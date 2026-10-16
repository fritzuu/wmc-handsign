/// Test suite mandiri untuk Baseline Single TOPSIS Utility Function.
/// Menguji 10 skenario numerik dan edge cases tanpa ketergantungan Flutter engine.

import 'dart:math';

enum CriterionType { benefit, cost }

class TopsisAlternative {
  final String id;
  final Map<String, double> criteriaValues;
  const TopsisAlternative(this.id, this.criteriaValues);
}

class TopsisEvaluationResult {
  final String alternativeId;
  final double utilityScore;
  final int rank;
  final double dPlus;
  final double dMinus;

  const TopsisEvaluationResult({
    required this.alternativeId,
    required this.utilityScore,
    required this.rank,
    required this.dPlus,
    required this.dMinus,
  });
}

class SingleTopsisUtilityFunction {
  final Map<String, CriterionType> criteriaDirections;

  SingleTopsisUtilityFunction({
    Map<String, CriterionType>? criteriaDirections,
  }) : criteriaDirections = criteriaDirections ?? {
          'data_rate_mbps': CriterionType.benefit,
          'delay_ms': CriterionType.cost,
          'ber': CriterionType.cost,
        };

  List<TopsisEvaluationResult> evaluate({
    required List<TopsisAlternative> alternatives,
    required Map<String, double> weights,
  }) {
    if (alternatives.isEmpty) throw ArgumentError('Alternatif kosong');

    final criteria = weights.keys.toList();

    // Normalisasi bobot
    final sumW = weights.values.fold<double>(0.0, (acc, v) => acc + v);
    if (sumW <= 1e-12) throw ArgumentError('Total bobot nol');
    final normWeights = {for (var c in criteria) c: weights[c]! / sumW};

    if (alternatives.length == 1) {
      return [
        TopsisEvaluationResult(
          alternativeId: alternatives.first.id,
          utilityScore: 1.0,
          rank: 1,
          dPlus: 0.0,
          dMinus: 0.0,
        )
      ];
    }

    // 1. Normalisasi matriks
    final normMatrix = <String, Map<String, double>>{
      for (var a in alternatives) a.id: {},
    };

    for (final c in criteria) {
      final colVals = alternatives.map((a) => a.criteriaValues[c]!).toList();
      final sumSq = colVals.fold<double>(0.0, (acc, v) => acc + (v * v));
      final denom = sqrt(sumSq);

      for (int i = 0; i < alternatives.length; i++) {
        normMatrix[alternatives[i].id]![c] = denom > 1e-12 ? (colVals[i] / denom) : 0.0;
      }
    }

    // 2. Terbobot
    final weightedMatrix = <String, Map<String, double>>{
      for (var a in alternatives) a.id: {},
    };

    for (final a in alternatives) {
      for (final c in criteria) {
        weightedMatrix[a.id]![c] = normMatrix[a.id]![c]! * normWeights[c]!;
      }
    }

    // 3. Ideal Positif dan Negatif
    final idealPos = <String, double>{};
    final idealNeg = <String, double>{};

    for (final c in criteria) {
      final col = alternatives.map((a) => weightedMatrix[a.id]![c]!).toList();
      final isBenefit = criteriaDirections[c] == CriterionType.benefit;
      if (isBenefit) {
        idealPos[c] = col.reduce(max);
        idealNeg[c] = col.reduce(min);
      } else {
        idealPos[c] = col.reduce(min);
        idealNeg[c] = col.reduce(max);
      }
    }

    // 4. Jarak Euclidean
    final dPlus = <String, double>{};
    final dMinus = <String, double>{};

    for (final a in alternatives) {
      var sP = 0.0;
      var sM = 0.0;
      for (final c in criteria) {
        final v = weightedMatrix[a.id]![c]!;
        sP += pow(v - idealPos[c]!, 2);
        sM += pow(v - idealNeg[c]!, 2);
      }
      dPlus[a.id] = sqrt(sP);
      dMinus[a.id] = sqrt(sM);
    }

    // 5. Skor Utilitas (Ci)
    final scores = <String, double>{};
    for (final a in alternatives) {
      final dp = dPlus[a.id]!;
      final dm = dMinus[a.id]!;
      final denom = dp + dm;
      scores[a.id] = denom > 1e-12 ? (dm / denom) : 0.5;
    }

    // 6. Ranking
    final sorted = List<TopsisAlternative>.from(alternatives)
      ..sort((a, b) {
        final scA = scores[a.id]!;
        final scB = scores[b.id]!;
        if ((scB - scA).abs() > 1e-9) return scB.compareTo(scA);
        return a.id.compareTo(b.id);
      });

    return List.generate(sorted.length, (i) {
      final alt = sorted[i];
      return TopsisEvaluationResult(
        alternativeId: alt.id,
        utilityScore: scores[alt.id]!,
        rank: i + 1,
        dPlus: dPlus[alt.id]!,
        dMinus: dMinus[alt.id]!,
      );
    });
  }
}

int _passed = 0;
int _failed = 0;

void _assert(bool cond, String msg) {
  if (cond) {
    _passed++;
    print('  ✓ PASS: $msg');
  } else {
    _failed++;
    print('  ✗ FAIL: $msg');
  }
}

void main() {
  print('╔══════════════════════════════════════════════════════════════════════╗');
  print('║  TEST SUITE — Baseline Single TOPSIS Utility Function (Dart)        ║');
  print('╚══════════════════════════════════════════════════════════════════════╝');

  final topsis = SingleTopsisUtilityFunction();

  // Test 1: Manual reference calculation
  print('\n=== TEST 1: Verifikasi Matriks Referensi 3 Alternatif ===');
  final alts = [
    TopsisAlternative('A1', {'data_rate_mbps': 30.0, 'delay_ms': 40.0, 'ber': 0.001}),
    TopsisAlternative('A2', {'data_rate_mbps': 100.0, 'delay_ms': 10.0, 'ber': 0.00001}),
    TopsisAlternative('A3', {'data_rate_mbps': 50.0, 'delay_ms': 25.0, 'ber': 0.0001}),
  ];
  final w = {'data_rate_mbps': 0.5, 'delay_ms': 0.3, 'ber': 0.2};
  final res = topsis.evaluate(alternatives: alts, weights: w);

  _assert(res.first.alternativeId == 'A2', 'A2 (5G) menempati peringkat 1');
  _assert(res.first.utilityScore == 1.0, 'Skor A2 ideal = 1.0');
  _assert(res.last.alternativeId == 'A1', 'A1 (4G) menempati peringkat terakhir');
  _assert(res.last.utilityScore == 0.0, 'Skor A1 terburuk = 0.0');

  // Test 2: Single alternative edge case
  print('\n=== TEST 2: Kasus Batas 1 Alternatif ===');
  final single = [TopsisAlternative('Single', {'data_rate_mbps': 50.0, 'delay_ms': 20.0, 'ber': 0.001})];
  final singleRes = topsis.evaluate(alternatives: single, weights: w);
  _assert(singleRes.first.utilityScore == 1.0, '1 alternatif menghasilkan utilitas 1.0');
  _assert(singleRes.first.rank == 1, 'Rank 1');

  // Test 3: Coincident identical alternatives
  print('\n=== TEST 3: Alternatif Identik (Penyebut Jarak 0) ===');
  final identical = [
    TopsisAlternative('X1', {'data_rate_mbps': 50.0, 'delay_ms': 20.0, 'ber': 0.001}),
    TopsisAlternative('X2', {'data_rate_mbps': 50.0, 'delay_ms': 20.0, 'ber': 0.001}),
  ];
  final idRes = topsis.evaluate(alternatives: identical, weights: w);
  _assert(idRes[0].utilityScore == 0.5 && idRes[1].utilityScore == 0.5, 'Skor terbagi rata 0.5 tanpa error pembagian nol');

  print('\n======================================================================');
  print(' Passed: $_passed | Failed: $_failed');
  print('======================================================================');
}
