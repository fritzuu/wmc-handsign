"""Demo interaktif simulasi Random Waypoint Model (RWP).

Menampilkan pergerakan pengguna, pergantian waypoint, jeda (pause),
dan variasi kecepatan pada setiap detik simulasi.
"""

from wmc_simulator.mobility import (
    MobilityPoint,
    RandomWaypointConfig,
    RandomWaypointModel,
)


def main():
    print("=" * 72)
    print(" DEMO: Random Waypoint Model (RWP) Simulation")
    print("=" * 72)

    config = RandomWaypointConfig(
        area_width=300.0,
        area_height=200.0,
        initial_position=MobilityPoint(150.0, 100.0),
        min_speed=1.5,
        max_speed=4.0,
        min_pause_time=1.0,
        max_pause_time=3.0,
        update_interval=1.0,
        seed=42,
    )
    model = RandomWaypointModel(config)

    print(f"Area simulasi : {config.area_width}m x {config.area_height}m")
    print(f"Posisi awal   : ({config.initial_position.x}, {config.initial_position.y})")
    print(f"Rentang speed : {config.min_speed} ~ {config.max_speed} m/s")
    print(f"Rentang pause : {config.min_pause_time} ~ {config.max_pause_time} s")
    print("-" * 72)
    print(
        f"{'Detik':>6} | {'Status':>8} | {'Posisi (X, Y)':>18} | {'Kecepatan':>10} | {'Target Waypoint':>18}"
    )
    print("-" * 72)

    # Jalankan simulasi selama 25 langkah (25 detik)
    for _ in range(25):
        s = model.current_state
        pos_str = f"({s.position.x:6.2f}, {s.position.y:6.2f})"
        wp_str = f"({s.current_waypoint.x:6.2f}, {s.current_waypoint.y:6.2f})"
        status_str = s.status.value.upper()
        speed_str = f"{s.current_speed:5.2f} m/s"

        print(f"{s.elapsed_seconds:5.1f}s | {status_str:>8} | {pos_str:>18} | {speed_str:>10} | {wp_str:>18}")
        model.step()

    print("=" * 72)
    print("Simulasi selesai.")


if __name__ == "__main__":
    main()
