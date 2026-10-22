"""Hasil yang benar-benar didukung oleh fondasi Pekan 3."""

from dataclasses import asdict

from ..models import ScenarioSnapshot
from ..network.candidates import available_candidates


def validation_report(snapshot: ScenarioSnapshot) -> dict:
    """Susun laporan input, tanpa menghitung keputusan handover."""
    return {
        "status": "validated_input_only",
        "snapshot": asdict(snapshot),
        "available_candidates": [network.id for network in available_candidates(snapshot)],
        "handover_decision": None,
        "note": "Fuzzy dan TOPSIS belum diimplementasikan pada Pekan 3.",
    }
