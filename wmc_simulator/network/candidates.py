"""Temukan jaringan alternatif yang tersedia pada satu snapshot."""

from ..models import NetworkSnapshot, ScenarioSnapshot


def available_candidates(snapshot: ScenarioSnapshot) -> tuple[NetworkSnapshot, ...]:
    """Kembalikan kandidat selain jaringan aktif, tanpa memberi peringkat."""
    return tuple(
        network
        for network in snapshot.networks
        if network.available and network.id != snapshot.current_network
    )
