"""Kontrak data awal; rentang QoS teknologi belum ditetapkan."""

from dataclasses import dataclass
from math import isfinite


TECHNOLOGIES = frozenset({"4G", "5G", "WLAN"})
TRAFFIC_CLASSES = frozenset({"conversational", "streaming", "interactive", "background"})


def _number(value: object, name: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not isfinite(value):
        raise ValueError(f"{name} harus angka finite")
    return float(value)


@dataclass(frozen=True)
class NetworkSnapshot:
    id: str
    technology: str
    rss_dbm: float
    data_rate_mbps: float
    delay_ms: float
    ber: float
    available: bool

    @classmethod
    def from_dict(cls, data: dict) -> "NetworkSnapshot":
        if not isinstance(data, dict):
            raise ValueError("setiap network harus objek JSON")
        if not isinstance(data.get("id"), str) or not data["id"].strip():
            raise ValueError("network.id harus teks nonkosong")
        if not isinstance(data.get("technology"), str) or data["technology"] not in TECHNOLOGIES:
            raise ValueError("network.technology harus 4G, 5G, atau WLAN")
        if not isinstance(data.get("available"), bool):
            raise ValueError("network.available harus boolean")
        rss = _number(data.get("rss_dbm"), "rss_dbm")
        rate = _number(data.get("data_rate_mbps"), "data_rate_mbps")
        delay = _number(data.get("delay_ms"), "delay_ms")
        ber = _number(data.get("ber"), "ber")
        if rate < 0 or delay < 0 or not 0 <= ber <= 1:
            raise ValueError("data_rate_mbps dan delay_ms harus >= 0; ber harus 0–1")
        return cls(data["id"], data["technology"], rss, rate, delay, ber, data["available"])


@dataclass(frozen=True)
class ScenarioSnapshot:
    timestamp_s: float
    current_network: str
    velocity_mps: float
    traffic_class: str
    networks: tuple[NetworkSnapshot, ...]

    @classmethod
    def from_dict(cls, data: dict) -> "ScenarioSnapshot":
        if not isinstance(data, dict):
            raise ValueError("snapshot harus objek JSON")
        timestamp = _number(data.get("timestamp_s"), "timestamp_s")
        velocity = _number(data.get("velocity_mps"), "velocity_mps")
        if timestamp < 0 or velocity < 0:
            raise ValueError("timestamp_s dan velocity_mps harus >= 0")
        if not isinstance(data.get("traffic_class"), str) or data["traffic_class"] not in TRAFFIC_CLASSES:
            raise ValueError("traffic_class tidak dikenal")
        if not isinstance(data.get("networks"), list) or not data["networks"]:
            raise ValueError("networks harus daftar nonkosong")
        networks = tuple(NetworkSnapshot.from_dict(item) for item in data["networks"])
        ids = [item.id for item in networks]
        if len(ids) != len(set(ids)):
            raise ValueError("network.id harus unik")
        current = data.get("current_network")
        if current not in ids:
            raise ValueError("current_network tidak ditemukan di networks")
        if not next(item for item in networks if item.id == current).available:
            raise ValueError("current_network harus tersedia")
        return cls(timestamp, current, velocity, data["traffic_class"], networks)
