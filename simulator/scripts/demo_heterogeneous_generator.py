"""Demo interaktif untuk Generator Profil Jaringan Heterogen.

Menampilkan:
1. Pembangkitan profil per teknologi (4G, 5G, WLAN) pada berbagai kondisi (good, moderate, poor).
2. Representasi keluaran JSON terstandar.
3. Pembangkitan batch profil multi-teknologi.
4. Pembangkitan deret temporal (AR(1) drift) selama 10 langkah waktu.
5. Integrasi langsung dengan evaluasi baseline Single TOPSIS Utility Function.

Dijalankan dengan: python demo_heterogeneous_generator.py
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import json
from wmc_simulator.baseline.topsis_utility import (
    SingleTopsisUtilityFunction,
    TopsisAlternative,
)
from wmc_simulator.network import (
    HeterogeneousProfileGenerator,
    load_profiles_from_json,
)


def print_banner(title: str) -> None:
    print("\n" + "=" * 78)
    print(f" {title}")
    print("=" * 78)


def main() -> None:
    generator = HeterogeneousProfileGenerator(seed=42)

    # -------------------------------------------------------------------------
    # 1. Pembangkitan Profil per Teknologi & Kondisi
    # -------------------------------------------------------------------------
    print_banner("1. PEMBANGKITAN PROFIL PER TEKNOLOGI & KONDISI OPERASIONAL")
    print(f"{'ID':16s} {'Tech':6s} {'Kondisi':10s} {'RSS (dBm)':>10s} {'Rate (Mbps)':>12s} {'Delay (ms)':>12s} {'BER':>12s}")
    print("-" * 78)

    sample_profiles = []
    for tech in ["4G", "5G", "WLAN"]:
        for cond in ["good", "moderate", "poor"]:
            p = generator.generate_profile(technology=tech, condition=cond)
            sample_profiles.append(p)
            print(f"{p.profile_id:16s} {p.technology:6s} {p.condition:10s} {p.rss_dbm:10.2f} {p.data_rate_mbps:12.3f} {p.delay_ms:12.3f} {p.ber:12.2e}")

    # -------------------------------------------------------------------------
    # 2. Contoh Format JSON Output Terstandar
    # -------------------------------------------------------------------------
    print_banner("2. CONTOH FORMAT JSON OUTPUT TERSTANDAR (Sesuai Spesifikasi)")
    example_prof = generator.generate_profile(
        technology="4G",
        condition="good",
        profile_id="profile_4g_sample",
        timestamp_s=0.0,
    )
    json_output = json.dumps(example_prof.to_dict(), indent=2)
    print(json_output)

    # -------------------------------------------------------------------------
    # 3. Pembangkitan Batch Multi-Teknologi
    # -------------------------------------------------------------------------
    print_banner("3. PEMBANGKITAN BATCH MULTI-TEKNOLOGI (Kondisi Mixed)")
    batch = generator.generate_batch(count=6, condition="mixed", id_prefix="demo_batch")
    print(f"{'Profile ID':20s} {'Tech':6s} {'Kondisi':10s} {'RSS':>10s} {'Rate':>12s} {'Delay':>10s} {'BER':>10s}")
    print("-" * 78)
    for p in batch:
        print(f"{p.profile_id:20s} {p.technology:6s} {p.condition:10s} {p.rss_dbm:10.2f} {p.data_rate_mbps:12.3f} {p.delay_ms:10.3f} {p.ber:10.2e}")

    # -------------------------------------------------------------------------
    # 4. Pembangkitan Deret Temporal (AR(1) Drift)
    # -------------------------------------------------------------------------
    print_banner("4. PEMBANGKITAN DERET TEMPORAL DENGAN DRIFT FADING HALUS (5G NR, 6 Steps)")
    temporal_seq = generator.generate_temporal_sequence(
        technology="5G",
        num_steps=6,
        dt_s=1.0,
        condition="moderate",
        profile_id="nr_fading_node",
    )
    print(f"{'Waktu (s)':>10s} {'ID':18s} {'RSS (dBm)':>12s} {'Rate (Mbps)':>14s} {'Delay (ms)':>12s} {'BER':>12s}")
    print("-" * 78)
    for p in temporal_seq:
        print(f"{p.timestamp_s:10.1f} {p.profile_id:18s} {p.rss_dbm:12.2f} {p.data_rate_mbps:14.3f} {p.delay_ms:12.3f} {p.ber:12.2e}")

    # -------------------------------------------------------------------------
    # 5. Integrasi End-to-End dengan Baseline Single TOPSIS Utility Function
    # -------------------------------------------------------------------------
    print_banner("5. INTEGRASI DENGAN BASELINE SINGLE TOPSIS UTILITY FUNCTION")
    # Skenario 3 kandidat heterogen: 4G (moderate), 5G (good), WLAN (poor)
    c_lte = generator.generate_profile("4G", condition="moderate", profile_id="LTE_Macro")
    c_nr = generator.generate_profile("5G", condition="good", profile_id="NR_SmallCell")
    c_wlan = generator.generate_profile("WLAN", condition="poor", profile_id="WLAN_AP")

    candidates = [c_lte, c_nr, c_wlan]
    alternatives = [TopsisAlternative.from_network_snapshot(c.to_network_snapshot()) for c in candidates]

    topsis = SingleTopsisUtilityFunction()
    weights = {
        "data_rate_mbps": 0.40,
        "delay_ms": 0.35,
        "ber": 0.25,
    }
    result = topsis.evaluate(alternatives, weights=weights)

    print("Hasil Perankingan Kandidat Jaringan:")
    print(f"{'Rank':>5s} {'Network ID':16s} {'Tech':6s} {'Kondisi':10s} {'Skor Utilitas (Ci)':>20s}")
    print("-" * 65)
    for r in result.rankings:
        cand = next(c for c in candidates if c.profile_id == r.alternative_id)
        print(f"{r.rank:5d} {r.alternative_id:16s} {cand.technology:6s} {cand.condition:10s} {r.utility_score:20.6f}")

    print(f"\nJaringan Rekomendasi TOPSIS Terbaik: {result.best_alternative_id} (Skor: {result.best_utility_score:.6f})")


if __name__ == "__main__":
    main()
