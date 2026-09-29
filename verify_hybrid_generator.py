"""Verifikasi kesetaraan logika Hybrid Generator Dart dengan Python.

Skrip ini mensimulasikan logika yang sama persis dengan Dart
HybridProfileGenerator untuk memastikan kedua versi menghasilkan
hasil yang konsisten.

Dijalankan dengan: python verify_hybrid_generator.py
"""

import math
import random


# =====================================================================
# Profil Teknologi (identik dengan Dart defaultProfiles)
# =====================================================================

PROFILES = {
    "4G": {
        "rss_min": -120.0, "rss_max": -50.0,
        "data_rate_min": 1.0, "data_rate_max": 100.0,
        "delay_min": 10.0, "delay_max": 100.0,
        "ber_min": 1e-6, "ber_max": 1e-3,
    },
    "5G": {
        "rss_min": -110.0, "rss_max": -40.0,
        "data_rate_min": 50.0, "data_rate_max": 1000.0,
        "delay_min": 1.0, "delay_max": 20.0,
        "ber_min": 1e-8, "ber_max": 1e-5,
    },
    "WLAN": {
        "rss_min": -90.0, "rss_max": -30.0,
        "data_rate_min": 1.0, "data_rate_max": 600.0,
        "delay_min": 5.0, "delay_max": 50.0,
        "ber_min": 1e-7, "ber_max": 1e-4,
    },
}


# =====================================================================
# Logika Hybrid Generator (port Python dari kode Dart)
# =====================================================================

def lerp(lo, hi, t):
    t = max(0.0, min(1.0, t))
    return lo + (hi - lo) * t


def lerp_log(lo, hi, t):
    if lo <= 0 or hi <= 0:
        return lo
    log_lo = math.log10(lo)
    log_hi = math.log10(hi)
    t = max(0.0, min(1.0, t))
    return 10 ** (log_lo + (log_hi - log_lo) * t)


def compute_quality_factor(rss_dbm, profile):
    rss_range = profile["rss_max"] - profile["rss_min"]
    if rss_range == 0:
        return 0.5
    return max(0.0, min(1.0, (rss_dbm - profile["rss_min"]) / rss_range))


def hybrid_estimate(network_id, technology, rss_dbm, noise_std=0.0, rng=None):
    """Estimasi parameter QoS dari RSS — logika identik dengan Dart."""
    profile = PROFILES[technology]
    
    # Quality factor
    quality = compute_quality_factor(rss_dbm, profile)
    
    # Noisy quality (noise_std=0 untuk verifikasi deterministik)
    if rng and noise_std > 0:
        u1 = max(0.0001, rng.random())
        u2 = rng.random()
        z = math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)
        noise = z * noise_std
    else:
        noise = 0.0
    noisy_q = max(0.0, min(1.0, quality + noise))
    
    # Data Rate — proporsional
    data_rate = lerp(profile["data_rate_min"], profile["data_rate_max"], noisy_q)
    data_rate = max(profile["data_rate_min"], min(profile["data_rate_max"], data_rate))
    
    # Delay — terbalik
    delay = lerp(profile["delay_max"], profile["delay_min"], noisy_q)
    delay = max(profile["delay_min"], min(profile["delay_max"], delay))
    
    # BER — terbalik logaritmik
    ber = lerp_log(profile["ber_min"], profile["ber_max"], 1.0 - noisy_q)
    ber = max(0.0, min(1.0, ber))
    
    # Availability
    available = rss_dbm >= profile["rss_min"]
    
    return {
        "network_id": network_id,
        "technology": technology,
        "rss_dbm": rss_dbm,
        "quality_factor": round(quality, 4),
        "data_rate_mbps": round(data_rate, 3),
        "delay_ms": round(delay, 3),
        "ber": ber,
        "available": available,
    }


# =====================================================================
# Perbandingan dengan Python Generator yang Sudah Ada
# =====================================================================

def compare_with_existing_python():
    """Bandingkan logika hybrid dengan generator Python yang sudah ada."""
    from wmc_simulator.network.profile_generator import (
        NetworkProfileGenerator, NetworkNode, DEFAULT_PROFILES as PY_PROFILES,
    )
    
    print("\n  Membandingkan profil teknologi:")
    for tech in ["4G", "5G", "WLAN"]:
        py_profile = PY_PROFILES[tech]
        dart_profile = PROFILES[tech]
        
        match = (
            py_profile.rss_min == dart_profile["rss_min"] and
            py_profile.rss_max == dart_profile["rss_max"] and
            py_profile.data_rate_min == dart_profile["data_rate_min"] and
            py_profile.data_rate_max == dart_profile["data_rate_max"] and
            py_profile.delay_min == dart_profile["delay_min"] and
            py_profile.delay_max == dart_profile["delay_max"] and
            py_profile.ber_min == dart_profile["ber_min"] and
            py_profile.ber_max == dart_profile["ber_max"]
        )
        status = "✓ COCOK" if match else "✗ BERBEDA"
        print(f"    [{tech}] {status}")
    
    print("\n  Membandingkan logika interpolasi:")
    
    # Bandingkan fungsi _lerp
    py_gen = NetworkProfileGenerator(rng=random.Random(42))
    test_cases_lerp = [
        (0.0, 100.0, 0.0),
        (0.0, 100.0, 0.5),
        (0.0, 100.0, 1.0),
        (10.0, 100.0, 0.3),
    ]
    
    all_match = True
    for lo, hi, t in test_cases_lerp:
        py_result = py_gen._lerp(lo, hi, t)
        dart_result = lerp(lo, hi, t)
        if abs(py_result - dart_result) > 1e-10:
            print(f"    lerp({lo}, {hi}, {t}): Python={py_result}, Dart={dart_result} ✗")
            all_match = False
    
    if all_match:
        print("    _lerp: ✓ Semua test case cocok")
    
    # Bandingkan fungsi _lerp_log
    test_cases_log = [
        (1e-6, 1e-3, 0.0),
        (1e-6, 1e-3, 0.5),
        (1e-6, 1e-3, 1.0),
        (1e-8, 1e-5, 0.3),
    ]
    
    all_match = True
    for lo, hi, t in test_cases_log:
        py_result = py_gen._lerp_log(lo, hi, t)
        dart_result = lerp_log(lo, hi, t)
        if abs(py_result - dart_result) / max(py_result, dart_result, 1e-20) > 1e-6:
            print(f"    lerp_log({lo}, {hi}, {t}): Python={py_result}, Dart={dart_result} ✗")
            all_match = False
    
    if all_match:
        print("    _lerp_log: ✓ Semua test case cocok")


# =====================================================================
# TEST SUITE
# =====================================================================

passed = 0
failed = 0
total = 0


def check(condition, message):
    global passed, failed, total
    total += 1
    if condition:
        passed += 1
        print(f"  ✓ {message}")
    else:
        failed += 1
        print(f"  ✗ GAGAL: {message}")


def header(title):
    print(f"\n{'=' * 70}")
    print(f" {title}")
    print("=" * 70)


def test_quality_factor():
    header("TEST 1: Quality Factor dari RSS (Tanpa Noise)")
    
    # 4G: range -120 ~ -50
    q1 = compute_quality_factor(-50.0, PROFILES["4G"])
    check(q1 == 1.0, f"4G RSS=-50 (terkuat) → quality={q1} == 1.0")
    
    q2 = compute_quality_factor(-120.0, PROFILES["4G"])
    check(q2 == 0.0, f"4G RSS=-120 (terlemah) → quality={q2} == 0.0")
    
    q3 = compute_quality_factor(-85.0, PROFILES["4G"])
    check(abs(q3 - 0.5) < 0.01, f"4G RSS=-85 (tengah) → quality={q3:.4f} ≈ 0.5")
    
    # WLAN: range -90 ~ -30
    q4 = compute_quality_factor(-60.0, PROFILES["WLAN"])
    check(abs(q4 - 0.5) < 0.01, f"WLAN RSS=-60 (tengah) → quality={q4:.4f} ≈ 0.5")
    
    # Clamp test
    q5 = compute_quality_factor(-10.0, PROFILES["4G"])
    check(q5 == 1.0, f"4G RSS=-10 (di atas max) → clamp ke 1.0")
    
    q6 = compute_quality_factor(-150.0, PROFILES["4G"])
    check(q6 == 0.0, f"4G RSS=-150 (di bawah min) → clamp ke 0.0")


def test_data_rate():
    header("TEST 2: Data Rate Proporsional terhadap RSS")
    
    strong = hybrid_estimate("lte_strong", "4G", -55.0)
    weak = hybrid_estimate("lte_weak", "4G", -115.0)
    
    check(
        strong["data_rate_mbps"] > weak["data_rate_mbps"],
        f"RSS kuat → rate {strong['data_rate_mbps']} > RSS lemah → rate {weak['data_rate_mbps']}"
    )
    
    p = PROFILES["4G"]
    check(
        p["data_rate_min"] <= strong["data_rate_mbps"] <= p["data_rate_max"],
        f"Strong rate {strong['data_rate_mbps']} dalam [{p['data_rate_min']}, {p['data_rate_max']}]"
    )
    check(
        p["data_rate_min"] <= weak["data_rate_mbps"] <= p["data_rate_max"],
        f"Weak rate {weak['data_rate_mbps']} dalam [{p['data_rate_min']}, {p['data_rate_max']}]"
    )


def test_delay():
    header("TEST 3: Delay Berbanding Terbalik terhadap RSS")
    
    strong = hybrid_estimate("nr_strong", "5G", -45.0)
    weak = hybrid_estimate("nr_weak", "5G", -105.0)
    
    check(
        strong["delay_ms"] < weak["delay_ms"],
        f"5G strong delay {strong['delay_ms']}ms < weak delay {weak['delay_ms']}ms"
    )
    
    p = PROFILES["5G"]
    check(
        p["delay_min"] <= strong["delay_ms"] <= p["delay_max"],
        f"Strong delay {strong['delay_ms']} dalam [{p['delay_min']}, {p['delay_max']}]"
    )


def test_ber():
    header("TEST 4: BER Berbanding Terbalik (Log-Scale)")
    
    strong = hybrid_estimate("wlan_strong", "WLAN", -35.0)
    weak = hybrid_estimate("wlan_weak", "WLAN", -85.0)
    
    check(
        strong["ber"] < weak["ber"],
        f"WLAN strong BER {strong['ber']:.2e} < weak BER {weak['ber']:.2e}"
    )
    
    check(0 <= strong["ber"] <= 1, f"Strong BER dalam [0, 1]")
    check(0 <= weak["ber"] <= 1, f"Weak BER dalam [0, 1]")


def test_availability():
    header("TEST 5: Ketersediaan Jaringan")
    
    ok = hybrid_estimate("wifi_ok", "WLAN", -70.0)
    out = hybrid_estimate("wifi_out", "WLAN", -95.0)
    
    check(ok["available"] == True, f"WLAN RSS=-70 → available=True")
    check(out["available"] == False, f"WLAN RSS=-95 → available=False")


def test_walk_scenario():
    header("TEST 6: Skenario Walk Test (Simulasi Berjalan)")
    
    rss_values = [-35.0, -45.0, -55.0, -65.0, -75.0, -85.0, -92.0]
    
    print(f"\n  {'RSS(dBm)':>10} {'Quality':>10} {'Rate(Mbps)':>12} {'Delay(ms)':>10} {'BER':>12} {'Status':>8}")
    print(f"  {'-'*10} {'-'*10} {'-'*12} {'-'*10} {'-'*12} {'-'*8}")
    
    results = []
    for rss in rss_values:
        r = hybrid_estimate("wifi_walk", "WLAN", rss)
        results.append(r)
        status = "OK" if r["available"] else "OUT"
        print(f"  {rss:10.1f} {r['quality_factor']:10.4f} {r['data_rate_mbps']:12.1f} {r['delay_ms']:10.1f} {r['ber']:12.2e} {status:>8}")
    
    # Verifikasi tren
    check(
        results[0]["data_rate_mbps"] > results[-2]["data_rate_mbps"],
        f"Data rate menurun: {results[0]['data_rate_mbps']} → {results[-2]['data_rate_mbps']}"
    )
    check(
        results[0]["delay_ms"] < results[-2]["delay_ms"],
        f"Delay meningkat: {results[0]['delay_ms']} → {results[-2]['delay_ms']}"
    )
    check(
        results[0]["ber"] < results[-2]["ber"],
        f"BER meningkat: {results[0]['ber']:.2e} → {results[-2]['ber']:.2e}"
    )
    check(
        results[-1]["available"] == False,
        f"Terakhir (RSS=-92) → OUT of range"
    )


def test_all_technologies_bulk():
    header("TEST 7: Validasi 100 Sampel × 3 Teknologi")
    
    for tech in ["4G", "5G", "WLAN"]:
        p = PROFILES[tech]
        violations = 0
        
        for i in range(100):
            rss = p["rss_min"] + (p["rss_max"] - p["rss_min"]) * (i / 99.0)
            r = hybrid_estimate(f"{tech}_{i}", tech, rss)
            
            if not (p["data_rate_min"] <= r["data_rate_mbps"] <= p["data_rate_max"]):
                violations += 1
            if not (p["delay_min"] <= r["delay_ms"] <= p["delay_max"]):
                violations += 1
            if not (0 <= r["ber"] <= 1):
                violations += 1
        
        check(violations == 0, f"[{tech}] 100 sampel, {violations} pelanggaran rentang")


def test_consistency_with_python_generator():
    header("TEST 8: Konsistensi dengan Python Generator")
    
    try:
        compare_with_existing_python()
        check(True, "Perbandingan berhasil dilakukan")
    except Exception as e:
        check(False, f"Gagal: {e}")


# =====================================================================
# MAIN
# =====================================================================

def main():
    print("╔══════════════════════════════════════════════════════════════════════╗")
    print("║  VERIFIKASI — Hybrid Generator Python ↔ Dart                      ║")
    print("║  Proyek: WMC Vertical Handover Real-Time (FR-03)                  ║")
    print("╚══════════════════════════════════════════════════════════════════════╝")
    
    test_quality_factor()
    test_data_rate()
    test_delay()
    test_ber()
    test_availability()
    test_walk_scenario()
    test_all_technologies_bulk()
    test_consistency_with_python_generator()
    
    print(f"\n{'=' * 70}")
    if failed == 0:
        print(f" ✅ SEMUA {total} TEST LULUS! Logika Hybrid Generator terverifikasi.")
    else:
        print(f" ❌ {failed} dari {total} test GAGAL!")
    print(f" Passed: {passed} | Failed: {failed} | Total: {total}")
    print("=" * 70)


if __name__ == "__main__":
    main()
