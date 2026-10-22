"""Unit tests untuk modul Random Waypoint Model (RWP).

Memeriksa 10 kriteria fungsional task:
1. Initial position berada di dalam area.
2. Waypoint selalu berada di dalam boundary.
3. Speed berada dalam rentang min-max speed.
4. Posisi berubah ketika state moving.
5. Posisi tidak berubah ketika state paused.
6. Pengguna mencapai waypoint sebelum memilih waypoint baru.
7. Pengguna tidak keluar dari area simulasi.
8. Delta time menghasilkan perpindahan yang sesuai (dist = speed * dt).
9. Random seed menghasilkan trajectory yang reproducible.
10. Modul dapat dihentikan dan di-reset dengan benar.
Dan integrasi dengan generator profil skenario simulasi.
"""

import unittest
from wmc_simulator.mobility import (
    MobilityMovementStatus,
    MobilityPoint,
    RandomWaypointConfig,
    RandomWaypointModel,
)
from wmc_simulator.network import NetworkNode, generate_scenario_snapshots


class TestRandomWaypointModel(unittest.TestCase):
    def test_1_initial_position_in_area(self):
        # Default center position
        cfg1 = RandomWaypointConfig(area_width=400.0, area_height=300.0)
        model1 = RandomWaypointModel(cfg1)
        self.assertEqual(model1.current_state.position.x, 200.0)
        self.assertEqual(model1.current_state.position.y, 150.0)
        self.assertTrue(cfg1.contains(model1.current_state.position))

        # Explicit initial position
        cfg2 = RandomWaypointConfig(
            area_width=500.0,
            area_height=500.0,
            initial_position=MobilityPoint(50.0, 75.0),
        )
        model2 = RandomWaypointModel(cfg2)
        self.assertEqual(model2.current_state.position.x, 50.0)
        self.assertEqual(model2.current_state.position.y, 75.0)

        # Clamped out-of-bounds initial position
        cfg3 = RandomWaypointConfig(
            area_width=100.0,
            area_height=100.0,
            initial_position=MobilityPoint(250.0, -30.0),
        )
        model3 = RandomWaypointModel(cfg3)
        self.assertEqual(model3.current_state.position.x, 100.0)
        self.assertEqual(model3.current_state.position.y, 0.0)

    def test_2_waypoint_in_boundary(self):
        cfg = RandomWaypointConfig(area_width=300.0, area_height=200.0, seed=123)
        model = RandomWaypointModel(cfg)

        for _ in range(50):
            model.step(1.0)
            wp = model.current_state.current_waypoint
            self.assertTrue(0.0 <= wp.x <= 300.0, f"Waypoint X {wp.x} di luar boundary")
            self.assertTrue(0.0 <= wp.y <= 200.0, f"Waypoint Y {wp.y} di luar boundary")

    def test_3_speed_within_range(self):
        cfg = RandomWaypointConfig(min_speed=1.5, max_speed=4.5, seed=42)
        model = RandomWaypointModel(cfg)

        for _ in range(60):
            model.step(1.0)
            s = model.current_state
            if s.is_moving:
                self.assertGreaterEqual(s.current_speed, 1.499)
                self.assertLessEqual(s.current_speed, 4.501)
            else:
                self.assertEqual(s.current_speed, 0.0)

    def test_4_position_changes_when_moving(self):
        cfg = RandomWaypointConfig(
            area_width=1000.0,
            area_height=1000.0,
            initial_position=MobilityPoint(0.0, 0.0),
            min_speed=5.0,
            max_speed=5.0,
            seed=99,
        )
        model = RandomWaypointModel(cfg)
        pos0 = model.current_state.position
        s1 = model.step(1.0)

        self.assertTrue(s1.is_moving)
        self.assertGreater(pos0.distance_to(s1.position), 0.1)

    def test_5_position_does_not_change_when_paused(self):
        cfg = RandomWaypointConfig(
            area_width=100.0,
            area_height=100.0,
            initial_position=MobilityPoint(50.0, 50.0),
            min_speed=100.0,
            max_speed=100.0,
            min_pause_time=5.0,
            max_pause_time=5.0,
            seed=1,
        )
        model = RandomWaypointModel(cfg)

        # Langkah 1: langsung sampai ke waypoint dan masuk status PAUSED
        s_reach = model.step(1.0)
        self.assertTrue(s_reach.is_paused)

        paused_pos = s_reach.position
        s_paused2 = model.step(1.0)

        self.assertTrue(s_paused2.is_paused)
        self.assertAlmostEqual(s_paused2.position.x, paused_pos.x, places=5)
        self.assertAlmostEqual(s_paused2.position.y, paused_pos.y, places=5)
        self.assertEqual(s_paused2.current_speed, 0.0)

    def test_6_waypoint_reached_before_new_waypoint(self):
        cfg = RandomWaypointConfig(
            area_width=500.0,
            area_height=500.0,
            initial_position=MobilityPoint(0.0, 0.0),
            min_speed=10.0,
            max_speed=10.0,
            min_pause_time=2.0,
            max_pause_time=2.0,
            seed=77,
        )
        model = RandomWaypointModel(cfg)
        target_wp = model.current_state.current_waypoint

        reached = False
        for _ in range(100):
            s = model.step(1.0)
            if s.is_paused:
                if s.position.distance_to(target_wp) < 1e-4:
                    reached = True
                    break
        self.assertTrue(reached)

    def test_7_simulation_boundary_clamped(self):
        cfg = RandomWaypointConfig(
            area_width=100.0,
            area_height=100.0,
            min_speed=20.0,
            max_speed=30.0,
            seed=33,
        )
        model = RandomWaypointModel(cfg)

        for _ in range(200):
            s = model.step(0.5)
            self.assertTrue(0.0 <= s.position.x <= 100.0)
            self.assertTrue(0.0 <= s.position.y <= 100.0)

    def test_8_delta_time_displacement(self):
        cfg = RandomWaypointConfig(
            area_width=10000.0,
            area_height=10000.0,
            initial_position=MobilityPoint(0.0, 0.0),
            min_speed=4.0,
            max_speed=4.0,
            seed=10,
        )
        model = RandomWaypointModel(cfg)
        pos0 = model.current_state.position
        dt = 2.5
        pos1 = model.step(dt).position

        displacement = pos0.distance_to(pos1)
        expected = 4.0 * dt
        self.assertAlmostEqual(displacement, expected, places=3)

    def test_9_seed_reproducibility(self):
        cfg1 = RandomWaypointConfig(seed=2026)
        m1 = RandomWaypointModel(cfg1)
        path1 = [m1.step(1.0).position for _ in range(25)]

        cfg2 = RandomWaypointConfig(seed=2026)
        m2 = RandomWaypointModel(cfg2)
        path2 = [m2.step(1.0).position for _ in range(25)]

        for p1, p2 in zip(path1, path2):
            self.assertAlmostEqual(p1.x, p2.x, places=6)
            self.assertAlmostEqual(p1.y, p2.y, places=6)

    def test_10_reset(self):
        cfg = RandomWaypointConfig(
            area_width=500.0,
            area_height=500.0,
            initial_position=MobilityPoint(100.0, 100.0),
            seed=55,
        )
        model = RandomWaypointModel(cfg)

        for _ in range(15):
            model.step(1.0)
        self.assertEqual(model.current_state.elapsed_seconds, 15.0)

        model.reset()
        self.assertEqual(model.current_state.elapsed_seconds, 0.0)
        self.assertEqual(model.current_state.position.x, 100.0)
        self.assertEqual(model.current_state.position.y, 100.0)
        self.assertEqual(model.current_state.status, MobilityMovementStatus.MOVING)

    def test_integration_with_scenario_generator(self):
        nodes = [
            NetworkNode(id="lte_macro", technology="4G", x=100.0, y=100.0),
            NetworkNode(id="nr_small", technology="5G", x=250.0, y=250.0),
            NetworkNode(id="wifi_ap", technology="WLAN", x=120.0, y=110.0),
        ]
        rwp = RandomWaypointModel(
            RandomWaypointConfig(
                area_width=500.0,
                area_height=500.0,
                initial_position=MobilityPoint(100.0, 100.0),
                seed=42,
            )
        )

        snapshots = generate_scenario_snapshots(
            nodes,
            num_steps=10,
            dt_s=1.0,
            traffic_class="streaming",
            mobility_model=rwp,
        )

        self.assertEqual(len(snapshots), 10)
        for s in snapshots:
            self.assertIsNotNone(s.velocity_mps)
            self.assertEqual(len(s.networks), 3)


if __name__ == "__main__":
    unittest.main()
