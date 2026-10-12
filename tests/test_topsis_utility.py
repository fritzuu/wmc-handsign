"""Unit test komprehensif untuk Baseline Algorithm — Single TOPSIS Utility Function.

Mencakup seluruh pengujian Phase 6:
1. Matriks keputusan kecil yang dapat diverifikasi manual langkah demi langkah (intermediate values).
2. Kriteria campuran benefit dan cost.
3. Bobot tidak sama dan normalisasi bobot.
4. Validasi bobot negatif atau tidak valid.
5. Penanganan nilai hilang / non-numerik.
6. Kriteria konstan dan kolom bernilai nol.
7. Solusi ideal berimpit (coincident ideal solutions).
8. Penanganan pembagi nol pada penyebut jarak (D+ + D- == 0).
9. Penanganan skor utilitas seri (tied scores).
10. Stabilitas peringkat dan reprodusibilitas.
11. Evaluasi pada ScenarioSnapshot simulator.
12. Simulasi multi-step handover dan metrik ping-pong.
"""

import math
import unittest

from wmc_simulator.baseline import (
    CriterionType,
    DEFAULT_TOPSIS_WEIGHTS,
    SingleTopsisUtilityFunction,
    TopsisAlternative,
    run_baseline_topsis_scenario,
)
from wmc_simulator.models import NetworkSnapshot, ScenarioSnapshot


class TestSingleTopsisUtilityFunction(unittest.TestCase):
    def setUp(self):
        self.topsis = SingleTopsisUtilityFunction()

    def test_1_manual_verifiable_matrix_intermediate_steps(self):
        """Verifikasi numerik terhadap perhitungan manual independen langkah demi langkah:

        Alternatif:
          A1 (4G):   Data Rate = 30 Mbps,  Delay = 40 ms, BER = 0.001
          A2 (5G):   Data Rate = 100 Mbps, Delay = 10 ms, BER = 0.00001
          A3 (WLAN): Data Rate = 50 Mbps,  Delay = 25 ms, BER = 0.0001

        Kriteria:
          Data Rate: benefit
          Delay: cost
          BER: cost

        Bobot:
          w = [0.5, 0.3, 0.2]
        """
        alts = [
            TopsisAlternative("A1", {"data_rate_mbps": 30.0, "delay_ms": 40.0, "ber": 0.001}),
            TopsisAlternative("A2", {"data_rate_mbps": 100.0, "delay_ms": 10.0, "ber": 0.00001}),
            TopsisAlternative("A3", {"data_rate_mbps": 50.0, "delay_ms": 25.0, "ber": 0.0001}),
        ]
        weights = {"data_rate_mbps": 0.5, "delay_ms": 0.3, "ber": 0.2}

        res = self.topsis.evaluate(alts, weights=weights)
        detail = res.details

        # 1. Cek normalisasi vektor
        # denom DR = sqrt(30^2 + 100^2 + 50^2) = sqrt(13400) ≈ 115.758369
        self.assertAlmostEqual(detail.normalized_matrix["A1"]["data_rate_mbps"], 30.0 / math.sqrt(13400), places=5)
        self.assertAlmostEqual(detail.normalized_matrix["A2"]["data_rate_mbps"], 100.0 / math.sqrt(13400), places=5)
        self.assertAlmostEqual(detail.normalized_matrix["A3"]["data_rate_mbps"], 50.0 / math.sqrt(13400), places=5)

        # 2. Cek matriks terbobot
        v_a2_dr = (100.0 / math.sqrt(13400)) * 0.5
        self.assertAlmostEqual(detail.weighted_matrix["A2"]["data_rate_mbps"], v_a2_dr, places=5)

        # 3. Cek Solusi Ideal Positif & Negatif
        # Data rate (benefit): pos = max, neg = min
        self.assertEqual(detail.ideal_positive["data_rate_mbps"], detail.weighted_matrix["A2"]["data_rate_mbps"])
        self.assertEqual(detail.ideal_negative["data_rate_mbps"], detail.weighted_matrix["A1"]["data_rate_mbps"])
        # Delay (cost): pos = min, neg = max
        self.assertEqual(detail.ideal_positive["delay_ms"], detail.weighted_matrix["A2"]["delay_ms"])
        self.assertEqual(detail.ideal_negative["delay_ms"], detail.weighted_matrix["A1"]["delay_ms"])

        # 4. A2 ideal di seluruh kriteria -> D+ = 0, Ci = 1.0
        r_a2 = next(r for r in res.rankings if r.alternative_id == "A2")
        self.assertAlmostEqual(r_a2.d_plus, 0.0, places=5)
        self.assertAlmostEqual(r_a2.utility_score, 1.0, places=5)
        self.assertEqual(r_a2.rank, 1)

        # 5. A1 terburuk di seluruh kriteria -> D- = 0, Ci = 0.0
        r_a1 = next(r for r in res.rankings if r.alternative_id == "A1")
        self.assertAlmostEqual(r_a1.d_minus, 0.0, places=5)
        self.assertAlmostEqual(r_a1.utility_score, 0.0, places=5)
        self.assertEqual(r_a1.rank, 3)

        # 6. A3 di tengah-tengah: skor ≈ 0.482
        r_a3 = next(r for r in res.rankings if r.alternative_id == "A3")
        self.assertTrue(0.40 < r_a3.utility_score < 0.60)
        self.assertEqual(r_a3.rank, 2)

        # Pemenang terbaik adalah A2
        self.assertEqual(res.best_alternative_id, "A2")

    def test_2_mixed_benefit_and_cost_criteria(self):
        """Memeriksa penanganan kriteria campuran secara benar."""
        alts = [
            TopsisAlternative("high_rate_high_delay", {"data_rate_mbps": 100.0, "delay_ms": 100.0}),
            TopsisAlternative("low_rate_low_delay", {"data_rate_mbps": 10.0, "delay_ms": 10.0}),
        ]
        # Jika prioritas utama adalah Data Rate (benefit):
        res_dr_priority = self.topsis.evaluate(
            alts,
            weights={"data_rate_mbps": 0.9, "delay_ms": 0.1},
        )
        self.assertEqual(res_dr_priority.best_alternative_id, "high_rate_high_delay")

        # Jika prioritas utama adalah Delay rendah (cost):
        res_delay_priority = self.topsis.evaluate(
            alts,
            weights={"data_rate_mbps": 0.1, "delay_ms": 0.9},
        )
        self.assertEqual(res_delay_priority.best_alternative_id, "low_rate_low_delay")

    def test_3_unequal_and_normalized_weights(self):
        """Bobot yang tidak dijumlahkan = 1.0 harus otomatis dinormalisasi secara proporsional."""
        alts = [
            TopsisAlternative("X1", {"data_rate_mbps": 50.0, "delay_ms": 20.0, "ber": 0.001}),
            TopsisAlternative("X2", {"data_rate_mbps": 80.0, "delay_ms": 50.0, "ber": 0.0001}),
        ]
        # Bobot unnormalized: [5, 3, 2] -> sum = 10
        res1 = self.topsis.evaluate(alts, weights={"data_rate_mbps": 5.0, "delay_ms": 3.0, "ber": 2.0})
        # Bobot normalized: [0.5, 0.3, 0.2] -> sum = 1.0
        res2 = self.topsis.evaluate(alts, weights={"data_rate_mbps": 0.5, "delay_ms": 0.3, "ber": 0.2})

        self.assertAlmostEqual(res1.details.weights["data_rate_mbps"], 0.5, places=6)
        self.assertAlmostEqual(res1.details.weights["delay_ms"], 0.3, places=6)
        self.assertAlmostEqual(res1.details.weights["ber"], 0.2, places=6)

        # Hasil ranking dan utility score harus identik
        for r1, r2 in zip(res1.rankings, res2.rankings):
            self.assertEqual(r1.alternative_id, r2.alternative_id)
            self.assertAlmostEqual(r1.utility_score, r2.utility_score, places=6)

    def test_4_invalid_weights_rejected(self):
        """Bobot negatif, non-finite, atau total nol harus menghasilkan ValueError."""
        alts = [TopsisAlternative("A", {"data_rate_mbps": 10.0, "delay_ms": 20.0})]

        # Bobot negatif
        with self.assertRaises(ValueError):
            self.topsis.evaluate(alts, weights={"data_rate_mbps": -0.5, "delay_ms": 0.5})

        # Total bobot nol
        with self.assertRaises(ValueError):
            self.topsis.evaluate(alts, weights={"data_rate_mbps": 0.0, "delay_ms": 0.0})

        # Non-finite weight
        with self.assertRaises(ValueError):
            self.topsis.evaluate(alts, weights={"data_rate_mbps": float("nan"), "delay_ms": 0.5})

    def test_5_missing_and_non_numeric_values_rejected(self):
        """Nilai kriteria yang None, string, atau NaN harus menghasilkan ValueError."""
        alts = [
            TopsisAlternative("Bad1", {"data_rate_mbps": float("nan"), "delay_ms": 20.0, "ber": 0.01}),
            TopsisAlternative("Good", {"data_rate_mbps": 50.0, "delay_ms": 20.0, "ber": 0.01}),
        ]
        with self.assertRaises(ValueError):
            self.topsis.evaluate(alts)

    def test_6_constant_criteria_and_zero_columns(self):
        """Kolom dengan nilai konstan atau seluruhnya nol tidak boleh menghasilkan ZeroDivisionError atau NaN."""
        alts = [
            TopsisAlternative("A1", {"data_rate_mbps": 50.0, "delay_ms": 20.0, "ber": 0.0}),
            TopsisAlternative("A2", {"data_rate_mbps": 80.0, "delay_ms": 20.0, "ber": 0.0}),
        ]
        # delay_ms bernilai konstan 20.0; ber bernilai 0.0 di kedua alternatif
        res = self.topsis.evaluate(alts, weights={"data_rate_mbps": 0.5, "delay_ms": 0.3, "ber": 0.2})
        self.assertIsNotNone(res.best_alternative_id)
        for r in res.rankings:
            self.assertTrue(math.isfinite(r.utility_score))
            self.assertTrue(math.isfinite(r.d_plus))
            self.assertTrue(math.isfinite(r.d_minus))

    def test_7_coincident_ideal_solutions_and_zero_denominator(self):
        """Jika semua alternatif identik pada semua kriteria, Ci harus bernilai 0.5 secara aman tanpa crash."""
        alts = [
            TopsisAlternative("Same1", {"data_rate_mbps": 50.0, "delay_ms": 20.0, "ber": 0.001}),
            TopsisAlternative("Same2", {"data_rate_mbps": 50.0, "delay_ms": 20.0, "ber": 0.001}),
        ]
        res = self.topsis.evaluate(alts)
        self.assertEqual(len(res.rankings), 2)
        for r in res.rankings:
            self.assertEqual(r.utility_score, 0.5)

    def test_8_single_alternative_boundary_case(self):
        """Jika hanya 1 alternatif, skor utilitas adalah 1.0 dan rank 1."""
        alts = [TopsisAlternative("OnlyOne", {"data_rate_mbps": 40.0, "delay_ms": 30.0, "ber": 0.001})]
        res = self.topsis.evaluate(alts)
        self.assertEqual(res.best_alternative_id, "OnlyOne")
        self.assertEqual(res.rankings[0].utility_score, 1.0)
        self.assertEqual(res.rankings[0].rank, 1)

    def test_9_tied_utility_scores_stable_ranking(self):
        """Alternatif yang seri harus mempertahankan urutan yang deterministik."""
        alts = [
            TopsisAlternative("NetB", {"data_rate_mbps": 50.0, "delay_ms": 20.0}),
            TopsisAlternative("NetA", {"data_rate_mbps": 50.0, "delay_ms": 20.0}),
        ]
        res1 = self.topsis.evaluate(alts)
        res2 = self.topsis.evaluate(alts)

        self.assertEqual([r.alternative_id for r in res1.rankings], [r.alternative_id for r in res2.rankings])

    def test_10_evaluate_scenario_snapshot(self):
        """Memverifikasi evaluasi langsung terhadap ScenarioSnapshot simulator."""
        snapshot = ScenarioSnapshot(
            timestamp_s=1.0,
            current_network="lte_1",
            velocity_mps=1.4,
            traffic_class="streaming",
            networks=(
                NetworkSnapshot("lte_1", "4G", -85.0, 25.0, 40.0, 0.001, True),
                NetworkSnapshot("nr_1", "5G", -75.0, 150.0, 10.0, 0.00001, True),
                NetworkSnapshot("wlan_1", "WLAN", -65.0, 60.0, 20.0, 0.0001, True),
                NetworkSnapshot("dead_wlan", "WLAN", -95.0, 0.0, 100.0, 0.1, False),  # Unavailable
            ),
        )

        res = self.topsis.evaluate_snapshot(snapshot)
        # Jaringan unavailable harus otomatis disaring keluar
        ranked_ids = [r.alternative_id for r in res.rankings]
        self.assertNotIn("dead_wlan", ranked_ids)
        self.assertEqual(len(ranked_ids), 3)

        # 5G memiliki rate tertinggi dan delay terendah -> harus rank 1
        self.assertEqual(res.best_alternative_id, "nr_1")

        # Cek keputusan handover
        decision = self.topsis.decide_handover(snapshot)
        self.assertTrue(decision["handover_recommended"])
        self.assertEqual(decision["target_network"], "nr_1")
        self.assertEqual(decision["current_network"], "lte_1")

    def test_11_traffic_class_weights_differ(self):
        """Memastikan setiap kelas trafik (conversational, streaming, background) menggunakan bobot berbeda."""
        alts = [
            TopsisAlternative("high_rate_mod_delay", {"data_rate_mbps": 120.0, "delay_ms": 45.0, "ber": 0.001}),
            TopsisAlternative("low_rate_low_delay", {"data_rate_mbps": 15.0, "delay_ms": 8.0, "ber": 0.0001}),
        ]

        res_conv = self.topsis.evaluate(alts, weights=DEFAULT_TOPSIS_WEIGHTS["conversational"])
        res_bg = self.topsis.evaluate(alts, weights=DEFAULT_TOPSIS_WEIGHTS["background"])

        # Pada conversational, delay berbobot 0.50 -> low_delay menang
        self.assertEqual(res_conv.best_alternative_id, "low_rate_low_delay")
        # Pada background, data rate berbobot 0.60 -> high_rate menang
        self.assertEqual(res_bg.best_alternative_id, "high_rate_mod_delay")

    def test_12_multi_step_scenario_and_ping_pong_metrics(self):
        """Memverifikasi runner skenario beruntun dan perhitungan metrik evaluasi."""
        # Buat skenario di mana sinyal 5G dan WLAN bergantian mendominasi
        steps = [
            ScenarioSnapshot(
                0.0, "lte_1", 10.0, "streaming",
                (
                    NetworkSnapshot("lte_1", "4G", -80.0, 20.0, 35.0, 0.001, True),
                    NetworkSnapshot("nr_1", "5G", -70.0, 100.0, 10.0, 0.00001, True),
                )
            ),
            ScenarioSnapshot(
                1.0, "nr_1", 10.0, "streaming",
                (
                    NetworkSnapshot("lte_1", "4G", -70.0, 80.0, 12.0, 0.00001, True),  # LTE tiba-tiba sangat bagus
                    NetworkSnapshot("nr_1", "5G", -90.0, 10.0, 80.0, 0.01, True),
                )
            ),
            ScenarioSnapshot(
                2.0, "lte_1", 10.0, "streaming",
                (
                    NetworkSnapshot("lte_1", "4G", -90.0, 10.0, 80.0, 0.01, True),
                    NetworkSnapshot("nr_1", "5G", -70.0, 100.0, 10.0, 0.00001, True),  # 5G kembali bagus (< 3 detik)
                )
            ),
        ]

        result = run_baseline_topsis_scenario(steps)
        self.assertEqual(result["total_timesteps"], 3)
        self.assertGreater(result["total_handovers"], 0)
        # Harusnya terdeteksi ping-pong karena berpindah bolak-balik dalam waktu < 3s
        self.assertGreater(result["ping_pong_count"], 0)
        self.assertTrue(0.0 <= result["ping_pong_rate"] <= 1.0)


if __name__ == "__main__":
    unittest.main()
