"""Runner evaluasi simulasi untuk Baseline Single TOPSIS Utility Function."""

from __future__ import annotations

from typing import Sequence
from ..models import ScenarioSnapshot
from .topsis_utility import SingleTopsisUtilityFunction


def run_baseline_topsis_scenario(
    snapshots: Sequence[ScenarioSnapshot],
    hysteresis_margin: float = 0.0,
    criteria_names: Sequence[str] | None = None,
    custom_weights: dict[str, float] | None = None,
) -> dict:
    """Menjalankan evaluasi beruntun Single TOPSIS pada deretan snapshot simulasi.

    Menghitung metrik performa:
    - Jumlah rekomendasi handover
    - Ping-pong handover count (kembali ke jaringan asal dalam < 3 interval)
    - Riwayat keputusan per timestep
    """
    if not snapshots:
        raise ValueError("Daftar snapshot tidak boleh kosong.")

    engine = SingleTopsisUtilityFunction()
    history: list[dict] = []
    handover_count = 0
    ping_pong_count = 0

    # Menyimpan jejak perpindahan (timestamp, from_net, to_net)
    handover_events: list[tuple[float, str, str]] = []

    current_simulated_network = snapshots[0].current_network

    for snapshot in snapshots:
        # Perbarui snapshot dengan jaringan aktif simulasi jika telah berpindah
        effective_snapshot = ScenarioSnapshot(
            timestamp_s=snapshot.timestamp_s,
            current_network=current_simulated_network,
            velocity_mps=snapshot.velocity_mps,
            traffic_class=snapshot.traffic_class,
            networks=snapshot.networks,
        )

        decision = engine.decide_handover(
            effective_snapshot,
            hysteresis_margin=hysteresis_margin,
            criteria_names=criteria_names,
        )

        is_ho = decision["handover_recommended"]
        target_net = decision["target_network"]

        if is_ho:
            handover_count += 1
            # Deteksi ping-pong: jika kembali ke jaringan sebelumnya dalam interval < 3 detik
            if handover_events:
                prev_time, prev_from, prev_to = handover_events[-1]
                if target_net == prev_from and (snapshot.timestamp_s - prev_time) <= 3.0:
                    ping_pong_count += 1

            handover_events.append((snapshot.timestamp_s, current_simulated_network, target_net))
            current_simulated_network = target_net

        history.append({
            "step_decision": decision,
            "active_network": current_simulated_network,
        })

    ping_pong_rate = (ping_pong_count / handover_count) if handover_count > 0 else 0.0

    return {
        "total_timesteps": len(snapshots),
        "total_handovers": handover_count,
        "ping_pong_count": ping_pong_count,
        "ping_pong_rate": round(ping_pong_rate, 4),
        "history": history,
    }
