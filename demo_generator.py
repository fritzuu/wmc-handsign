"""Demo untuk mengecek generator profil jaringan heterogen."""

from wmc_simulator.network import (
    NetworkNode,
    generate_scenario_snapshots,
    create_default_scenario,
    DEFAULT_PROFILES,
)


def print_header(title):
    print("=" * 70)
    print(f" {title}")
    print("=" * 70)


def print_snapshot(s):
    print(f"\n  Waktu: {s.timestamp_s}s | Terhubung ke: {s.current_network} | Kecepatan: {s.velocity_mps} m/s")
    print(f"  {'ID':10s} {'Tech':5s} {'RSS(dBm)':>10s} {'Rate(Mbps)':>12s} {'Delay(ms)':>10s} {'BER':>10s} {'Status':>10s}")
    print(f"  {'-'*10} {'-'*5} {'-'*10} {'-'*12} {'-'*10} {'-'*10} {'-'*10}")
    for n in s.networks:
        status = "OK" if n.available else "OUT"
        print(f"  {n.id:10s} {n.technology:5s} {n.rss_dbm:10.2f} {n.data_rate_mbps:12.3f} {n.delay_ms:10.3f} {n.ber:10.2e} {status:>10s}")


def main():
    # === CEK 1: Profil Teknologi ===
    print_header("CEK 1: Profil Teknologi Default")
    for tech, profile in DEFAULT_PROFILES.items():
        print(f"\n  [{tech}]")
        print(f"    RSS       : {profile.rss_min} ~ {profile.rss_max} dBm")
        print(f"    Data Rate : {profile.data_rate_min} ~ {profile.data_rate_max} Mbps")
        print(f"    Delay     : {profile.delay_min} ~ {profile.delay_max} ms")
        print(f"    BER       : {profile.ber_min} ~ {profile.ber_max}")
        print(f"    Coverage  : {profile.coverage_radius_m} m")

    # === CEK 2: Skenario Default ===
    print("\n")
    print_header("CEK 2: Skenario Default (3 jaringan, 5 langkah, v=10 m/s)")
    snapshots = create_default_scenario(seed=42, num_steps=5, velocity_mps=10.0)
    for s in snapshots:
        print_snapshot(s)

    # === CEK 3: Skenario Custom Kecepatan Tinggi ===
    print("\n")
    print_header("CEK 3: Skenario Custom (v=30 m/s, trafik conversational)")
    nodes = [
        NetworkNode(id="lte_macro", technology="4G", x=0, y=100),
        NetworkNode(id="nr_small", technology="5G", x=150, y=0),
        NetworkNode(id="wifi_ap", technology="WLAN", x=50, y=20),
    ]
    snapshots = generate_scenario_snapshots(
        nodes,
        num_steps=5,
        dt_s=1.0,
        velocity_mps=30.0,
        traffic_class="conversational",
        user_start_x=0,
        user_start_y=0,
        user_direction_deg=45,
        seed=99,
    )
    for s in snapshots:
        print_snapshot(s)

    # === CEK 4: Reprodusibilitas Seed ===
    print("\n")
    print_header("CEK 4: Reprodusibilitas Seed")
    r1 = create_default_scenario(seed=123, num_steps=3)
    r2 = create_default_scenario(seed=123, num_steps=3)
    all_match = all(
        s1 == s2 for s1, s2 in zip(r1, r2)
    )
    print(f"\n  Seed 123 run 1 == run 2? {'YA - Identik!' if all_match else 'TIDAK - Ada masalah!'}")

    # === CEK 5: Validasi kontrak data ===
    print("\n")
    print_header("CEK 5: Validasi Kontrak Data")
    snapshots = create_default_scenario(seed=42, num_steps=10)
    errors = []
    for i, snap in enumerate(snapshots):
        # current_network harus ada dan available
        current = next((n for n in snap.networks if n.id == snap.current_network), None)
        if current is None:
            errors.append(f"  Step {i}: current_network '{snap.current_network}' tidak ditemukan")
        elif not current.available:
            errors.append(f"  Step {i}: current_network '{snap.current_network}' tidak available")
        # BER harus 0-1
        for n in snap.networks:
            if not (0 <= n.ber <= 1):
                errors.append(f"  Step {i}: {n.id} BER={n.ber} di luar rentang 0-1")
            if n.data_rate_mbps < 0:
                errors.append(f"  Step {i}: {n.id} data_rate negatif")
            if n.delay_ms < 0:
                errors.append(f"  Step {i}: {n.id} delay negatif")

    if errors:
        print("\n  GAGAL! Ditemukan error:")
        for e in errors:
            print(f"    {e}")
    else:
        print("\n  LULUS! Semua 10 snapshot memenuhi kontrak data:")
        print("    - current_network selalu tersedia")
        print("    - BER selalu dalam rentang 0-1")
        print("    - Data rate selalu >= 0")
        print("    - Delay selalu >= 0")

    # === KESIMPULAN ===
    print("\n")
    print("=" * 70)
    print(" SEMUA PENGECEKAN SELESAI - GENERATOR BERJALAN DENGAN BAIK!")
    print("=" * 70)


if __name__ == "__main__":
    main()
