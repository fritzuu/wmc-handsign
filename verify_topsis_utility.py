"""Verifikasi kesetaraan dan validasi numerik Baseline Single TOPSIS Utility Function.

Dijalankan dengan: python -X utf8 verify_topsis_utility.py
"""

from __future__ import annotations

import math
from wmc_simulator.baseline import (
    CriterionType,
    DEFAULT_TOPSIS_WEIGHTS,
    SingleTopsisUtilityFunction,
    TopsisAlternative,
)

_passed = 0
_failed = 0
_total = 0


def _assert(condition: bool, message: str) -> None:
    global _passed, _failed, _total
    _total += 1
    if condition:
        _passed += 1
        print(f"  [PASS] {message}")
    else:
        _failed += 1
        print(f"  [FAIL] {message}")


def _header(title: str) -> None:
    print(f"\n======================================================================")
    print(f" {title}")
    print(f"======================================================================")


def test_topsis_reference_verification():
    _header("TEST 1: Verifikasi Numerik Langkah-demi-Langkah (Manual Baseline Example)")
    topsis = SingleTopsisUtilityFunction()
    alts = [
        TopsisAlternative("A1", {"data_rate_mbps": 30.0, "delay_ms": 40.0, "ber": 0.001}),
        TopsisAlternative("A2", {"data_rate_mbps": 100.0, "delay_ms": 10.0, "ber": 0.00001}),
        TopsisAlternative("A3", {"data_rate_mbps": 50.0, "delay_ms": 25.0, "ber": 0.0001}),
    ]
    w = {"data_rate_mbps": 0.5, "delay_ms": 0.3, "ber": 0.2}
    res = topsis.evaluate(alts, weights=w)
    d = res.details

    # 1. Normalisasi
    denom_dr = math.sqrt(30**2 + 100**2 + 50**2)
    _assert(abs(d.normalized_matrix["A1"]["data_rate_mbps"] - (30 / denom_dr)) < 1e-5, "Normalisasi vektor Data Rate A1 cocok")
    _assert(abs(d.normalized_matrix["A2"]["data_rate_mbps"] - (100 / denom_dr)) < 1e-5, "Normalisasi vektor Data Rate A2 cocok")

    # 2. Solusi Ideal
    _assert(d.ideal_positive["data_rate_mbps"] == d.weighted_matrix["A2"]["data_rate_mbps"], "Ideal Positif Data Rate diambil dari A2")
    _assert(d.ideal_positive["delay_ms"] == d.weighted_matrix["A2"]["delay_ms"], "Ideal Positif Delay (min) diambil dari A2")

    # 3. Skor Relatif
    r_a2 = next(r for r in res.rankings if r.alternative_id == "A2")
    r_a1 = next(r for r in res.rankings if r.alternative_id == "A1")
    r_a3 = next(r for r in res.rankings if r.alternative_id == "A3")

    _assert(abs(r_a2.utility_score - 1.0) < 1e-5, "Skor A2 (ideal pada semua kriteria) = 1.000")
    _assert(abs(r_a1.utility_score - 0.0) < 1e-5, "Skor A1 (terburuk pada semua kriteria) = 0.000")
    _assert(0.40 < r_a3.utility_score < 0.60, f"Skor A3 berada di tengah ({r_a3.utility_score:.4f})")
    _assert(res.best_alternative_id == "A2", "Pemenang alternatif terbaik = A2")


def test_mixed_benefit_cost():
    _header("TEST 2: Verifikasi Arah Kriteria Campuran (Benefit vs Cost)")
    topsis = SingleTopsisUtilityFunction()
    alts = [
        TopsisAlternative("high_rate_high_delay", {"data_rate_mbps": 100.0, "delay_ms": 100.0}),
        TopsisAlternative("low_rate_low_delay", {"data_rate_mbps": 10.0, "delay_ms": 10.0}),
    ]
    res_dr = topsis.evaluate(alts, weights={"data_rate_mbps": 0.9, "delay_ms": 0.1})
    _assert(res_dr.best_alternative_id == "high_rate_high_delay", "Bobot Data Rate tinggi memilih rate tertinggi")

    res_dl = topsis.evaluate(alts, weights={"data_rate_mbps": 0.1, "delay_ms": 0.9})
    _assert(res_dl.best_alternative_id == "low_rate_low_delay", "Bobot Delay tinggi memilih delay terendah")


def test_edge_cases():
    _header("TEST 3: Verifikasi Kasus Tepi Numerik & Pembagi Nol")
    topsis = SingleTopsisUtilityFunction()

    # 1 Alternatif
    one = [TopsisAlternative("Solo", {"data_rate_mbps": 50.0, "delay_ms": 20.0, "ber": 0.001})]
    res_one = topsis.evaluate(one)
    _assert(res_one.rankings[0].utility_score == 1.0, "1 Alternatif menghasilkan skor utilitas 1.0")

    # Identik
    same = [
        TopsisAlternative("S1", {"data_rate_mbps": 50.0, "delay_ms": 20.0, "ber": 0.001}),
        TopsisAlternative("S2", {"data_rate_mbps": 50.0, "delay_ms": 20.0, "ber": 0.001}),
    ]
    res_same = topsis.evaluate(same)
    _assert(res_same.rankings[0].utility_score == 0.5 and res_same.rankings[1].utility_score == 0.5, "Alternatif identik terbagi rata Ci=0.5 tanpa NaN")

    # Kolom 0
    zero_col = [
        TopsisAlternative("Z1", {"data_rate_mbps": 50.0, "delay_ms": 20.0, "ber": 0.0}),
        TopsisAlternative("Z2", {"data_rate_mbps": 80.0, "delay_ms": 20.0, "ber": 0.0}),
    ]
    res_zero = topsis.evaluate(zero_col)
    _assert(math.isfinite(res_zero.rankings[0].utility_score), "Kolom bernilai 0 tidak menyebabkan error pembagian")


def main():
    print("=" * 70)
    print(" VERIFIKASI — Baseline Algorithm: Single TOPSIS Utility Function")
    print(" Proyek: WMC Vertical Handover Decision System")
    print("=" * 70)

    test_topsis_reference_verification()
    test_mixed_benefit_cost()
    test_edge_cases()

    print("\n" + "=" * 70)
    if _failed == 0:
        print(f" [OK] SEMUA {_total} TEST VERIFIKASI LULUS!")
    else:
        print(f" [FAIL] {_failed} dari {_total} test GAGAL!")
    print(f" Passed: {_passed} | Failed: {_failed} | Total: {_total}")
    print("=" * 70)


if __name__ == "__main__":
    main()
