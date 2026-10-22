"""Implementasi Random Waypoint Model (RWP) untuk modul mobilitas pengguna.

Sesuai rancangan Pekan 4 simulator WMC:
Menghasilkan posisi (x, y) dan kecepatan pengguna pada setiap langkah waktu (timestep)
berdasarkan model Random Waypoint standar.
"""

from __future__ import annotations

import math
import random
from dataclasses import dataclass
from enum import Enum
from typing import Sequence


class MobilityMovementStatus(str, Enum):
    """Status pergerakan pengguna."""
    MOVING = "moving"
    PAUSED = "paused"


@dataclass(frozen=True)
class MobilityPoint:
    """Titik koordinat 2 dimensi dalam meter."""
    x: float
    y: float

    def distance_to(self, other: MobilityPoint) -> float:
        """Menghitung jarak Euclidean ke titik lain."""
        dx = other.x - self.x
        dy = other.y - self.y
        return math.sqrt(dx * dx + dy * dy)

    def to_dict(self) -> dict[str, float]:
        return {"x": round(self.x, 3), "y": round(self.y, 3)}


@dataclass(frozen=True)
class RandomWaypointConfig:
    """Konfigurasi parameter Random Waypoint Model."""
    area_width: float = 500.0
    area_height: float = 500.0
    initial_position: MobilityPoint | None = None
    min_speed: float = 1.0
    max_speed: float = 5.0
    min_pause_time: float = 0.0
    max_pause_time: float = 3.0
    update_interval: float = 1.0
    seed: int | None = None

    def __post_init__(self) -> None:
        if self.area_width <= 0:
            raise ValueError("area_width harus > 0.")
        if self.area_height <= 0:
            raise ValueError("area_height harus > 0.")
        if self.min_speed < 0:
            raise ValueError("min_speed tidak boleh negatif.")
        if self.max_speed < self.min_speed:
            raise ValueError("max_speed harus >= min_speed.")
        if self.min_pause_time < 0:
            raise ValueError("min_pause_time tidak boleh negatif.")
        if self.max_pause_time < self.min_pause_time:
            raise ValueError("max_pause_time harus >= min_pause_time.")
        if self.update_interval <= 0:
            raise ValueError("update_interval harus > 0.")

    def contains(self, point: MobilityPoint) -> bool:
        """Cek apakah titik berada di dalam area simulasi."""
        return 0.0 <= point.x <= self.area_width and 0.0 <= point.y <= self.area_height


@dataclass(frozen=True)
class MobilityState:
    """Snapshot kondisi mobilitas pada satu waktu."""
    elapsed_seconds: float
    position: MobilityPoint
    current_waypoint: MobilityPoint
    current_speed: float
    cruising_speed: float
    status: MobilityMovementStatus
    remaining_pause_time: float = 0.0

    @property
    def is_moving(self) -> bool:
        return self.status == MobilityMovementStatus.MOVING

    @property
    def is_paused(self) -> bool:
        return self.status == MobilityMovementStatus.PAUSED

    def to_dict(self) -> dict:
        return {
            "timestamp": round(self.elapsed_seconds, 3),
            "x": round(self.position.x, 3),
            "y": round(self.position.y, 3),
            "speed": round(self.current_speed, 3),
            "cruising_speed": round(self.cruising_speed, 3),
            "waypoint": self.current_waypoint.to_dict(),
            "state": self.status.value,
            "remaining_pause_time": round(self.remaining_pause_time, 3),
        }


class RandomWaypointModel:
    """Generator mobilitas Random Waypoint (RWP)."""

    def __init__(self, config: RandomWaypointConfig | None = None) -> None:
        self.config = config or RandomWaypointConfig()
        self.reset()

    def reset(self, custom_seed: int | None = None) -> None:
        """Reset simulasi ke kondisi awal."""
        effective_seed = custom_seed if custom_seed is not None else self.config.seed
        self._rng = random.Random(effective_seed)
        self._elapsed_seconds = 0.0

        if self.config.initial_position is not None:
            self._current_position = self._clamp_point(self.config.initial_position)
        else:
            self._current_position = MobilityPoint(
                self.config.area_width / 2.0,
                self.config.area_height / 2.0,
            )

        self._remaining_pause_time = 0.0
        self._status = MobilityMovementStatus.MOVING

        self._current_waypoint = self._generate_random_waypoint()
        self._cruising_speed = self._generate_random_speed()
        self._current_speed = self._cruising_speed

    def _generate_random_waypoint(self) -> MobilityPoint:
        x = self._rng.uniform(0.0, self.config.area_width)
        y = self._rng.uniform(0.0, self.config.area_height)
        return MobilityPoint(x, y)

    def _generate_random_speed(self) -> float:
        if self.config.max_speed == self.config.min_speed:
            return self.config.min_speed
        return self._rng.uniform(self.config.min_speed, self.config.max_speed)

    def _generate_random_pause_time(self) -> float:
        if self.config.max_pause_time == self.config.min_pause_time:
            return self.config.min_pause_time
        return self._rng.uniform(self.config.min_pause_time, self.config.max_pause_time)

    def _clamp_point(self, point: MobilityPoint) -> MobilityPoint:
        cx = max(0.0, min(self.config.area_width, point.x))
        cy = max(0.0, min(self.config.area_height, point.y))
        return MobilityPoint(cx, cy)

    @property
    def current_state(self) -> MobilityState:
        return MobilityState(
            elapsed_seconds=self._elapsed_seconds,
            position=self._current_position,
            current_waypoint=self._current_waypoint,
            current_speed=self._current_speed,
            cruising_speed=self._cruising_speed,
            status=self._status,
            remaining_pause_time=self._remaining_pause_time,
        )

    def step(self, dt: float | None = None) -> MobilityState:
        """Melakukan satu langkah pembaruan waktu dt (detik)."""
        delta_time = dt if dt is not None else self.config.update_interval
        if delta_time <= 0:
            raise ValueError("dt harus > 0.")

        self._elapsed_seconds += delta_time

        # Status: PAUSED
        if self._status == MobilityMovementStatus.PAUSED:
            self._remaining_pause_time -= delta_time
            self._current_speed = 0.0

            if self._remaining_pause_time <= 0.0:
                self._remaining_pause_time = 0.0
                self._status = MobilityMovementStatus.MOVING
                self._current_waypoint = self._generate_random_waypoint()
                self._cruising_speed = self._generate_random_speed()
                self._current_speed = self._cruising_speed

            return self.current_state

        # Status: MOVING
        dist = self._current_position.distance_to(self._current_waypoint)
        step_dist = self._cruising_speed * delta_time

        if step_dist >= dist or dist < 1e-6:
            # Waypoint tercapai
            self._current_position = self._current_waypoint
            pause_dur = self._generate_random_pause_time()

            if pause_dur > 0.0:
                self._status = MobilityMovementStatus.PAUSED
                self._remaining_pause_time = pause_dur
                self._current_speed = 0.0
            else:
                self._current_waypoint = self._generate_random_waypoint()
                self._cruising_speed = self._generate_random_speed()
                self._current_speed = self._cruising_speed
        else:
            ratio = step_dist / dist
            nx = self._current_position.x + (self._current_waypoint.x - self._current_position.x) * ratio
            ny = self._current_position.y + (self._current_waypoint.y - self._current_position.y) * ratio
            self._current_position = self._clamp_point(MobilityPoint(nx, ny))
            self._current_speed = self._cruising_speed

        return self.current_state

    def generate_path(self, steps: int, dt: float | None = None) -> list[MobilityState]:
        """Menghasilkan deretan state mobilitas untuk sejumlah langkah."""
        if steps <= 0:
            raise ValueError("steps harus > 0.")
        path = [self.current_state]
        for _ in range(steps):
            path.append(self.step(dt))
        return path
