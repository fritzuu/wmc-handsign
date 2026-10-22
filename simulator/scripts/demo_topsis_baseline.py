"""Demo interaktif eksekusi Baseline Algorithm: Single TOPSIS Utility Function.

Mengevaluasi snapshot sintetis dan skenario multi-timestep heterogen (4G, 5G, WLAN).
Dijalankan dengan: python demo_topsis_baseline.py
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from wmc_simulator.io import load_snapshot
from wmc_simulator.baseline import SingleTopsisUtilityFunction, run_baseline_topsis_scenario
from wmc_simulator.network import create_default_scenario


def main():
    print("=" * 76)
    print(" DEMO: Baseline Algorithm — Single TOPSIS Utility Function")
    print(" Proyek: WMC Vertical Handover Decision System")
    print("=" * 76)

    engine = SingleTopsisUtilityFunction()

    # 1. Evaluasi pada snapshot contoh (examples/sample_snapshot.json)
    sim_root = Path(__file__).resolve().parent.parent
    sample_path = sim_root / "examples" / "sample_snapshot.json"
    if not sample_path.exists():
        sample_path = Path(__file__).resolve().parent / "examples" / "sample_snapshot.json"
    print(f"\n[1] Evaluasi Snapshot Contoh: {sample_path.name}")
    print("-" * 76)
    snapshot = load_snapshot(str(sample_path))
    decision = engine.decide_handover(snapshot)

    print(f" Waktu simulasi     : {decision['timestamp_s']}s")
    print(f" Kelas trafik       : {snapshot.traffic_class}")
    print(f" Jaringan aktif     : {decision['current_network']}")
    print(f" Rekomendasi pindah : {'YA' if decision['handover_recommended'] else 'TIDAK'}")
    print(f" Jaringan target    : {decision['target_network']}")
    print(f" Alasan keputusan   : {decision['reason']}")
    print("\n Peringkat Kandidat Jaringan (Berdasarkan Skor Utilitas Relatif Ci):")
    print(f" {'Rank':>4} | {'ID Jaringan':12} | {'Utilitas (Ci)':>13} | {'D+ (ke A+)':>11} | {'D- (ke A-)':>11}")
    print(f" {'-'*4} | {'-'*12} | {'-'*13} | {'-'*11} | {'-'*11}")
    for r in decision["rankings"]:
        print(f" {r['rank']:4d} | {r['alternative_id']:12} | {r['utility_score']:13.6f} | {r['d_plus']:11.6f} | {r['d_minus']:11.6f}")

    # 2. Evaluasi Skenario Beruntun Multi-Timestep (20 Langkah)
    print("\n" + "=" * 76)
    print("[2] Evaluasi Skenario Beruntun Multi-Timestep (20 Timestep, v=10 m/s)")
    print("-" * 76)
    scenarios = create_default_scenario(num_steps=20, velocity_mps=10.0, seed=42)
    eval_result = run_baseline_topsis_scenario(scenarios, hysteresis_margin=0.05)

    print(f" Total Timesteps          : {eval_result['total_timesteps']}")
    print(f" Total Keputusan Handover : {eval_result['total_handovers']}")
    print(f" Kejadian Ping-pong       : {eval_result['ping_pong_count']}")
    print(f" Rasio Ping-pong (Rate)   : {eval_result['ping_pong_rate'] * 100:.2f}%")
    print("-" * 76)
    print(f" {'Detik':>6} | {'Jaringan Aktif':14} | {'Target Pilihan':14} | {'Handover?':>9} | {'Skor Terbaik':>12}")
    print(f" {'-'*6} | {'-'*14} | {'-'*14} | {'-'*9} | {'-'*12}")

    for item in eval_result["history"][:10]:
        dec = item["step_decision"]
        ho_str = "YA" if dec["handover_recommended"] else "TIDAK"
        print(
            f" {dec['timestamp_s']:5.1f}s | {dec['current_network']:14} | "
            f"{dec['target_network']:14} | {ho_str:>9} | {dec['best_utility_score']:12.4f}"
        )
    print("  ... (10 langkah berikutnya disederhanakan)")
    print("=" * 76)
    print(" Baseline Single TOPSIS Utility Function selesai dijalankan dengan sukses.")


if __name__ == "__main__":
    main()
