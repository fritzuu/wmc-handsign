"""Generator profil jaringan heterogen (4G / 5G / WLAN).

Menghasilkan nilai RSS, Data Rate, Delay, dan BER yang realistis
berdasarkan rentang spesifikasi tiap teknologi. Generator ini
menyediakan:

1. `TechnologyProfile` — rentang parameter QoS per teknologi.
2. `NetworkProfileGenerator` — membangkitkan `NetworkSnapshot` secara
   acak atau berdasarkan jarak/kecepatan pengguna.
3. `generate_scenario_snapshots` — membangkitkan deretan
   `ScenarioSnapshot` untuk simulasi multi-timestep.

Referensi rentang parameter:
- 4G (LTE):  RSS −120…−50 dBm, data rate 1…100 Mbps,
             delay 10…100 ms, BER 1e-6…1e-3
- 5G (NR):   RSS −110…−40 dBm, data rate 50…1000 Mbps,
             delay 1…20 ms, BER 1e-8…1e-5
- WLAN:      RSS −90…−30 dBm, data rate 1…600 Mbps,
             delay 5…50 ms, BER 1e-7…1e-4
"""

from __future__ import annotations

import math
import random
from dataclasses import dataclass, field
from typing import Sequence

from ..models import NetworkSnapshot, ScenarioSnapshot, TECHNOLOGIES, TRAFFIC_CLASSES


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


# Profil default berdasarkan literatur dan spesifikasi umum
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


# ---------------------------------------------------------------------------
# 2. Konfigurasi jaringan — definisi satu node jaringan dalam skenario
# ---------------------------------------------------------------------------

@dataclass
class NetworkNode:
    """Satu node jaringan dengan posisi dan profil teknologi.

    Posisi (``x``, ``y``) dalam meter digunakan untuk menghitung RSS
    berdasarkan jarak ke pengguna.  Jika posisi tidak diatur, generator
    akan membangkitkan parameter secara acak murni.
    """

    id: str
    technology: str
    profile: TechnologyProfile | None = None  # None → gunakan DEFAULT_PROFILES
    x: float = 0.0
    y: float = 0.0

    def resolved_profile(self) -> TechnologyProfile:
        """Kembalikan profil eksplisit atau profil default teknologi."""
        if self.profile is not None:
            return self.profile
        return DEFAULT_PROFILES[self.technology]


# ---------------------------------------------------------------------------
# 3. Generator utama
# ---------------------------------------------------------------------------

@dataclass
class NetworkProfileGenerator:
    """Membangkitkan ``NetworkSnapshot`` untuk setiap node pada setiap timestep.

    Parameter QoS dihasilkan dalam dua mode:

    *   **Mode jarak** — jika posisi pengguna (``user_x``, ``user_y``)
        diberikan, RSS dihitung dari jarak ke node menggunakan model
        *log-distance path loss*.  Data rate, delay, dan BER kemudian
        diskalakan secara proporsional terhadap kualitas sinyal.

    *   **Mode acak** — jika posisi tidak diberikan, parameter dibangkitkan
        secara seragam dari rentang profil teknologi.

    Atribut:
        nodes: Daftar ``NetworkNode`` yang tersedia di skenario.
        rng: Instance ``random.Random`` untuk reprodusibilitas (seed).
        path_loss_exponent: Eksponen path-loss untuk model propagasi
            (tipikal 2–4; default 3.0 untuk lingkungan urban).
        reference_distance_m: Jarak referensi (d₀) dalam meter.
        shadow_fading_std: Standar deviasi *shadow fading* Gaussian (dB).
    """

    nodes: list[NetworkNode] = field(default_factory=list)
    rng: random.Random = field(default_factory=random.Random)
    path_loss_exponent: float = 3.0
    reference_distance_m: float = 1.0
    shadow_fading_std: float = 4.0

    # -- Utilitas internal ------------------------------------------------

    @staticmethod
    def _lerp(lo: float, hi: float, t: float) -> float:
        """Interpolasi linier: ``t`` ∈ [0, 1] → [lo, hi]."""
        return lo + (hi - lo) * max(0.0, min(1.0, t))

    @staticmethod
    def _lerp_log(lo: float, hi: float, t: float) -> float:
        """Interpolasi logaritmik antara ``lo`` dan ``hi``.

        Cocok untuk BER yang rentangnya beberapa orde magnitudo.
        ``t`` ∈ [0, 1], di mana 0 → ``lo`` (terbaik) dan 1 → ``hi``
        (terburuk).
        """
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
        """Hitung faktor kualitas sinyal [0, 1] berdasarkan jarak.

        Mengembalikan ``(quality, available)``.  ``quality`` 1.0 berarti
        sinyal terbaik (sangat dekat); 0.0 berarti sinyal terlemah.
        ``available`` menjadi ``False`` jika jarak melebihi radius
        jangkauan node.
        """
        profile = node.resolved_profile()
        dx = user_x - node.x
        dy = user_y - node.y
        distance = math.sqrt(dx * dx + dy * dy)

        if distance < self.reference_distance_m:
            distance = self.reference_distance_m

        available = distance <= profile.coverage_radius_m

        # Faktor kualitas: 1.0 di jarak referensi, 0.0 di batas coverage
        ratio = distance / profile.coverage_radius_m
        quality = max(0.0, min(1.0, 1.0 - ratio))
        return quality, available

    def _compute_rss_from_distance(
        self,
        profile: TechnologyProfile,
        distance: float,
    ) -> float:
        """Hitung RSS menggunakan model log-distance path loss.

        RSS = RSS_max − 10·n·log10(d / d₀) + X_σ

        di mana X_σ adalah shadow fading Gaussian.
        """
        if distance < self.reference_distance_m:
            distance = self.reference_distance_m

        path_loss = 10.0 * self.path_loss_exponent * math.log10(
            distance / self.reference_distance_m
        )
        shadow = self.rng.gauss(0, self.shadow_fading_std)
        rss = profile.rss_max - path_loss + shadow

        # Clamp ke rentang profil
        return max(profile.rss_min, min(profile.rss_max, rss))

    # -- API publik -------------------------------------------------------

    def generate_snapshot(
        self,
        node: NetworkNode,
        *,
        user_x: float | None = None,
        user_y: float | None = None,
    ) -> NetworkSnapshot:
        """Bangkitkan satu ``NetworkSnapshot`` untuk ``node``.

        Jika ``user_x`` dan ``user_y`` diberikan, parameter dihitung
        berdasarkan jarak.  Jika tidak, parameter dibangkitkan acak dari
        rentang profil.
        """
        profile = node.resolved_profile()

        if user_x is not None and user_y is not None:
            quality, available = self._quality_factor_from_distance(
                node, user_x, user_y,
            )
            dx = user_x - node.x
            dy = user_y - node.y
            distance = math.sqrt(dx * dx + dy * dy)
            rss = self._compute_rss_from_distance(profile, distance)

            # Semakin tinggi quality → data rate tinggi, delay rendah, BER rendah
            noise = self.rng.gauss(0, 0.05)
            q = max(0.0, min(1.0, quality + noise))

            data_rate = self._lerp(profile.data_rate_min, profile.data_rate_max, q)
            delay = self._lerp(profile.delay_max, profile.delay_min, q)  # terbalik
            ber = self._lerp_log(profile.ber_min, profile.ber_max, 1.0 - q)
        else:
            # Mode acak murni
            rss = self.rng.uniform(profile.rss_min, profile.rss_max)
            data_rate = self.rng.uniform(profile.data_rate_min, profile.data_rate_max)
            delay = self.rng.uniform(profile.delay_min, profile.delay_max)
            ber = self._lerp_log(
                profile.ber_min, profile.ber_max, self.rng.random(),
            )
            available = True

        # Bulatkan agar output lebih mudah dibaca
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
# 4. Pembangun skenario multi-timestep
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
) -> list[ScenarioSnapshot]:
    """Bangkitkan deretan ``ScenarioSnapshot`` untuk simulasi.

    Pengguna bergerak lurus dengan kecepatan ``velocity_mps`` ke arah
    ``user_direction_deg`` (0° = sumbu-x positif).  Pada setiap
    langkah, profil jaringan dihitung berdasarkan posisi pengguna
    terhadap setiap node.

    Parameter:
        nodes: Daftar ``NetworkNode`` dalam skenario.
        num_steps: Jumlah langkah waktu.
        dt_s: Interval waktu antar langkah (detik).
        velocity_mps: Kecepatan gerak pengguna (m/s).
        traffic_class: Kelas trafik (``conversational``, ``streaming``,
            ``interactive``, ``background``).
        initial_network: ID jaringan awal yang terhubung.
            Jika ``None``, dipilih jaringan tersedia dengan RSS terbaik.
        user_start_x: Posisi awal pengguna (x, meter).
        user_start_y: Posisi awal pengguna (y, meter).
        user_direction_deg: Arah gerak pengguna (derajat).
        seed: Seed untuk reprodusibilitas.
        path_loss_exponent: Eksponen model path-loss (default 3.0).
        shadow_fading_std: Standar deviasi shadow fading (dB).

    Returns:
        Daftar ``ScenarioSnapshot``, satu per langkah waktu.

    Raises:
        ValueError: Jika parameter tidak valid.
    """
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

    user_x = user_start_x
    user_y = user_start_y
    current_network = initial_network

    snapshots: list[ScenarioSnapshot] = []

    for step in range(num_steps):
        timestamp = step * dt_s

        networks = generator.generate_all(user_x=user_x, user_y=user_y)

        # Pilih current_network jika belum ditetapkan atau sudah tidak tersedia
        available_ids = {n.id for n in networks if n.available}
        if current_network is None or current_network not in available_ids:
            if available_ids:
                # Pilih jaringan tersedia dengan RSS terbaik
                best = max(
                    (n for n in networks if n.available),
                    key=lambda n: n.rss_dbm,
                )
                current_network = best.id
            else:
                # Semua jaringan tidak terjangkau — paksa jaringan
                # pertama agar tersedia (edge case simulasi)
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
            velocity_mps=velocity_mps,
            traffic_class=traffic_class,
            networks=tuple(networks),
        )
        snapshots.append(snapshot)

        # Gerakkan pengguna
        user_x += vx * dt_s
        user_y += vy * dt_s

    return snapshots


# ---------------------------------------------------------------------------
# 5. Utilitas: buat skenario default cepat
# ---------------------------------------------------------------------------

def create_default_scenario(
    *,
    seed: int | None = 42,
    num_steps: int = 20,
    velocity_mps: float = 10.0,
    traffic_class: str = "streaming",
) -> list[ScenarioSnapshot]:
    """Bangkitkan skenario default dengan 3 jaringan (4G, 5G, WLAN).

    Jaringan ditempatkan di posisi berbeda, dan pengguna bergerak dari
    titik asal ke arah kanan.  Cocok untuk pengujian cepat.
    """
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
