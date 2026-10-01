"""Unit tests untuk generator profil jaringan heterogen."""

import unittest

from wmc_simulator.models import NetworkSnapshot, ScenarioSnapshot
from wmc_simulator.network.profile_generator import (
    TechnologyProfile,
    NetworkNode,
    NetworkProfileGenerator,
    generate_scenario_snapshots,
    create_default_scenario,
    DEFAULT_PROFILES,
)


class TestTechnologyProfile(unittest.TestCase):
    """Pengujian konfigurasi profil teknologi."""

    def test_default_profiles_cover_all_technologies(self):
        self.assertEqual(set(DEFAULT_PROFILES.keys()), {"4G", "5G", "WLAN"})

    def test_profile_ranges_valid(self):
        for tech, profile in DEFAULT_PROFILES.items():
            with self.subTest(tech=tech):
                self.assertLess(profile.rss_min, profile.rss_max)
                self.assertLess(profile.data_rate_min, profile.data_rate_max)
                self.assertLess(profile.delay_min, profile.delay_max)
                self.assertLess(profile.ber_min, profile.ber_max)
                self.assertGreater(profile.coverage_radius_m, 0)

    def test_rejects_invalid_technology(self):
        with self.assertRaises(ValueError):
            TechnologyProfile(
                technology="6G",
                rss_min=-100, rss_max=-40,
                data_rate_min=10, data_rate_max=500,
                delay_min=1, delay_max=50,
                ber_min=1e-8, ber_max=1e-4,
            )


class TestNetworkNode(unittest.TestCase):
    """Pengujian node jaringan."""

    def test_resolved_profile_returns_default(self):
        node = NetworkNode(id="test_4g", technology="4G")
        self.assertEqual(node.resolved_profile(), DEFAULT_PROFILES["4G"])

    def test_resolved_profile_returns_custom(self):
        custom = TechnologyProfile(
            technology="5G",
            rss_min=-100, rss_max=-50,
            data_rate_min=100, data_rate_max=500,
            delay_min=2, delay_max=10,
            ber_min=1e-7, ber_max=1e-5,
        )
        node = NetworkNode(id="test_5g", technology="5G", profile=custom)
        self.assertEqual(node.resolved_profile(), custom)


class TestNetworkProfileGenerator(unittest.TestCase):
    """Pengujian generator profil jaringan."""

    def setUp(self):
        self.nodes = [
            NetworkNode(id="lte_1", technology="4G", x=0.0, y=50.0),
            NetworkNode(id="nr_1", technology="5G", x=200.0, y=-30.0),
            NetworkNode(id="wlan_1", technology="WLAN", x=80.0, y=10.0),
        ]
        self.generator = NetworkProfileGenerator(
            nodes=self.nodes,
            rng=__import__("random").Random(42),
        )

    def test_generate_snapshot_returns_network_snapshot(self):
        result = self.generator.generate_snapshot(self.nodes[0])
        self.assertIsInstance(result, NetworkSnapshot)
        self.assertEqual(result.id, "lte_1")
        self.assertEqual(result.technology, "4G")

    def test_generate_snapshot_random_mode_within_range(self):
        """Snapshot acak harus dalam rentang profil."""
        profile = DEFAULT_PROFILES["4G"]
        for _ in range(50):
            snap = self.generator.generate_snapshot(self.nodes[0])
            self.assertGreaterEqual(snap.rss_dbm, profile.rss_min)
            self.assertLessEqual(snap.rss_dbm, profile.rss_max)
            self.assertGreaterEqual(snap.data_rate_mbps, 0)
            self.assertGreaterEqual(snap.delay_ms, 0)
            self.assertGreaterEqual(snap.ber, 0)
            self.assertLessEqual(snap.ber, 1)

    def test_generate_snapshot_distance_mode(self):
        """Snapshot berdasarkan jarak harus mengembalikan hasil valid."""
        snap = self.generator.generate_snapshot(
            self.nodes[0], user_x=10.0, user_y=10.0,
        )
        self.assertIsInstance(snap, NetworkSnapshot)
        self.assertTrue(snap.available)  # dekat dengan node

    def test_generate_snapshot_far_away_unavailable(self):
        """Pengguna yang jauh melampaui coverage harus not available."""
        snap = self.generator.generate_snapshot(
            self.nodes[2],  # WLAN, coverage 100m
            user_x=5000.0, user_y=5000.0,
        )
        self.assertFalse(snap.available)

    def test_generate_all_returns_all_nodes(self):
        results = self.generator.generate_all()
        self.assertEqual(len(results), 3)
        ids = {r.id for r in results}
        self.assertEqual(ids, {"lte_1", "nr_1", "wlan_1"})

    def test_seed_reproducibility(self):
        """Seed yang sama harus menghasilkan output identik."""
        gen1 = NetworkProfileGenerator(
            nodes=self.nodes, rng=__import__("random").Random(99),
        )
        gen2 = NetworkProfileGenerator(
            nodes=self.nodes, rng=__import__("random").Random(99),
        )
        for n in self.nodes:
            s1 = gen1.generate_snapshot(n, user_x=50, user_y=50)
            s2 = gen2.generate_snapshot(n, user_x=50, user_y=50)
            self.assertEqual(s1, s2)


class TestGenerateScenarioSnapshots(unittest.TestCase):
    """Pengujian pembangkitan deretan skenario."""

    def setUp(self):
        self.nodes = [
            NetworkNode(id="lte_1", technology="4G", x=0.0, y=50.0),
            NetworkNode(id="nr_1", technology="5G", x=200.0, y=-30.0),
            NetworkNode(id="wlan_1", technology="WLAN", x=80.0, y=10.0),
        ]

    def test_generates_correct_number_of_steps(self):
        result = generate_scenario_snapshots(
            self.nodes, num_steps=5, seed=42,
        )
        self.assertEqual(len(result), 5)

    def test_each_step_is_scenario_snapshot(self):
        result = generate_scenario_snapshots(
            self.nodes, num_steps=3, seed=42,
        )
        for snap in result:
            self.assertIsInstance(snap, ScenarioSnapshot)

    def test_timestamps_increment(self):
        result = generate_scenario_snapshots(
            self.nodes, num_steps=5, dt_s=2.0, seed=42,
        )
        for i, snap in enumerate(result):
            self.assertAlmostEqual(snap.timestamp_s, i * 2.0)

    def test_current_network_always_available(self):
        result = generate_scenario_snapshots(
            self.nodes, num_steps=10, seed=42,
        )
        for snap in result:
            current = next(n for n in snap.networks if n.id == snap.current_network)
            self.assertTrue(current.available)

    def test_velocity_preserved(self):
        result = generate_scenario_snapshots(
            self.nodes, num_steps=3, velocity_mps=15.0, seed=42,
        )
        for snap in result:
            self.assertEqual(snap.velocity_mps, 15.0)

    def test_rejects_empty_nodes(self):
        with self.assertRaises(ValueError):
            generate_scenario_snapshots([], num_steps=1, seed=42)

    def test_rejects_invalid_traffic_class(self):
        with self.assertRaises(ValueError):
            generate_scenario_snapshots(
                self.nodes, traffic_class="invalid", seed=42,
            )

    def test_rejects_zero_dt(self):
        with self.assertRaises(ValueError):
            generate_scenario_snapshots(
                self.nodes, dt_s=0, seed=42,
            )


class TestCreateDefaultScenario(unittest.TestCase):
    """Pengujian skenario default."""

    def test_returns_list_of_scenario_snapshots(self):
        result = create_default_scenario(seed=42, num_steps=5)
        self.assertEqual(len(result), 5)
        for snap in result:
            self.assertIsInstance(snap, ScenarioSnapshot)
            self.assertEqual(len(snap.networks), 3)

    def test_seed_reproducibility(self):
        r1 = create_default_scenario(seed=123, num_steps=3)
        r2 = create_default_scenario(seed=123, num_steps=3)
        for s1, s2 in zip(r1, r2):
            self.assertEqual(s1, s2)


if __name__ == "__main__":
    unittest.main()
