"""Unit test komprehensif untuk HeterogeneousProfileGenerator."""

import json
import unittest

from wmc_simulator.baseline.topsis_utility import (
    SingleTopsisUtilityFunction,
    TopsisAlternative,
)
from wmc_simulator.models import NetworkSnapshot
from wmc_simulator.network.profile_generator import (
    DEFAULT_PROFILES,
    GeneratorConfig,
    HeterogeneousProfileGenerator,
    NetworkProfile,
    load_profiles_from_json,
)


class TestHeterogeneousProfileGenerator(unittest.TestCase):
    """Pengujian fungsional dan statistik untuk HeterogeneousProfileGenerator."""

    def setUp(self):
        self.generator = HeterogeneousProfileGenerator(seed=42)

    # 1. Menghasilkan profil untuk 4G, 5G, dan WLAN
    def test_generate_profile_all_technologies(self):
        for tech in ["4G", "5G", "WLAN"]:
            prof = self.generator.generate_profile(technology=tech, condition="moderate")
            self.assertIsInstance(prof, NetworkProfile)
            self.assertEqual(prof.technology, tech)
            self.assertEqual(prof.condition, "moderate")

    # 2. Seluruh profil memiliki parameter wajib
    def test_required_parameters_present(self):
        prof = self.generator.generate_profile(
            technology="4G", condition="good", profile_id="test_4g_01", timestamp_s=2.5
        )
        self.assertEqual(prof.profile_id, "test_4g_01")
        self.assertEqual(prof.technology, "4G")
        self.assertEqual(prof.condition, "good")
        self.assertEqual(prof.timestamp_s, 2.5)
        self.assertIsInstance(prof.rss_dbm, float)
        self.assertIsInstance(prof.data_rate_mbps, float)
        self.assertIsInstance(prof.delay_ms, float)
        self.assertIsInstance(prof.ber, float)
        self.assertIsInstance(prof.available, bool)
        self.assertIsInstance(prof.metadata, dict)
        self.assertIn("metric_type", prof.metadata)

    # 3. Validasi tipe data dan batas nilai
    def test_parameter_boundaries_and_types(self):
        for tech in ["4G", "5G", "WLAN"]:
            ref = DEFAULT_PROFILES[tech]
            for _ in range(30):
                prof = self.generator.generate_profile(technology=tech, condition="random")
                self.assertGreaterEqual(prof.rss_dbm, ref.rss_min)
                self.assertLessEqual(prof.rss_dbm, ref.rss_max)
                self.assertGreaterEqual(prof.data_rate_mbps, 0.0)
                self.assertGreaterEqual(prof.delay_ms, 0.0)
                self.assertGreaterEqual(prof.ber, 0.0)
                self.assertLessEqual(prof.ber, 1.0)

    # 4. Penanganan konfigurasi tidak valid
    def test_invalid_configurations_rejected(self):
        with self.assertRaises(ValueError):
            self.generator.generate_profile(technology="6G", condition="good")

        with self.assertRaises(ValueError):
            self.generator.generate_profile(technology="4G", condition="ultra_fast")

        with self.assertRaises(ValueError):
            NetworkProfile(
                profile_id="",  # kosong
                technology="4G",
                condition="good",
                rss_dbm=-70.0,
                data_rate_mbps=10.0,
                delay_ms=20.0,
                ber=1e-5,
            )

        with self.assertRaises(ValueError):
            NetworkProfile(
                profile_id="p1",
                technology="4G",
                condition="good",
                rss_dbm=-70.0,
                data_rate_mbps=-5.0,  # negatif
                delay_ms=20.0,
                ber=1e-5,
            )

        with self.assertRaises(ValueError):
            NetworkProfile(
                profile_id="p1",
                technology="4G",
                condition="good",
                rss_dbm=-70.0,
                data_rate_mbps=10.0,
                delay_ms=20.0,
                ber=1.5,  # > 1.0
            )

        with self.assertRaises(ValueError):
            GeneratorConfig(num_profiles=0)

        with self.assertRaises(ValueError):
            GeneratorConfig(technologies=("4G", "UNKNOWN"))

    # 5. Reprodusibilitas seed
    def test_seed_reproducibility(self):
        gen1 = HeterogeneousProfileGenerator(seed=12345)
        gen2 = HeterogeneousProfileGenerator(seed=12345)

        batch1 = gen1.generate_batch(count=15, condition="mixed")
        batch2 = gen2.generate_batch(count=15, condition="mixed")

        self.assertEqual(len(batch1), len(batch2))
        for p1, p2 in zip(batch1, batch2):
            self.assertEqual(p1.profile_id, p2.profile_id)
            self.assertEqual(p1.technology, p2.technology)
            self.assertEqual(p1.condition, p2.condition)
            self.assertAlmostEqual(p1.rss_dbm, p2.rss_dbm, places=4)
            self.assertAlmostEqual(p1.data_rate_mbps, p2.data_rate_mbps, places=4)
            self.assertAlmostEqual(p1.delay_ms, p2.delay_ms, places=4)
            self.assertAlmostEqual(p1.ber, p2.ber, places=7)

    # 6. Distribusi kondisi jaringan (good vs moderate vs poor)
    def test_condition_distributions_statistical(self):
        # Jalankan 100 sampel per kondisi untuk menguji tren fisik secara statistik
        n_samples = 100
        gen = HeterogeneousProfileGenerator(seed=999)

        good_profiles = [gen.generate_profile("5G", condition="good") for _ in range(n_samples)]
        poor_profiles = [gen.generate_profile("5G", condition="poor") for _ in range(n_samples)]

        avg_good_rss = sum(p.rss_dbm for p in good_profiles) / n_samples
        avg_poor_rss = sum(p.rss_dbm for p in poor_profiles) / n_samples
        self.assertGreater(avg_good_rss, avg_poor_rss, "RSS pada kondisi good harus lebih kuat dari poor")

        avg_good_rate = sum(p.data_rate_mbps for p in good_profiles) / n_samples
        avg_poor_rate = sum(p.data_rate_mbps for p in poor_profiles) / n_samples
        self.assertGreater(avg_good_rate, avg_poor_rate * 2.0, "Data rate kondisi good harus jauh lebih tinggi")

        avg_good_delay = sum(p.delay_ms for p in good_profiles) / n_samples
        avg_poor_delay = sum(p.delay_ms for p in poor_profiles) / n_samples
        self.assertLess(avg_good_delay, avg_poor_delay, "Delay kondisi good harus lebih rendah dari poor")

        avg_good_ber = sum(p.ber for p in good_profiles) / n_samples
        avg_poor_ber = sum(p.ber for p in poor_profiles) / n_samples
        self.assertLess(avg_good_ber, avg_poor_ber, "BER kondisi good harus lebih rendah dari poor")

    # 7. Pembuatan profil dalam jumlah banyak (batch generation)
    def test_batch_generation_without_failure(self):
        batch = self.generator.generate_batch(
            count=60,
            technologies=("4G", "5G", "WLAN"),
            condition="mixed",
            id_prefix="batch_test",
        )
        self.assertEqual(len(batch), 60)
        techs_found = {p.technology for p in batch}
        self.assertEqual(techs_found, {"4G", "5G", "WLAN"})
        conditions_found = {p.condition for p in batch}
        self.assertEqual(conditions_found, {"good", "moderate", "poor"})

    # 8. Konversi dan serialisasi JSON
    def test_json_serialization_and_roundtrip(self):
        prof = self.generator.generate_profile(
            technology="WLAN", condition="good", profile_id="wlan_json_01", timestamp_s=1.0
        )
        d = prof.to_dict()

        # Validasi struktur JSON sesuai spesifikasi
        self.assertEqual(d["profile_id"], "wlan_json_01")
        self.assertEqual(d["technology"], "WLAN")
        self.assertEqual(d["condition"], "good")
        self.assertIn("parameters", d)
        self.assertIn("rss_dbm", d["parameters"])
        self.assertIn("data_rate_mbps", d["parameters"])
        self.assertIn("delay_ms", d["parameters"])
        self.assertIn("ber", d["parameters"])
        self.assertEqual(d["metadata"]["data_source"], "synthetic")

        # Serialisasi ke string JSON tidak boleh error
        json_str = json.dumps(d)
        parsed = json.loads(json_str)

        # Roundtrip via from_dict
        restored = NetworkProfile.from_dict(parsed)
        self.assertEqual(restored.profile_id, prof.profile_id)
        self.assertEqual(restored.technology, prof.technology)
        self.assertAlmostEqual(restored.rss_dbm, prof.rss_dbm)
        self.assertAlmostEqual(restored.data_rate_mbps, prof.data_rate_mbps)

    # 9. Integrasi langsung dengan NetworkSnapshot dan Single TOPSIS Utility Function
    def test_integration_with_topsis_utility_function(self):
        # Buat 3 kandidat jaringan dengan kondisi heterogen
        p_lte = self.generator.generate_profile("4G", condition="moderate", profile_id="lte_node")
        p_nr = self.generator.generate_profile("5G", condition="good", profile_id="nr_node")
        p_wlan = self.generator.generate_profile("WLAN", condition="poor", profile_id="wlan_node")

        # Konversi ke NetworkSnapshot
        snapshots = [
            p_lte.to_network_snapshot(),
            p_nr.to_network_snapshot(),
            p_wlan.to_network_snapshot(),
        ]

        for s in snapshots:
            self.assertIsInstance(s, NetworkSnapshot)
            self.assertTrue(s.available)

        # Evaluasi menggunakan Single TOPSIS Baseline
        alternatives = [TopsisAlternative.from_network_snapshot(s) for s in snapshots]
        topsis = SingleTopsisUtilityFunction()
        weights = {
            "data_rate_mbps": 0.40,
            "delay_ms": 0.35,
            "ber": 0.25,
        }
        decision = topsis.evaluate(
            alternatives=alternatives,
            weights=weights,
        )

        # 5G NR (kondisi good) harus mendapatkan peringkat terbaik (rank 1)
        self.assertEqual(decision.best_alternative_id, "nr_node")
        ranking_map = {r.alternative_id: r.rank for r in decision.rankings}
        self.assertEqual(ranking_map["nr_node"], 1)

    # 10. Variasi temporal (generate_temporal_sequence)
    def test_temporal_sequence_generation(self):
        seq = self.generator.generate_temporal_sequence(
            technology="4G",
            num_steps=10,
            dt_s=1.5,
            condition="moderate",
            profile_id="lte_dyn",
            correlation=0.85,
        )
        self.assertEqual(len(seq), 10)
        for i, item in enumerate(seq):
            self.assertEqual(item.profile_id, "lte_dyn")
            self.assertAlmostEqual(item.timestamp_s, i * 1.5)
            self.assertTrue(DEFAULT_PROFILES["4G"].rss_min <= item.rss_dbm <= DEFAULT_PROFILES["4G"].rss_max)
            self.assertGreaterEqual(item.data_rate_mbps, 0.0)
            self.assertGreaterEqual(item.delay_ms, 0.0)
            self.assertTrue(0.0 <= item.ber <= 1.0)
            self.assertIn("step", item.metadata)

    # 11. Pemuat profil dari file JSON (qos_profiles.json)
    def test_load_profiles_from_json(self):
        loaded = load_profiles_from_json()
        self.assertEqual(set(loaded.keys()), {"4G", "5G", "WLAN"})
        for tech in ["4G", "5G", "WLAN"]:
            self.assertLess(loaded[tech].rss_min, loaded[tech].rss_max)
            self.assertLess(loaded[tech].data_rate_min, loaded[tech].data_rate_max)
            self.assertLess(loaded[tech].delay_min, loaded[tech].delay_max)
            self.assertLess(loaded[tech].ber_min, loaded[tech].ber_max)


if __name__ == "__main__":
    unittest.main()
