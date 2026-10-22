"""Generator profil jaringan heterogen (4G / 5G / WLAN).

Menghasilkan nilai RSS, Data Rate, Delay, dan BER yang realistis
berdasarkan rentang spesifikasi tiap teknologi serta variasi kondisi
jaringan (good, moderate, poor).

Modul ini menyediakan:
1. `TechnologyProfile` — rentang parameter QoS per teknologi.
2. `NetworkProfile` — representasi data profil lengkap dengan metadata & JSON export.
3. `HeterogeneousProfileGenerator` — generator modular multi-kondisi, batch, & temporal.
4. `NetworkNode` & `NetworkProfileGenerator` — generator berbasis koordinat jarak pengguna.
5. `generate_scenario_snapshots` & `create_default_scenario` — skenario multi-timestep.
6. `load_profiles_from_json` — pemuat profil kanonis dari file konfigurasi.

Referensi rentang parameter:
- 4G (LTE):  RSS −120…−50 dBm, data rate 1…100 Mbps,
             delay 10…100 ms, BER 1e-6…1e-3
- 5G (NR):   RSS −110…−40 dBm, data rate 50…1000 Mbps,
             delay 1…20 ms, BER 1e-8…1e-5
- WLAN:      RSS −90…−30 dBm, data rate 1…600 Mbps,
             delay 5…50 ms, BER 1e-7…1e-4
"""

from __future__ import annotations

import json
import math
from pathlib import Path
import random
from dataclasses import dataclass, field
from typing import Any, Sequence

from ..models import NetworkSnapshot, ScenarioSnapshot, TECHNOLOGIES, TRAFFIC_CLASSES

CONDITIONS = frozenset({"good", "moderate", "poor", "random"})


# ---------------------------------------------------------------------------
# 1. Profil teknologi — rentang realistis tiap parameter QoS
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class TechnologyProfile:
    """Rentang parameter QoS untuk satu teknologi jaringan."""

    technology: str

    # RSS (Received Signal Strength) dalam dBm
    rss_min: float
    rss_max: float

    # Data rate dalam Mbps
    data_rate_min: float
    data_rate_max: float

    # Delay (latency) dalam ms
    delay_min: float
    delay_max: float

    # BER (Bit Error Rate) — rasio 0–1
    ber_min: float
    ber_max: float

    # Jangkauan efektif dalam meter (untuk model jarak)
    coverage_radius_m: float = 500.0

    def __post_init__(self) -> None:
        if self.technology not in TECHNOLOGIES:
            raise ValueError(
                f"Teknologi '{self.technology}' tidak didukung. "
                f"Gunakan salah satu dari {sorted(TECHNOLOGIES)}."
            )
        if self.rss_min > self.rss_max:
            raise ValueError(
                f"rss_min ({self.rss_min}) tidak boleh > rss_max ({self.rss_max})"
            )
        if self.data_rate_min > self.data_rate_max:
            raise ValueError(
                f"data_rate_min ({self.data_rate_min}) tidak boleh > data_rate_max ({self.data_rate_max})"
            )
        if self.delay_min > self.delay_max:
            raise ValueError(
                f"delay_min ({self.delay_min}) tidak boleh > delay_max ({self.delay_max})"
            )
        if self.ber_min > self.ber_max:
            raise ValueError(
                f"ber_min ({self.ber_min}) tidak boleh > ber_max ({self.ber_max})"
            )
        if self.coverage_radius_m <= 0:
            raise ValueError("coverage_radius_m harus > 0")


# Profil default berdasarkan literatur dan spesifikasi 3GPP / ITU-R / IEEE
DEFAULT_PROFILES: dict[str, TechnologyProfile] = {
    "4G": TechnologyProfile(
        technology="4G",
        rss_min=-120.0, rss_max=-50.0,
        data_rate_min=1.0, data_rate_max=100.0,
        delay_min=10.0, delay_max=100.0,
        ber_min=1e-6, ber_max=1e-3,
        coverage_radius_m=1000.0,
    ),
    "5G": TechnologyProfile(
        technology="5G",
        rss_min=-110.0, rss_max=-40.0,
        data_rate_min=50.0, data_rate_max=1000.0,
        delay_min=1.0, delay_max=20.0,
        ber_min=1e-8, ber_max=1e-5,
        coverage_radius_m=500.0,
    ),
    "WLAN": TechnologyProfile(
        technology="WLAN",
        rss_min=-90.0, rss_max=-30.0,
        data_rate_min=1.0, data_rate_max=600.0,
        delay_min=5.0, delay_max=50.0,
        ber_min=1e-7, ber_max=1e-4,
        coverage_radius_m=100.0,
    ),
}


def load_profiles_from_json(
    path: str | Path | None = None,
) -> dict[str, TechnologyProfile]:
    """Muat TechnologyProfile dari berkas JSON eksternal seperti qos_profiles.json."""
    if path is None:
        default_path = Path(__file__).parent / "qos_profiles.json"
        if default_path.is_file():
            path = default_path
        else:
            return dict(DEFAULT_PROFILES)

    filepath = Path(path)
    if not filepath.is_file():
        raise FileNotFoundError(f"Berkas konfigurasi profil tidak ditemukan: {filepath}")

    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)

    profiles_data = data.get("profiles", {})
    loaded: dict[str, TechnologyProfile] = {}
    for tech, info in profiles_data.items():
        if tech not in TECHNOLOGIES:
            continue
        params = info.get("parameters", {})
        loaded[tech] = TechnologyProfile(
            technology=tech,
            rss_min=float(params.get("rss_dbm", {}).get("min", DEFAULT_PROFILES[tech].rss_min)),
            rss_max=float(params.get("rss_dbm", {}).get("max", DEFAULT_PROFILES[tech].rss_max)),
            data_rate_min=float(params.get("data_rate_mbps", {}).get("min", DEFAULT_PROFILES[tech].data_rate_min)),
            data_rate_max=float(params.get("data_rate_mbps", {}).get("max", DEFAULT_PROFILES[tech].data_rate_max)),
            delay_min=float(params.get("delay_ms", {}).get("min", DEFAULT_PROFILES[tech].delay_min)),
            delay_max=float(params.get("delay_ms", {}).get("max", DEFAULT_PROFILES[tech].delay_max)),
            ber_min=float(params.get("ber", {}).get("min", DEFAULT_PROFILES[tech].ber_min)),
            ber_max=float(params.get("ber", {}).get("max", DEFAULT_PROFILES[tech].ber_max)),
            coverage_radius_m=float(info.get("coverage_radius_m", DEFAULT_PROFILES[tech].coverage_radius_m)),
        )

    for tech in TECHNOLOGIES:
        if tech not in loaded and tech in DEFAULT_PROFILES:
            loaded[tech] = DEFAULT_PROFILES[tech]

    return loaded


# ---------------------------------------------------------------------------
# 2. Entitas profil jaringan terstruktur (NetworkProfile)
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class NetworkProfile:
    """Profil jaringan heterogen lengkap dengan kondisi operasional dan metadata."""

    profile_id: str
    technology: str
    condition: str
    rss_dbm: float
    data_rate_mbps: float
    delay_ms: float
    ber: float
    timestamp_s: float = 0.0
    available: bool = True
    metadata: dict[str, Any] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if not isinstance(self.profile_id, str) or not self.profile_id.strip():
            raise ValueError("profile_id harus berupa string non-kosong")
        if self.technology not in TECHNOLOGIES:
            raise ValueError(
                f"technology '{self.technology}' tidak didukung ({sorted(TECHNOLOGIES)})"
            )
        if not math.isfinite(self.rss_dbm):
            raise ValueError("rss_dbm harus berupa angka finite")
        if not math.isfinite(self.data_rate_mbps) or self.data_rate_mbps < 0:
            raise ValueError(
                f"data_rate_mbps harus berupa angka finite >= 0, dapat {self.data_rate_mbps}"
            )
        if not math.isfinite(self.delay_ms) or self.delay_ms < 0:
            raise ValueError(
                f"delay_ms harus berupa angka finite >= 0, dapat {self.delay_ms}"
            )
        if not math.isfinite(self.ber) or not (0.0 <= self.ber <= 1.0):
            raise ValueError(
                f"ber harus berupa rasio [0, 1], dapat {self.ber}"
            )
        if not isinstance(self.available, bool):
            raise ValueError("available harus berupa boolean")

    def to_dict(self) -> dict[str, Any]:
        """Konversi ke format dictionary JSON terstandar."""
        meta = {
            "data_source": "synthetic",
            "model_version": "1.0",
        }
        meta.update(self.metadata)
        return {
            "profile_id": self.profile_id,
            "technology": self.technology,
            "condition": self.condition,
            "timestamp": self.timestamp_s,
            "parameters": {
                "rss_dbm": self.rss_dbm,
                "data_rate_mbps": self.data_rate_mbps,
                "delay_ms": self.delay_ms,
                "ber": self.ber,
            },
            "available": self.available,
            "metadata": meta,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "NetworkProfile":
        """Bangkitkan NetworkProfile dari dictionary JSON terstandar."""
        if not isinstance(data, dict):
            raise ValueError("data harus berupa dictionary JSON")
        profile_id = data.get("profile_id")
        technology = data.get("technology")
        condition = data.get("condition", "moderate")
        timestamp = float(data.get("timestamp", data.get("timestamp_s", 0.0)))
        params = data.get("parameters", {})
        if not isinstance(params, dict):
            raise ValueError("parameters harus berupa dictionary")
        rss = float(params.get("rss_dbm", data.get("rss_dbm", 0.0)))
        rate = float(params.get("data_rate_mbps", data.get("data_rate_mbps", 0.0)))
        delay = float(params.get("delay_ms", data.get("delay_ms", 0.0)))
        ber = float(params.get("ber", data.get("ber", 0.0)))
        available = bool(data.get("available", True))
        metadata = dict(data.get("metadata", {}))
        return cls(
            profile_id=str(profile_id),
            technology=str(technology),
            condition=str(condition),
            rss_dbm=rss,
            data_rate_mbps=rate,
            delay_ms=delay,
            ber=ber,
            timestamp_s=timestamp,
            available=available,
            metadata=metadata,
        )

    def to_network_snapshot(self) -> NetworkSnapshot:
        """Konversi ke NetworkSnapshot untuk evaluasi TOPSIS dan model pipeline."""
        return NetworkSnapshot(
            id=self.profile_id,
            technology=self.technology,
            rss_dbm=self.rss_dbm,
            data_rate_mbps=self.data_rate_mbps,
            delay_ms=self.delay_ms,
            ber=self.ber,
            available=self.available,
        )


# ---------------------------------------------------------------------------
# 3. Konfigurasi generator
# ---------------------------------------------------------------------------

@dataclass
class GeneratorConfig:
    """Konfigurasi untuk HeterogeneousProfileGenerator."""

    num_profiles: int = 10
    technologies: Sequence[str] = ("4G", "5G", "WLAN")
    condition: str = "moderate"
    seed: int | None = None
    dt_s: float = 1.0
    network_load: float = 0.5
    include_metadata: bool = True

    def __post_init__(self) -> None:
        if self.num_profiles < 1:
            raise ValueError("num_profiles harus >= 1")
        if not self.technologies:
            raise ValueError("technologies tidak boleh kosong")
        for tech in self.technologies:
            if tech not in TECHNOLOGIES:
                raise ValueError(f"Teknologi '{tech}' tidak didukung")
        if self.condition not in CONDITIONS and self.condition != "mixed":
            raise ValueError(
                f"condition '{self.condition}' tidak valid. "
                f"Gunakan salah satu dari {sorted(CONDITIONS)} atau 'mixed'."
            )
        if self.dt_s <= 0:
            raise ValueError("dt_s harus > 0")
        if not (0.0 <= self.network_load <= 1.0):
            raise ValueError("network_load harus berada pada rentang [0.0, 1.0]")


# ---------------------------------------------------------------------------
# 4. Generator profil jaringan heterogen multi-kondisi
# ---------------------------------------------------------------------------

@dataclass
class HeterogeneousProfileGenerator:
    """Generator profil jaringan heterogen multi-kondisi (good, moderate, poor).

    Mendukung pembangkitan profil individual, batch multi-teknologi,
    dan deret temporal berbasis model korelasi fisik (Path Loss, Shannon/MCS,
    dan koreksi error) atau distribusi probabilistik per kondisi.
    """

    profiles: dict[str, TechnologyProfile] = field(
        default_factory=lambda: dict(DEFAULT_PROFILES)
    )
    rng: random.Random = field(default_factory=random.Random)
    seed: int | None = None

    def __post_init__(self) -> None:
        if self.seed is not None:
            self.rng = random.Random(self.seed)

    # -- Utilitas interpolasi internal ------------------------------------

    @staticmethod
    def _lerp(lo: float, hi: float, t: float) -> float:
        return lo + (hi - lo) * max(0.0, min(1.0, t))

    @staticmethod
    def _lerp_log(lo: float, hi: float, t: float) -> float:
        floor = 1e-9
        eff_lo = max(lo, floor)
        eff_hi = max(hi, floor)
        log_lo = math.log10(eff_lo)
        log_hi = math.log10(eff_hi)
        val = 10 ** (log_lo + (log_hi - log_lo) * max(0.0, min(1.0, t)))
        return max(0.0, min(1.0, val))

    def _sample_quality_factor(self, condition: str) -> float:
        """Sampel faktor kualitas sinyal rho in [0, 1] berdasarkan kondisi."""
        if condition == "good":
            # Kondisi baik: rho tinggi (0.65 - 0.98), mode di 0.85
            return self.rng.triangular(0.65, 0.98, 0.85)
        elif condition == "moderate":
            # Kondisi sedang: rho menengah (0.35 - 0.75), mode di 0.55
            return self.rng.triangular(0.35, 0.75, 0.55)
        elif condition == "poor":
            # Kondisi buruk: rho rendah (0.05 - 0.40), mode di 0.20
            return self.rng.triangular(0.05, 0.40, 0.20)
        elif condition == "random":
            return self.rng.uniform(0.05, 0.95)
        else:
            raise ValueError(
                f"Kondisi '{condition}' tidak dikenal. "
                f"Pilih salah satu dari: {sorted(CONDITIONS)}."
            )

    # -- API Utama --------------------------------------------------------

    def generate_profile(
        self,
        technology: str,
        condition: str = "moderate",
        *,
        profile_id: str | None = None,
        timestamp_s: float = 0.0,
        network_load: float = 0.5,
        metadata: dict[str, Any] | None = None,
    ) -> NetworkProfile:
        """Bangkitkan satu NetworkProfile berdasarkan teknologi dan kondisi.

        Parameter:
            technology: "4G", "5G", atau "WLAN".
            condition: "good", "moderate", "poor", atau "random".
            profile_id: ID unik (default otomatis jika None).
            timestamp_s: Waktu generasi dalam detik.
            network_load: Faktor beban antrean/kemacetan [0.0, 1.0].
            metadata: Informasi atribut tambahan.
        """
        if technology not in TECHNOLOGIES:
            raise ValueError(f"Teknologi '{technology}' tidak didukung ({sorted(TECHNOLOGIES)})")
        if condition not in CONDITIONS:
            raise ValueError(f"Kondisi '{condition}' tidak didukung ({sorted(CONDITIONS)})")

        prof = self.profiles.get(technology, DEFAULT_PROFILES[technology])
        rho = self._sample_quality_factor(condition)

        # 1. RSS: Mengikuti faktor kualitas dengan residu shadow fading
        rss_span = prof.rss_max - prof.rss_min
        rss_noise = self.rng.gauss(0, 1.0)
        rss = prof.rss_min + (rho * rss_span) + rss_noise
        rss = max(prof.rss_min, min(prof.rss_max, round(rss, 2)))

        # 2. Data Rate: Non-linear terhadap rho^1.5 dan terdegradasi oleh network_load
        rate_span = prof.data_rate_max - prof.data_rate_min
        rate_factor = math.pow(rho, 1.5)
        load_penalty = 1.0 - (0.25 * max(0.0, min(1.0, network_load)))
        rate_noise = self.rng.gauss(0, 0.02 * rate_span)
        rate = prof.data_rate_min + (rate_span * rate_factor * load_penalty) + rate_noise
        rate = max(prof.data_rate_min * 0.5, min(prof.data_rate_max, round(rate, 3)))

        # 3. Delay: Berbanding terbalik (1 - rho)^1.2 dan memanjang akibat antrean beban
        delay_span = prof.delay_max - prof.delay_min
        delay_factor = math.pow(1.0 - rho, 1.2)
        load_delay = 1.0 + (0.40 * max(0.0, min(1.0, network_load)))
        delay_noise = self.rng.gauss(0, 0.03 * delay_span)
        delay = prof.delay_min + (delay_span * delay_factor * load_delay) + delay_noise
        delay = max(prof.delay_min * 0.8, min(prof.delay_max * 1.5, round(delay, 3)))

        # 4. BER: Logaritmik menurun drastis seiring meningkatnya kualitas sinyal
        ber_t = max(0.0, min(1.0, 1.0 - rho + self.rng.gauss(0, 0.05)))
        ber = self._lerp_log(prof.ber_min, prof.ber_max, ber_t)

        # 5. Ketersediaan (availability gating)
        available = (rho >= 0.05) and (rss >= prof.rss_min)

        pid = profile_id or f"{technology.lower()}_{self.rng.randint(1000, 9999)}"

        meta = {
            "metric_type": "RSSI" if technology == "WLAN" else ("SS-RSRP" if technology == "5G" else "RSRP"),
            "quality_factor": round(rho, 4),
            "network_load": network_load,
        }
        if metadata:
            meta.update(metadata)

        return NetworkProfile(
            profile_id=pid,
            technology=technology,
            condition=condition,
            rss_dbm=rss,
            data_rate_mbps=rate,
            delay_ms=delay,
            ber=ber,
            timestamp_s=timestamp_s,
            available=available,
            metadata=meta,
        )

    def generate_batch(
        self,
        count: int = 10,
        technologies: Sequence[str] | None = None,
        condition: str = "moderate",
        id_prefix: str = "profile",
    ) -> list[NetworkProfile]:
        """Bangkitkan daftar sejumlah `count` profil jaringan heterogen."""
        if count < 1:
            raise ValueError("count harus >= 1")
        tech_list = list(technologies or ("4G", "5G", "WLAN"))
        for t in tech_list:
            if t not in TECHNOLOGIES:
                raise ValueError(f"Teknologi '{t}' tidak didukung")

        cond_cycle = ["good", "moderate", "poor"]
        profiles: list[NetworkProfile] = []

        for i in range(count):
            tech = tech_list[i % len(tech_list)]
            if condition == "mixed":
                c = cond_cycle[i % len(cond_cycle)]
            else:
                c = condition
            pid = f"{id_prefix}_{tech.lower()}_{i+1:03d}"
            prof = self.generate_profile(
                technology=tech,
                condition=c,
                profile_id=pid,
                timestamp_s=round(i * 0.5, 2),
            )
            profiles.append(prof)

        return profiles

    def generate_temporal_sequence(
        self,
        technology: str,
        num_steps: int = 10,
        dt_s: float = 1.0,
        condition: str = "moderate",
        profile_id: str | None = None,
        correlation: float = 0.85,
        network_load: float = 0.5,
    ) -> list[NetworkProfile]:
        """Bangkitkan deretan temporal NetworkProfile dengan drift berkorelasi halus."""
        if num_steps < 1:
            raise ValueError("num_steps harus >= 1")
        if dt_s <= 0:
            raise ValueError("dt_s harus > 0")
        if technology not in TECHNOLOGIES:
            raise ValueError(f"Teknologi '{technology}' tidak didukung")

        target_rho = {
            "good": 0.85,
            "moderate": 0.55,
            "poor": 0.20,
            "random": 0.50,
        }.get(condition, 0.55)

        current_rho = self._sample_quality_factor(condition)
        pid = profile_id or f"{technology.lower()}_temporal"
        sequence: list[NetworkProfile] = []

        prof = self.profiles.get(technology, DEFAULT_PROFILES[technology])

        for step in range(num_steps):
            timestamp = round(step * dt_s, 3)

            # Auto-regressive AR(1) drift: rho_t = alpha * rho_{t-1} + (1 - alpha) * target + noise
            noise = self.rng.gauss(0, 0.03)
            current_rho = (correlation * current_rho) + ((1.0 - correlation) * target_rho) + noise
            current_rho = max(0.02, min(0.98, current_rho))

            # Hitung parameter fisik
            rss_span = prof.rss_max - prof.rss_min
            rss = prof.rss_min + (current_rho * rss_span) + self.rng.gauss(0, 0.5)
            rss = max(prof.rss_min, min(prof.rss_max, round(rss, 2)))

            rate_span = prof.data_rate_max - prof.data_rate_min
            rate_factor = math.pow(current_rho, 1.5)
            rate = prof.data_rate_min + (rate_span * rate_factor * (1.0 - 0.2 * network_load))
            rate = max(prof.data_rate_min * 0.5, min(prof.data_rate_max, round(rate, 3)))

            delay_span = prof.delay_max - prof.delay_min
            delay_factor = math.pow(1.0 - current_rho, 1.2)
            delay = prof.delay_min + (delay_span * delay_factor * (1.0 + 0.3 * network_load))
            delay = max(prof.delay_min * 0.8, min(prof.delay_max * 1.5, round(delay, 3)))

            ber_t = max(0.0, min(1.0, 1.0 - current_rho + self.rng.gauss(0, 0.02)))
            ber = self._lerp_log(prof.ber_min, prof.ber_max, ber_t)

            available = (current_rho >= 0.05) and (rss >= prof.rss_min)

            item = NetworkProfile(
                profile_id=pid,
                technology=technology,
                condition=condition,
                rss_dbm=rss,
                data_rate_mbps=rate,
                delay_ms=delay,
                ber=ber,
                timestamp_s=timestamp,
                available=available,
                metadata={
                    "step": step,
                    "temporal_rho": round(current_rho, 4),
                    "network_load": network_load,
                },
            )
            sequence.append(item)

        return sequence


# ---------------------------------------------------------------------------
# 5. Konfigurasi jaringan node koordinat (NetworkNode)
# ---------------------------------------------------------------------------

@dataclass
class NetworkNode:
    """Satu node jaringan dengan posisi dan profil teknologi.

    Posisi (``x``, ``y``) dalam meter digunakan untuk menghitung RSS
    berdasarkan jarak ke pengguna. Jika posisi tidak diatur, generator
    akan membangkitkan parameter secara acak murni.
    """

    id: str
    technology: str
    profile: TechnologyProfile | None = None  # None -> gunakan DEFAULT_PROFILES
    x: float = 0.0
    y: float = 0.0

    def resolved_profile(self) -> TechnologyProfile:
        """Kembalikan profil eksplisit atau profil default teknologi."""
        if self.profile is not None:
            return self.profile
        return DEFAULT_PROFILES[self.technology]


# ---------------------------------------------------------------------------
# 6. Generator berbasis mobilitas & koordinat (NetworkProfileGenerator)
# ---------------------------------------------------------------------------

@dataclass
class NetworkProfileGenerator:
    """Membangkitkan ``NetworkSnapshot`` untuk setiap node pada setiap timestep.

    Parameter QoS dihasilkan dalam dua mode:
    * **Mode jarak** — jika posisi pengguna (user_x, user_y) diberikan, RSS dihitung
      menggunakan Log-Distance Path Loss. Data rate, delay, dan BER diskalakan
      proporsional terhadap kualitas sinyal.
    * **Mode acak** — jika posisi tidak diberikan, parameter dibangkitkan secara
      seragam dari rentang profil teknologi.
    """

    nodes: list[NetworkNode] = field(default_factory=list)
    rng: random.Random = field(default_factory=random.Random)
    path_loss_exponent: float = 3.0
    reference_distance_m: float = 1.0
    shadow_fading_std: float = 4.0

    @staticmethod
    def _lerp(lo: float, hi: float, t: float) -> float:
        return lo + (hi - lo) * max(0.0, min(1.0, t))

    @staticmethod
    def _lerp_log(lo: float, hi: float, t: float) -> float:
        if lo <= 0 or hi <= 0:
            return lo
        log_lo = math.log10(lo)
        log_hi = math.log10(hi)
        return 10 ** (log_lo + (log_hi - log_lo) * max(0.0, min(1.0, t)))

    def _quality_factor_from_distance(
        self,
        node: NetworkNode,
        user_x: float,
        user_y: float,
    ) -> tuple[float, bool]:
        profile = node.resolved_profile()
        dx = user_x - node.x
        dy = user_y - node.y
        distance = math.sqrt(dx * dx + dy * dy)

        if distance < self.reference_distance_m:
            distance = self.reference_distance_m

        available = distance <= profile.coverage_radius_m
        ratio = distance / profile.coverage_radius_m
        quality = max(0.0, min(1.0, 1.0 - ratio))
        return quality, available

    def _compute_rss_from_distance(
        self,
        profile: TechnologyProfile,
        distance: float,
    ) -> float:
        if distance < self.reference_distance_m:
            distance = self.reference_distance_m

        path_loss = 10.0 * self.path_loss_exponent * math.log10(
            distance / self.reference_distance_m
        )
        shadow = self.rng.gauss(0, self.shadow_fading_std)
        rss = profile.rss_max - path_loss + shadow
        return max(profile.rss_min, min(profile.rss_max, rss))

    def generate_snapshot(
        self,
        node: NetworkNode,
        *,
        user_x: float | None = None,
        user_y: float | None = None,
    ) -> NetworkSnapshot:
        """Bangkitkan satu ``NetworkSnapshot`` untuk ``node``."""
        profile = node.resolved_profile()

        if user_x is not None and user_y is not None:
            quality, available = self._quality_factor_from_distance(
                node, user_x, user_y,
            )
            dx = user_x - node.x
            dy = user_y - node.y
            distance = math.sqrt(dx * dx + dy * dy)
            rss = self._compute_rss_from_distance(profile, distance)

            noise = self.rng.gauss(0, 0.05)
            q = max(0.0, min(1.0, quality + noise))

            data_rate = self._lerp(profile.data_rate_min, profile.data_rate_max, q)
            delay = self._lerp(profile.delay_max, profile.delay_min, q)
            ber = self._lerp_log(profile.ber_min, profile.ber_max, 1.0 - q)
        else:
            rss = self.rng.uniform(profile.rss_min, profile.rss_max)
            data_rate = self.rng.uniform(profile.data_rate_min, profile.data_rate_max)
            delay = self.rng.uniform(profile.delay_min, profile.delay_max)
            ber = self._lerp_log(
                profile.ber_min, profile.ber_max, self.rng.random(),
            )
            available = True

        rss = round(rss, 2)
        data_rate = round(max(data_rate, 0.0), 3)
        delay = round(max(delay, 0.0), 3)
        ber = max(0.0, min(1.0, ber))

        return NetworkSnapshot(
            id=node.id,
            technology=node.technology,
            rss_dbm=rss,
            data_rate_mbps=data_rate,
            delay_ms=delay,
            ber=ber,
            available=available,
        )

    def generate_all(
        self,
        *,
        user_x: float | None = None,
        user_y: float | None = None,
    ) -> list[NetworkSnapshot]:
        """Bangkitkan ``NetworkSnapshot`` untuk semua node yang terdaftar."""
        return [
            self.generate_snapshot(node, user_x=user_x, user_y=user_y)
            for node in self.nodes
        ]


# ---------------------------------------------------------------------------
# 7. Pembangun skenario multi-timestep
# ---------------------------------------------------------------------------

def generate_scenario_snapshots(
    nodes: Sequence[NetworkNode],
    *,
    num_steps: int = 10,
    dt_s: float = 1.0,
    velocity_mps: float = 10.0,
    traffic_class: str = "streaming",
    initial_network: str | None = None,
    user_start_x: float = 0.0,
    user_start_y: float = 0.0,
    user_direction_deg: float = 0.0,
    seed: int | None = None,
    path_loss_exponent: float = 3.0,
    shadow_fading_std: float = 4.0,
    mobility_model: Any | None = None,
) -> list[ScenarioSnapshot]:
    """Bangkitkan deretan ``ScenarioSnapshot`` untuk simulasi."""
    if not nodes:
        raise ValueError("Harus ada minimal satu node jaringan.")
    if traffic_class not in TRAFFIC_CLASSES:
        raise ValueError(
            f"traffic_class '{traffic_class}' tidak dikenal. "
            f"Gunakan salah satu dari {sorted(TRAFFIC_CLASSES)}."
        )
    if num_steps < 1:
        raise ValueError("num_steps harus >= 1.")
    if dt_s <= 0:
        raise ValueError("dt_s harus > 0.")
    if velocity_mps < 0:
        raise ValueError("velocity_mps harus >= 0.")

    rng = random.Random(seed)
    generator = NetworkProfileGenerator(
        nodes=list(nodes),
        rng=rng,
        path_loss_exponent=path_loss_exponent,
        shadow_fading_std=shadow_fading_std,
    )

    direction_rad = math.radians(user_direction_deg)
    vx = velocity_mps * math.cos(direction_rad)
    vy = velocity_mps * math.sin(direction_rad)

    if mobility_model is not None:
        user_x = mobility_model.current_state.position.x
        user_y = mobility_model.current_state.position.y
        current_v = mobility_model.current_state.current_speed
    else:
        user_x = user_start_x
        user_y = user_start_y
        current_v = velocity_mps

    current_network = initial_network
    snapshots: list[ScenarioSnapshot] = []

    for step in range(num_steps):
        timestamp = step * dt_s
        networks = generator.generate_all(user_x=user_x, user_y=user_y)

        available_ids = {n.id for n in networks if n.available}
        if current_network is None or current_network not in available_ids:
            if available_ids:
                best = max(
                    (n for n in networks if n.available),
                    key=lambda n: n.rss_dbm,
                )
                current_network = best.id
            else:
                fallback = NetworkSnapshot(
                    id=networks[0].id,
                    technology=networks[0].technology,
                    rss_dbm=networks[0].rss_dbm,
                    data_rate_mbps=networks[0].data_rate_mbps,
                    delay_ms=networks[0].delay_ms,
                    ber=networks[0].ber,
                    available=True,
                )
                networks[0] = fallback
                current_network = fallback.id

        snapshot = ScenarioSnapshot(
            timestamp_s=round(timestamp, 3),
            current_network=current_network,
            velocity_mps=current_v,
            traffic_class=traffic_class,
            networks=tuple(networks),
        )
        snapshots.append(snapshot)

        if mobility_model is not None:
            mob_state = mobility_model.step(dt_s)
            user_x = mob_state.position.x
            user_y = mob_state.position.y
            current_v = mob_state.current_speed
        else:
            user_x += vx * dt_s
            user_y += vy * dt_s

    return snapshots


# ---------------------------------------------------------------------------
# 8. Utilitas: buat skenario default cepat
# ---------------------------------------------------------------------------

def create_default_scenario(
    *,
    seed: int | None = 42,
    num_steps: int = 20,
    velocity_mps: float = 10.0,
    traffic_class: str = "streaming",
) -> list[ScenarioSnapshot]:
    """Bangkitkan skenario default dengan 3 jaringan (4G, 5G, WLAN)."""
    nodes = [
        NetworkNode(id="lte_1", technology="4G", x=0.0, y=50.0),
        NetworkNode(id="nr_1", technology="5G", x=200.0, y=-30.0),
        NetworkNode(id="wlan_1", technology="WLAN", x=80.0, y=10.0),
    ]
    return generate_scenario_snapshots(
        nodes,
        num_steps=num_steps,
        dt_s=1.0,
        velocity_mps=velocity_mps,
        traffic_class=traffic_class,
        user_start_x=0.0,
        user_start_y=0.0,
        user_direction_deg=0.0,
        seed=seed,
    )
