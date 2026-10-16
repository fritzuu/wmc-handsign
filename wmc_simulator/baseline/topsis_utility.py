"""Algoritma Baseline: Single TOPSIS Utility Function.

Mengimplementasikan metode Technique for Order of Preference by Similarity to
Ideal Solution (TOPSIS) konvensional sebagai fungsi utilitas tunggal
(single-stage utility function) untuk perankingan kandidat jaringan heterogen
(4G, 5G, WLAN).

Dalam konteks penelitian ini, algoritma ini berperan sebagai baseline (pembanding)
terhadap algoritma primer (Fuzzy-TOPSIS). Berbeda dengan Fuzzy-TOPSIS yang
menggunakan Fuzzy Logic sebagai filter inisiasi sebelum evaluasi kandidat,
baseline Single TOPSIS Utility Function mengevaluasi dan meranking seluruh
kandidat jaringan secara langsung berdasarkan skor kedekatan relatif (relative closeness).
"""

from __future__ import annotations

import csv
import json
import math
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Sequence

from ..models import NetworkSnapshot, ScenarioSnapshot


class CriterionType(str, Enum):
    """Tipe kriteria keputusan."""
    BENEFIT = "benefit"  # Nilai lebih tinggi lebih baik (misal: Data Rate)
    COST = "cost"        # Nilai lebih rendah lebih baik (misal: Delay, BER)


# Bobot default per kelas aplikasi sesuai PRD v1.0/v2.0 (FR-07, FR-08)
# Kriteria standar: data_rate_mbps (benefit), delay_ms (cost), ber (cost)
DEFAULT_TOPSIS_WEIGHTS: dict[str, dict[str, float]] = {
    "conversational": {
        "data_rate_mbps": 0.20,
        "delay_ms": 0.50,
        "ber": 0.30,
    },
    "streaming": {
        "data_rate_mbps": 0.50,
        "delay_ms": 0.30,
        "ber": 0.20,
    },
    "interactive": {
        "data_rate_mbps": 0.40,
        "delay_ms": 0.35,
        "ber": 0.25,
    },
    "background": {
        "data_rate_mbps": 0.60,
        "delay_ms": 0.20,
        "ber": 0.20,
    },
}

# Arah default kriteria standar jaringan
DEFAULT_CRITERIA_DIRECTIONS: dict[str, CriterionType] = {
    "data_rate_mbps": CriterionType.BENEFIT,
    "delay_ms": CriterionType.COST,
    "ber": CriterionType.COST,
    "rss_dbm": CriterionType.BENEFIT,
}

# Bobot default untuk skenario 4 kriteria (Phase 5)
DEFAULT_4_CRITERIA_WEIGHTS: dict[str, float] = {
    "rss_dbm": 0.25,
    "data_rate_mbps": 0.35,
    "delay_ms": 0.25,
    "ber": 0.15,
}


@dataclass(frozen=True)
class TopsisAlternative:
    """Representasi satu alternatif yang dievaluasi oleh TOPSIS."""
    id: str
    criteria_values: dict[str, float]
    metadata: dict[str, object] = field(default_factory=dict)

    @classmethod
    def from_network_snapshot(cls, net: NetworkSnapshot) -> "TopsisAlternative":
        return cls(
            id=net.id,
            criteria_values={
                "data_rate_mbps": float(net.data_rate_mbps),
                "delay_ms": float(net.delay_ms),
                "ber": float(net.ber),
                "rss_dbm": float(net.rss_dbm),
            },
            metadata={
                "technology": net.technology,
                "available": net.available,
                "rss_dbm": net.rss_dbm,
            },
        )

    @classmethod
    def from_profile_record(cls, rec: object) -> "TopsisAlternative":
        """Membangun alternatif dari NetworkProfileRecord sintetis."""
        return cls(
            id=getattr(rec, "network_id"),
            criteria_values={
                "rss_dbm": float(getattr(rec, "rss_dbm")),
                "data_rate_mbps": float(getattr(rec, "data_rate_mbps")),
                "delay_ms": float(getattr(rec, "delay_ms")),
                "ber": float(getattr(rec, "ber")),
            },
            metadata={
                "scenario_id": getattr(rec, "scenario_id", ""),
                "time_step": getattr(rec, "time_step", 0),
                "network_type": getattr(rec, "network_type", ""),
                "network_load": getattr(rec, "network_load", 0.0),
                "channel_condition": getattr(rec, "channel_condition", ""),
            },
        )


@dataclass(frozen=True)
class TopsisEvaluationResult:
    """Hasil evaluasi per alternatif."""
    alternative_id: str
    utility_score: float  # Relative closeness Ci in [0.0, 1.0]
    rank: int             # 1-indexed (1 = peringkat terbaik)
    d_plus: float         # Jarak Euclidean ke Solusi Ideal Positif (A+)
    d_minus: float        # Jarak Euclidean ke Solusi Ideal Negatif (A-)
    metadata: dict[str, object] = field(default_factory=dict)

    def to_dict(self) -> dict:
        return {
            "alternative_id": self.alternative_id,
            "utility_score": round(self.utility_score, 6),
            "rank": self.rank,
            "d_plus": round(self.d_plus, 6),
            "d_minus": round(self.d_minus, 6),
            "metadata": dict(self.metadata),
        }


@dataclass(frozen=True)
class TopsisRankingRecord:
    """Rekaman hasil perankingan alternatif untuk satu timestep dan skenario."""
    scenario_id: str
    time_step: int
    network_id: str
    network_type: str
    utility_score: float
    rank: int
    rss_dbm: float
    data_rate_mbps: float
    delay_ms: float
    ber: float
    d_plus: float
    d_minus: float

    def to_dict(self) -> dict:
        return {
            "scenario_id": self.scenario_id,
            "time_step": self.time_step,
            "network_id": self.network_id,
            "network_type": self.network_type,
            "utility_score": round(self.utility_score, 6),
            "rank": self.rank,
            "rss_dbm": round(self.rss_dbm, 3),
            "data_rate_mbps": round(self.data_rate_mbps, 3),
            "delay_ms": round(self.delay_ms, 3),
            "ber": float(f"{self.ber:.6e}"),
            "d_plus": round(self.d_plus, 6),
            "d_minus": round(self.d_minus, 6),
        }


@dataclass(frozen=True)
class TopsisStepDetail:
    """Rincian perhitungan langkah intermediate TOPSIS untuk audit numerik."""
    criteria_names: list[str]
    weights: dict[str, float]
    criteria_types: dict[str, str]
    normalized_matrix: dict[str, dict[str, float]]
    weighted_matrix: dict[str, dict[str, float]]
    ideal_positive: dict[str, float]
    ideal_negative: dict[str, float]


@dataclass(frozen=True)
class SingleTopsisResult:
    """Keluaran lengkap eksekusi Single TOPSIS Utility Function."""
    rankings: list[TopsisEvaluationResult]
    best_alternative_id: str | None
    best_utility_score: float | None
    details: TopsisStepDetail

    def to_dict(self) -> dict:
        return {
            "best_alternative_id": self.best_alternative_id,
            "best_utility_score": round(self.best_utility_score, 6) if self.best_utility_score is not None else None,
            "rankings": [r.to_dict() for r in self.rankings],
        }


class SingleTopsisUtilityFunction:
    """Implementasi konvensional Single TOPSIS Utility Function.

    Tahapan Prosedur:
    1. Membentuk matriks keputusan X = [x_ij].
    2. Normalisasi vektor: r_ij = x_ij / sqrt(sum_k x_kj^2).
    3. Pembobotan matriks: v_ij = w_j * r_ij.
    4. Menentukan solusi ideal positif (A+) dan negatif (A-):
       - Benefit: v_j+ = max(v_ij), v_j- = min(v_ij)
       - Cost:    v_j+ = min(v_ij), v_j- = max(v_ij)
    5. Menghitung jarak separasi Euclidean:
       - D_i+ = sqrt(sum_j (v_ij - v_j+)^2)
       - D_i- = sqrt(sum_j (v_ij - v_j-)^2)
    6. Menghitung skor kedekatan relatif (Utility Score C_i):
       - C_i = D_i- / (D_i+ + D_i-)
    7. Perankingan menurun berdasarkan C_i.
    """

    def __init__(
        self,
        criteria_types: dict[str, CriterionType] | None = None,
        default_weights: dict[str, float] | None = None,
    ) -> None:
        self.criteria_types = dict(criteria_types or DEFAULT_CRITERIA_DIRECTIONS)
        self.default_weights = dict(default_weights) if default_weights else None

    def evaluate(
        self,
        alternatives: Sequence[TopsisAlternative],
        weights: dict[str, float] | None = None,
        criteria_names: Sequence[str] | None = None,
    ) -> SingleTopsisResult:
        """Evaluasi dan perankingan kumpulan alternatif menggunakan TOPSIS.

        Args:
            alternatives: Daftar alternatif yang akan dievaluasi.
            weights: Bobot untuk setiap kriteria. Jika None, gunakan default atau bobot setara.
            criteria_names: Kriteria yang disertakan. Jika None, kriteria diambil dari bobot atau intersection.

        Returns:
            SingleTopsisResult berisi ranking, skor utilitas, dan audit intermediate.
        """
        if not alternatives:
            raise ValueError("Daftar alternatif tidak boleh kosong.")

        # Tentukan kriteria yang digunakan
        if criteria_names is not None:
            active_criteria = list(criteria_names)
        elif weights is not None:
            active_criteria = list(weights.keys())
        elif self.default_weights is not None:
            active_criteria = list(self.default_weights.keys())
        else:
            # Gunakan 3 kriteria standar PRD jika tersedia
            standard_subset = ["data_rate_mbps", "delay_ms", "ber"]
            first_vals = alternatives[0].criteria_values
            if all(c in first_vals for c in standard_subset):
                active_criteria = standard_subset
            else:
                active_criteria = sorted(first_vals.keys())

        if not active_criteria:
            raise ValueError("Tidak ada kriteria evaluasi yang ditentukan.")

        # Validasi dan normalisasi bobot
        norm_weights = self._resolve_and_normalize_weights(active_criteria, weights)

        # Validasi tipe kriteria
        for c in active_criteria:
            if c not in self.criteria_types:
                raise ValueError(
                    f"Arah kriteria '{c}' tidak didefinisikan. "
                    f"Tentukan apakah BENEFIT atau COST."
                )

        # Kasus khusus: Hanya 1 alternatif
        if len(alternatives) == 1:
            alt = alternatives[0]
            dummy_eval = TopsisEvaluationResult(
                alternative_id=alt.id,
                utility_score=1.0,
                rank=1,
                d_plus=0.0,
                d_minus=0.0,
                metadata=alt.metadata,
            )
            detail = TopsisStepDetail(
                criteria_names=active_criteria,
                weights=norm_weights,
                criteria_types={c: self.criteria_types[c].value for c in active_criteria},
                normalized_matrix={alt.id: {c: 1.0 for c in active_criteria}},
                weighted_matrix={alt.id: {c: norm_weights[c] for c in active_criteria}},
                ideal_positive={c: norm_weights[c] for c in active_criteria},
                ideal_negative={c: norm_weights[c] for c in active_criteria},
            )
            return SingleTopsisResult(
                rankings=[dummy_eval],
                best_alternative_id=alt.id,
                best_utility_score=1.0,
                details=detail,
            )

        # 1. Bangun matriks keputusan & normalisasi vektor
        # r_ij = x_ij / sqrt(sum_k (x_kj)^2)
        norm_matrix: dict[str, dict[str, float]] = {alt.id: {} for alt in alternatives}
        for c in active_criteria:
            col_vals = []
            for alt in alternatives:
                val = alt.criteria_values.get(c)
                if val is None or not math.isfinite(val):
                    raise ValueError(f"Nilai kriteria '{c}' pada alternatif '{alt.id}' tidak valid: {val}")
                col_vals.append(float(val))

            sum_sq = sum(v * v for v in col_vals)
            denom = math.sqrt(sum_sq)

            for alt, val in zip(alternatives, col_vals):
                if denom > 1e-12:
                    norm_matrix[alt.id][c] = val / denom
                else:
                    # Seluruh kolom bernilai 0
                    norm_matrix[alt.id][c] = 0.0

        # 2. Matriks ternormalisasi terbobot (v_ij = w_j * r_ij)
        weighted_matrix: dict[str, dict[str, float]] = {alt.id: {} for alt in alternatives}
        for alt in alternatives:
            for c in active_criteria:
                weighted_matrix[alt.id][c] = norm_matrix[alt.id][c] * norm_weights[c]

        # 3. Tentukan Solusi Ideal Positif (A+) dan Negatif (A-)
        ideal_pos: dict[str, float] = {}
        ideal_neg: dict[str, float] = {}
        for c in active_criteria:
            col_weighted = [weighted_matrix[alt.id][c] for alt in alternatives]
            ctype = self.criteria_types[c]
            if ctype == CriterionType.BENEFIT:
                ideal_pos[c] = max(col_weighted)
                ideal_neg[c] = min(col_weighted)
            else:  # COST
                ideal_pos[c] = min(col_weighted)
                ideal_neg[c] = max(col_weighted)

        # 4. Hitung Jarak Separasi Euclidean (D+ dan D-)
        d_plus_map: dict[str, float] = {}
        d_minus_map: dict[str, float] = {}
        for alt in alternatives:
            diff_sq_pos = sum((weighted_matrix[alt.id][c] - ideal_pos[c]) ** 2 for c in active_criteria)
            diff_sq_neg = sum((weighted_matrix[alt.id][c] - ideal_neg[c]) ** 2 for c in active_criteria)
            d_plus_map[alt.id] = math.sqrt(diff_sq_pos)
            d_minus_map[alt.id] = math.sqrt(diff_sq_neg)

        # 5. Hitung Skor Utilitas Kedekatan Relatif (Ci)
        utility_scores: dict[str, float] = {}
        for alt in alternatives:
            d_p = d_plus_map[alt.id]
            d_m = d_minus_map[alt.id]
            denom = d_p + d_m
            if denom > 1e-12:
                ci = d_m / denom
            else:
                # Kasus tepi numerik: semua alternatif identik pada kriteria
                ci = 0.5
            utility_scores[alt.id] = ci

        # 6. Urutkan alternatif secara descending berdasarkan Ci
        # Tie-breaker stabil: jika Ci sama, urutkan berdasarkan index kedatangan/id
        sorted_alts = sorted(
            alternatives,
            key=lambda a: (-utility_scores[a.id], a.id),
        )

        rankings: list[TopsisEvaluationResult] = []
        for rank_idx, alt in enumerate(sorted_alts, start=1):
            rankings.append(
                TopsisEvaluationResult(
                    alternative_id=alt.id,
                    utility_score=utility_scores[alt.id],
                    rank=rank_idx,
                    d_plus=d_plus_map[alt.id],
                    d_minus=d_minus_map[alt.id],
                    metadata=alt.metadata,
                )
            )

        best_id = rankings[0].alternative_id if rankings else None
        best_score = rankings[0].utility_score if rankings else None

        detail = TopsisStepDetail(
            criteria_names=active_criteria,
            weights=norm_weights,
            criteria_types={c: self.criteria_types[c].value for c in active_criteria},
            normalized_matrix=norm_matrix,
            weighted_matrix=weighted_matrix,
            ideal_positive=ideal_pos,
            ideal_negative=ideal_neg,
        )

        return SingleTopsisResult(
            rankings=rankings,
            best_alternative_id=best_id,
            best_utility_score=best_score,
            details=detail,
        )

    def evaluate_snapshot(
        self,
        snapshot: ScenarioSnapshot,
        include_current_network: bool = True,
        criteria_names: Sequence[str] | None = None,
        custom_weights: dict[str, float] | None = None,
    ) -> SingleTopsisResult:
        """Evaluasi kandidat jaringan dari ScenarioSnapshot simulator.

        Args:
            snapshot: Snapshot skenario yang memuat daftar jaringan.
            include_current_network: Apakah menyertakan jaringan aktif saat ini dalam perankingan.
            criteria_names: Kriteria seleksi. Default: ['data_rate_mbps', 'delay_ms', 'ber'].
            custom_weights: Bobot kustom. Jika None, diambil dari profil kelas trafik snapshot.
        """
        # Saring jaringan yang tersedia (available == True)
        available_nets = [n for n in snapshot.networks if n.available]
        if not include_current_network:
            available_nets = [n for n in available_nets if n.id != snapshot.current_network]

        if not available_nets:
            raise ValueError(f"Tidak ada jaringan kandidat yang tersedia pada snapshot t={snapshot.timestamp_s}s.")

        # Ambil bobot berdasarkan traffic_class jika tidak diberikan custom_weights
        weights = custom_weights
        if weights is None:
            weights = DEFAULT_TOPSIS_WEIGHTS.get(snapshot.traffic_class)
            if weights is None:
                # Fallback jika traffic_class tidak dikenal
                weights = {"data_rate_mbps": 1/3, "delay_ms": 1/3, "ber": 1/3}

        alternatives = [TopsisAlternative.from_network_snapshot(n) for n in available_nets]
        return self.evaluate(alternatives, weights=weights, criteria_names=criteria_names)

    def decide_handover(
        self,
        snapshot: ScenarioSnapshot,
        hysteresis_margin: float = 0.0,
        criteria_names: Sequence[str] | None = None,
    ) -> dict:
        """Menghasilkan keputusan rekomendasi handover berdasarkan Single TOPSIS Utility.

        Pada baseline Single TOPSIS:
        - Utilitas seluruh jaringan yang tersedia dievaluasi langsung pada snapshot.
        - Jika jaringan terbaik berbeda dengan current_network dan selisih skor
          utilitas (C_best - C_current) > hysteresis_margin, maka direkomendasikan handover.
        """
        res = self.evaluate_snapshot(
            snapshot,
            include_current_network=True,
            criteria_names=criteria_names,
        )

        current_id = snapshot.current_network
        best_id = res.best_alternative_id
        best_score = res.best_utility_score

        current_res = next((r for r in res.rankings if r.alternative_id == current_id), None)
        current_score = current_res.utility_score if current_res else 0.0

        should_handover = False
        target_network = current_id
        reason = "Tetap di jaringan saat ini (memiliki utilitas terbaik)"

        if best_id != current_id:
            margin = (best_score or 0.0) - current_score
            if margin > hysteresis_margin:
                should_handover = True
                target_network = best_id
                reason = (
                    f"Rekomendasi handover ke {target_network}: skor utilitas "
                    f"({best_score:.4f}) lebih tinggi dari jaringan aktif ({current_score:.4f})"
                )
            else:
                reason = (
                    f"Kandidat {best_id} sedikit lebih baik tetapi di bawah margin histeresis "
                    f"({margin:.4f} <= {hysteresis_margin:.4f})"
                )

        return {
            "timestamp_s": snapshot.timestamp_s,
            "current_network": current_id,
            "target_network": target_network,
            "handover_recommended": should_handover,
            "best_alternative": best_id,
            "best_utility_score": best_score,
            "current_utility_score": current_score,
            "reason": reason,
            "rankings": [r.to_dict() for r in res.rankings],
        }

    def _resolve_and_normalize_weights(
        self,
        criteria: Sequence[str],
        weights: dict[str, float] | None,
    ) -> dict[str, float]:
        """Validasi dan normalisasi bobot agar jumlahnya persis = 1.0."""
        target_weights: dict[str, float] = {}

        if weights is not None:
            for c in criteria:
                if c not in weights:
                    raise ValueError(f"Bobot untuk kriteria '{c}' tidak disediakan.")
                w = float(weights[c])
                if not math.isfinite(w) or w < 0:
                    raise ValueError(f"Bobot untuk kriteria '{c}' harus bernilai non-negatif dan finite: {w}")
                target_weights[c] = w
        elif self.default_weights is not None:
            for c in criteria:
                w = self.default_weights.get(c, 1.0 / len(criteria))
                target_weights[c] = float(w)
        else:
            # Bobot setara (equal weights)
            eq_w = 1.0 / len(criteria)
            for c in criteria:
                target_weights[c] = eq_w

        total_w = sum(target_weights.values())
        if total_w <= 1e-12:
            raise ValueError("Total bobot kriteria tidak boleh bernilai nol.")

        # Normalisasi ke sum = 1.0
        return {c: target_weights[c] / total_w for c in criteria}

    def rank_scenario_group(
        self,
        records: Sequence[object],
        weights: dict[str, float] | None = None,
        criteria_names: Sequence[str] | None = None,
    ) -> list[TopsisRankingRecord]:
        """Merangking sekelompok alternatif dalam satu scenario_id dan time_step."""
        if not records:
            return []

        active_weights = weights or (DEFAULT_4_CRITERIA_WEIGHTS if criteria_names is None else None)
        alts = [TopsisAlternative.from_profile_record(r) for r in records]
        res = self.evaluate(alts, weights=active_weights, criteria_names=criteria_names)

        eval_map = {ev.alternative_id: ev for ev in res.rankings}
        out: list[TopsisRankingRecord] = []

        for r in records:
            nid = getattr(r, "network_id")
            ev = eval_map.get(nid)
            if ev is not None:
                out.append(
                    TopsisRankingRecord(
                        scenario_id=getattr(r, "scenario_id"),
                        time_step=int(getattr(r, "time_step")),
                        network_id=nid,
                        network_type=getattr(r, "network_type"),
                        utility_score=ev.utility_score,
                        rank=ev.rank,
                        rss_dbm=float(getattr(r, "rss_dbm")),
                        data_rate_mbps=float(getattr(r, "data_rate_mbps")),
                        delay_ms=float(getattr(r, "delay_ms")),
                        ber=float(getattr(r, "ber")),
                        d_plus=ev.d_plus,
                        d_minus=ev.d_minus,
                    )
                )

        # Urutkan berdasarkan rank
        out.sort(key=lambda x: x.rank)
        return out

    def rank_dataset(
        self,
        records: Sequence[object],
        weights: dict[str, float] | None = None,
        criteria_names: Sequence[str] | None = None,
    ) -> list[TopsisRankingRecord]:
        """Mengelompokkan rekaman per (scenario_id, time_step) lalu merangking setiap grup secara terisolasi.

        Menjamin bahwa alternatif dari skenario atau waktu yang berbeda TIDAK pernah dirangking bersamaan.
        """
        groups: dict[tuple[str, int], list[object]] = {}
        for r in records:
            key = (getattr(r, "scenario_id"), int(getattr(r, "time_step")))
            groups.setdefault(key, []).append(r)

        all_rankings: list[TopsisRankingRecord] = []
        for key in sorted(groups.keys()):
            group_records = groups[key]
            group_rankings = self.rank_scenario_group(group_records, weights=weights, criteria_names=criteria_names)
            all_rankings.extend(group_rankings)

        return all_rankings

    @staticmethod
    def export_rankings_csv(rankings: Sequence[TopsisRankingRecord], filepath: str | Path) -> Path:
        """Ekspor hasil perankingan TOPSIS ke format CSV."""
        out_path = Path(filepath)
        out_path.parent.mkdir(parents=True, exist_ok=True)

        if not rankings:
            raise ValueError("Tidak ada perankingan untuk diekspor ke CSV.")

        fieldnames = list(rankings[0].to_dict().keys())
        with out_path.open("w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            for r in rankings:
                writer.writerow(r.to_dict())

        return out_path

    @staticmethod
    def export_rankings_json(rankings: Sequence[TopsisRankingRecord], filepath: str | Path) -> Path:
        """Ekspor hasil perankingan TOPSIS ke format JSON."""
        out_path = Path(filepath)
        out_path.parent.mkdir(parents=True, exist_ok=True)

        data = [r.to_dict() for r in rankings]
        with out_path.open("w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

        return out_path
