"""Verifikasi kesetaraan logika Random Waypoint Model (RWP) Dart dengan Python.

Menjalankan 10 test case fungsional task untuk memverifikasi logika RWP
sebagaimana diimplementasikan dalam Dart dan Python.

Dijalankan dengan: python -X utf8 verify_random_waypoint.py
"""

from __future__ import annotations

import math
from wmc_simulator.mobility import (
    MobilityMovementStatus,
    MobilityPoint,
    RandomWaypointConfig,
    RandomWaypointModel,
)

_passed = 0
_failed = 0
_total = 0


def _assert(condition: bool, message: str) -> None:
    global _passed, _failed, _total
    _total += 1
    if condition:
        _passed += 1
        print(f"  [PASS] {message}")
    else:
        _failed += 1
        print(f"  [FAIL] {message}")


def _header(title: str) -> None:
    print(f"\n======================================================================")
    print(f" {title}")
    print(f"======================================================================")


def test_initial_position():
    _header("TEST 1: Initial position berada di dalam area")
    cfg1 = RandomWaypointConfig(area_width=400.0, area_height=300.0)
    m1 = RandomWaypointModel(cfg1)
    _assert(m1.current_state.position.x == 200.0 and m1.current_state.position.y == 150.0, "Posisi default di pusat area (200, 150)")
    _assert(cfg1.contains(m1.current_state.position), "Posisi awal valid dalam boundary")

    cfg2 = RandomWaypointConfig(area_width=500.0, area_height=500.0, initial_position=MobilityPoint(50.0, 75.0))
    m2 = RandomWaypointModel(cfg2)
    _assert(m2.current_state.position.x == 50.0 and m2.current_state.position.y == 75.0, "Posisi kustom terpasang (50, 75)")


def test_waypoint_in_boundary():
    _header("TEST 2: Waypoint selalu berada di dalam boundary")
    cfg = RandomWaypointConfig(area_width=300.0, area_height=200.0, seed=123)
    m = RandomWaypointModel(cfg)
    all_ok = True
    for _ in range(50):
        m.step(1.0)
        wp = m.current_state.current_waypoint
        if not (0.0 <= wp.x <= 300.0 and 0.0 <= wp.y <= 200.0):
            all_ok = False
            break
    _assert(all_ok, "Semua 50 waypoint berada dalam batas [0, 300] x [0, 200]")


def test_speed_range():
    _header("TEST 3: Speed berada dalam rentang min-max speed")
    cfg = RandomWaypointConfig(min_speed=1.5, max_speed=4.5, seed=42)
    m = RandomWaypointModel(cfg)
    valid = True
    for _ in range(60):
        m.step(1.0)
        s = m.current_state
        if s.is_moving:
            if not (1.499 <= s.current_speed <= 4.501):
                valid = False
                break
        else:
            if s.current_speed != 0.0:
                valid = False
                break
    _assert(valid, "Kecepatan dalam [1.5, 4.5] m/s saat moving, dan 0 m/s saat paused")


def test_position_changes_when_moving():
    _header("TEST 4: Posisi berubah ketika state moving")
    cfg = RandomWaypointConfig(area_width=1000.0, area_height=1000.0, initial_position=MobilityPoint(0.0, 0.0), min_speed=5.0, max_speed=5.0, seed=99)
    m = RandomWaypointModel(cfg)
    p0 = m.current_state.position
    s1 = m.step(1.0)
    _assert(s1.is_moving, "Status terkonfirmasi moving")
    _assert(p0.distance_to(s1.position) > 0.1, f"Posisi bergeser ({p0.x:.1f}, {p0.y:.1f}) -> ({s1.position.x:.1f}, {s1.position.y:.1f})")


def test_position_fixed_when_paused():
    _header("TEST 5: Posisi tidak berubah ketika state paused")
    cfg = RandomWaypointConfig(area_width=100.0, area_height=100.0, initial_position=MobilityPoint(50.0, 50.0), min_speed=100.0, max_speed=100.0, min_pause_time=5.0, max_pause_time=5.0, seed=1)
    m = RandomWaypointModel(cfg)
    s_reach = m.step(1.0)
    _assert(s_reach.is_paused, "Status masuk paused")
    p_paused = s_reach.position
    s_paused2 = m.step(1.0)
    _assert(s_paused2.is_paused, "Masih paused")
    _assert(abs(s_paused2.position.x - p_paused.x) < 1e-5 and abs(s_paused2.position.y - p_paused.y) < 1e-5, "Posisi sama persis selama paused")
    _assert(s_paused2.current_speed == 0.0, "Kecepatan 0 m/s saat paused")


def test_waypoint_reached():
    _header("TEST 6: Pengguna mencapai waypoint sebelum memilih waypoint baru")
    cfg = RandomWaypointConfig(area_width=500.0, area_height=500.0, initial_position=MobilityPoint(0.0, 0.0), min_speed=10.0, max_speed=10.0, min_pause_time=2.0, max_pause_time=2.0, seed=77)
    m = RandomWaypointModel(cfg)
    target_wp = m.current_state.current_waypoint
    reached = False
    for _ in range(100):
        s = m.step(1.0)
        if s.is_paused:
            if s.position.distance_to(target_wp) < 1e-4:
                reached = True
                break
    _assert(reached, "Pengguna tiba tepat pada target waypoint sebelum beralih/pause")


def test_boundary_clamped():
    _header("TEST 7: Pengguna tidak keluar dari area simulasi")
    cfg = RandomWaypointConfig(area_width=100.0, area_height=100.0, min_speed=20.0, max_speed=30.0, seed=33)
    m = RandomWaypointModel(cfg)
    in_bound = True
    for _ in range(200):
        s = m.step(0.5)
        if not (0.0 <= s.position.x <= 100.0 and 0.0 <= s.position.y <= 100.0):
            in_bound = False
            break
    _assert(in_bound, "200 langkah selalu dalam boundary [0, 100]")


def test_delta_time_displacement():
    _header("TEST 8: Delta time menghasilkan perpindahan yang sesuai (v * dt)")
    cfg = RandomWaypointConfig(area_width=10000.0, area_height=10000.0, initial_position=MobilityPoint(0.0, 0.0), min_speed=4.0, max_speed=4.0, seed=10)
    m = RandomWaypointModel(cfg)
    p0 = m.current_state.position
    dt = 2.5
    p1 = m.step(dt).position
    disp = p0.distance_to(p1)
    _assert(abs(disp - (4.0 * dt)) < 1e-3, f"Perpindahan {disp:.3f}m sesuai dengan v*dt = {4.0*dt}m")


def test_seed_reproducibility():
    _header("TEST 9: Random seed menghasilkan trajectory yang reproducible")
    m1 = RandomWaypointModel(RandomWaypointConfig(seed=2026))
    m2 = RandomWaypointModel(RandomWaypointConfig(seed=2026))
    identical = True
    for _ in range(25):
        s1 = m1.step(1.0)
        s2 = m2.step(1.0)
        if abs(s1.position.x - s2.position.x) > 1e-5 or abs(s1.position.y - s2.position.y) > 1e-5:
            identical = False
            break
    _assert(identical, "Trajectory identik untuk seed yang sama")


def test_reset():
    _header("TEST 10: Modul dapat dihentikan dan di-reset dengan benar")
    m = RandomWaypointModel(RandomWaypointConfig(area_width=500.0, area_height=500.0, initial_position=MobilityPoint(100.0, 100.0), seed=55))
    for _ in range(15):
        m.step(1.0)
    _assert(m.current_state.elapsed_seconds == 15.0, "Waktu berjalan 15 detik")
    m.reset()
    _assert(m.current_state.elapsed_seconds == 0.0, "Waktu kembali ke 0.0s setelah reset")
    _assert(m.current_state.position.x == 100.0 and m.current_state.position.y == 100.0, "Posisi kembali ke awal (100, 100)")
    _assert(m.current_state.status == MobilityMovementStatus.MOVING, "Status awal kembali moving")


def main():
    print("=" * 70)
    print(" VERIFIKASI — Random Waypoint Model (RWP)")
    print(" Proyek: WMC Vertical Handover Real-Time")
    print("=" * 70)

    test_initial_position()
    test_waypoint_in_boundary()
    test_speed_range()
    test_position_changes_when_moving()
    test_position_fixed_when_paused()
    test_waypoint_reached()
    test_boundary_clamped()
    test_delta_time_displacement()
    test_seed_reproducibility()
    test_reset()

    print("\n" + "=" * 70)
    if _failed == 0:
        print(f" [OK] SEMUA {_total} TEST LULUS! Random Waypoint Model terverifikasi.")
    else:
        print(f" [FAIL] {_failed} dari {_total} test GAGAL!")
    print(f" Passed: {_passed} | Failed: {_failed} | Total: {_total}")
    print("=" * 70)


if __name__ == "__main__":
    main()
