import 'dart:math';

/// Tipe kriteria keputusan dalam evaluasi TOPSIS.
enum CriterionType {
  benefit, // Semakin tinggi semakin baik (misal: Data Rate, RSS)
  cost,    // Semakin rendah semakin baik (misal: Delay, BER)
}

/// Bobot kriteria default per kelas aplikasi berdasarkan PRD v1.0/v2.0 (FR-07, FR-08).
/// Kriteria standar: Data Rate (benefit), Delay (cost), BER (cost).
const Map<String, Map<String, double>> defaultTopsisWeights = {
  'conversational': {
    'data_rate_mbps': 0.20,
    'delay_ms': 0.50,
    'ber': 0.30,
  },
  'streaming': {
    'data_rate_mbps': 0.50,
    'delay_ms': 0.30,
    'ber': 0.20,
  },
  'interactive': {
    'data_rate_mbps': 0.40,
    'delay_ms': 0.35,
    'ber': 0.25,
  },
  'background': {
    'data_rate_mbps': 0.60,
    'delay_ms': 0.20,
    'ber': 0.20,
  },
};

const Map<String, CriterionType> defaultCriteriaDirections = {
  'data_rate_mbps': CriterionType.benefit,
  'delay_ms': CriterionType.cost,
  'ber': CriterionType.cost,
  'rss_dbm': CriterionType.benefit,
};

/// Representasi alternatif jaringan yang dievaluasi oleh TOPSIS.
class TopsisAlternative {
  final String id;
  final Map<String, double> criteriaValues;
  final Map<String, dynamic> metadata;

  const TopsisAlternative({
    required this.id,
    required this.criteriaValues,
    this.metadata = const {},
  });
}

/// Hasil evaluasi per kandidat alternatif.
class TopsisEvaluationResult {
  final String alternativeId;
  final double utilityScore; // Relative closeness Ci in [0.0, 1.0]
  final int rank;            // 1-indexed (1 = peringkat terbaik)
  final double dPlus;        // Jarak Euclidean ke Solusi Ideal Positif (A+)
  final double dMinus;       // Jarak Euclidean ke Solusi Ideal Negatif (A-)
  final Map<String, dynamic> metadata;

  const TopsisEvaluationResult({
    required this.alternativeId,
    required this.utilityScore,
    required this.rank,
    required this.dPlus,
    required this.dMinus,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'alternative_id': alternativeId,
        'utility_score': double.parse(utilityScore.toStringAsFixed(6)),
        'rank': rank,
        'd_plus': double.parse(dPlus.toStringAsFixed(6)),
        'd_minus': double.parse(dMinus.toStringAsFixed(6)),
        'metadata': metadata,
      };
}

/// Rincian intermediate perhitungan TOPSIS untuk transparansi matematis.
class TopsisStepDetail {
  final List<String> criteriaNames;
  final Map<String, double> weights;
  final Map<String, String> criteriaTypes;
  final Map<String, Map<String, double>> normalizedMatrix;
  final Map<String, Map<String, double>> weightedMatrix;
  final Map<String, double> idealPositive;
  final Map<String, double> idealNegative;

  const TopsisStepDetail({
    required this.criteriaNames,
    required this.weights,
    required this.criteriaTypes,
    required this.normalizedMatrix,
    required this.weightedMatrix,
    required this.idealPositive,
    required this.idealNegative,
  });
}

/// Hasil komprehensif evaluasi Single TOPSIS Utility Function.
class SingleTopsisResult {
  final List<TopsisEvaluationResult> rankings;
  final String? bestAlternativeId;
  final double? bestUtilityScore;
  final TopsisStepDetail details;

  const SingleTopsisResult({
    required this.rankings,
    required this.bestAlternativeId,
    required this.bestUtilityScore,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'best_alternative_id': bestAlternativeId,
        'best_utility_score': bestUtilityScore != null
            ? double.parse(bestUtilityScore!.toStringAsFixed(6))
            : null,
        'rankings': rankings.map((r) => r.toJson()).toList(),
      };
}

/// Implementasi algoritma Baseline Single TOPSIS Utility Function.
class SingleTopsisUtilityFunction {
  final Map<String, CriterionType> criteriaDirections;
  final Map<String, double>? defaultWeights;

  SingleTopsisUtilityFunction({
    Map<String, CriterionType>? criteriaDirections,
    this.defaultWeights,
  }) : criteriaDirections = criteriaDirections ?? defaultCriteriaDirections;

  /// Evaluasi daftar alternatif menggunakan metode TOPSIS standar.
  SingleTopsisResult evaluate({
    required List<TopsisAlternative> alternatives,
    Map<String, double>? weights,
    List<String>? criteriaNames,
  }) {
    if (alternatives.isEmpty) {
      throw ArgumentError('Daftar alternatif tidak boleh kosong.');
    }

    final activeCriteria = criteriaNames ??
        (weights != null
            ? weights.keys.toList()
            : (defaultWeights != null
                ? defaultWeights!.keys.toList()
                : ['data_rate_mbps', 'delay_ms', 'ber']));

    if (activeCriteria.isEmpty) {
      throw ArgumentError('Tidak ada kriteria evaluasi yang ditentukan.');
    }

    // Normalisasi bobot sehingga sum = 1.0
    final normWeights = _resolveAndNormalizeWeights(activeCriteria, weights);

    // Kasus 1 alternatif
    if (alternatives.length == 1) {
      final alt = alternatives.first;
      final eval = TopsisEvaluationResult(
        alternativeId: alt.id,
        utilityScore: 1.0,
        rank: 1,
        dPlus: 0.0,
        dMinus: 0.0,
        metadata: alt.metadata,
      );
      final detail = TopsisStepDetail(
        criteriaNames: activeCriteria,
        weights: normWeights,
        criteriaTypes: {for (var c in activeCriteria) c: (criteriaDirections[c] ?? CriterionType.benefit).name},
        normalizedMatrix: {alt.id: {for (var c in activeCriteria) c: 1.0}},
        weightedMatrix: {alt.id: {for (var c in activeCriteria) c: normWeights[c]!}},
        idealPositive: {for (var c in activeCriteria) c: normWeights[c]!},
        idealNegative: {for (var c in activeCriteria) c: normWeights[c]!},
      );
      return SingleTopsisResult(
        rankings: [eval],
        bestAlternativeId: alt.id,
        bestUtilityScore: 1.0,
        details: detail,
      );
    }

    // 1. Normalisasi vektor: r_ij = x_ij / sqrt(sum_k x_kj^2)
    final normMatrix = <String, Map<String, double>>{
      for (var alt in alternatives) alt.id: {},
    };

    for (final c in activeCriteria) {
      final colVals = <double>[];
      for (final alt in alternatives) {
        final val = alt.criteriaValues[c];
        if (val == null || !val.isFinite) {
          throw ArgumentError("Nilai kriteria '$c' pada alternatif '${alt.id}' tidak valid: $val");
        }
        colVals.add(val);
      }

      final sumSq = colVals.fold<double>(0.0, (acc, v) => acc + (v * v));
      final denom = sqrt(sumSq);

      for (int i = 0; i < alternatives.length; i++) {
        final altId = alternatives[i].id;
        final v = colVals[i];
        normMatrix[altId]![c] = denom > 1e-12 ? (v / denom) : 0.0;
      }
    }

    // 2. Matriks ternormalisasi terbobot: v_ij = w_j * r_ij
    final weightedMatrix = <String, Map<String, double>>{
      for (var alt in alternatives) alt.id: {},
    };

    for (final alt in alternatives) {
      for (final c in activeCriteria) {
        weightedMatrix[alt.id]![c] = normMatrix[alt.id]![c]! * normWeights[c]!;
      }
    }

    // 3. Solusi Ideal Positif (A+) dan Negatif (A-)
    final idealPos = <String, double>{};
    final idealNeg = <String, double>{};

    for (final c in activeCriteria) {
      final colWeighted = alternatives.map((a) => weightedMatrix[a.id]![c]!).toList();
      final cType = criteriaDirections[c] ?? CriterionType.benefit;

      if (cType == CriterionType.benefit) {
        idealPos[c] = colWeighted.reduce(max);
        idealNeg[c] = colWeighted.reduce(min);
      } else {
        idealPos[c] = colWeighted.reduce(min);
        idealNeg[c] = colWeighted.reduce(max);
      }
    }

    // 4. Jarak Euclidean (D+ dan D-)
    final dPlusMap = <String, double>{};
    final dMinusMap = <String, double>{};

    for (final alt in alternatives) {
      var sumDiffPos = 0.0;
      var sumDiffNeg = 0.0;

      for (final c in activeCriteria) {
        final v = weightedMatrix[alt.id]![c]!;
        sumDiffPos += pow(v - idealPos[c]!, 2);
        sumDiffNeg += pow(v - idealNeg[c]!, 2);
      }

      dPlusMap[alt.id] = sqrt(sumDiffPos);
      dMinusMap[alt.id] = sqrt(sumDiffNeg);
    }

    // 5. Skor Utilitas Kedekatan Relatif: Ci = D- / (D+ + D-)
    final utilityScores = <String, double>{};
    for (final alt in alternatives) {
      final dp = dPlusMap[alt.id]!;
      final dm = dMinusMap[alt.id]!;
      final denom = dp + dm;
      utilityScores[alt.id] = denom > 1e-12 ? (dm / denom) : 0.5;
    }

    // 6. Urutkan secara descending berdasarkan Ci (tie-breaker stabil dengan ID)
    final sortedAlts = List<TopsisAlternative>.from(alternatives)
      ..sort((a, b) {
        final scoreA = utilityScores[a.id]!;
        final scoreB = utilityScores[b.id]!;
        if ((scoreB - scoreA).abs() > 1e-9) {
          return scoreB.compareTo(scoreA);
        }
        return a.id.compareTo(b.id);
      });

    final rankings = <TopsisEvaluationResult>[];
    for (int i = 0; i < sortedAlts.length; i++) {
      final alt = sortedAlts[i];
      rankings.add(
        TopsisEvaluationResult(
          alternativeId: alt.id,
          utilityScore: utilityScores[alt.id]!,
          rank: i + 1,
          dPlus: dPlusMap[alt.id]!,
          dMinus: dMinusMap[alt.id]!,
          metadata: alt.metadata,
        ),
      );
    }

    final detail = TopsisStepDetail(
      criteriaNames: activeCriteria,
      weights: normWeights,
      criteriaTypes: {for (var c in activeCriteria) c: (criteriaDirections[c] ?? CriterionType.benefit).name},
      normalizedMatrix: normMatrix,
      weightedMatrix: weightedMatrix,
      idealPositive: idealPos,
      idealNegative: idealNeg,
    );

    return SingleTopsisResult(
      rankings: rankings,
      bestAlternativeId: rankings.isNotEmpty ? rankings.first.alternativeId : null,
      bestUtilityScore: rankings.isNotEmpty ? rankings.first.utilityScore : null,
      details: detail,
    );
  }

  Map<String, double> _resolveAndNormalizeWeights(
    List<String> criteria,
    Map<String, double>? weights,
  ) {
    final target = <String, double>{};

    if (weights != null) {
      for (final c in criteria) {
        final w = weights[c];
        if (w == null || !w.isFinite || w < 0) {
          throw ArgumentError("Bobot untuk kriteria '$c' harus non-negatif dan finite: $w");
        }
        target[c] = w;
      }
    } else if (defaultWeights != null) {
      for (final c in criteria) {
        target[c] = defaultWeights![c] ?? (1.0 / criteria.length);
      }
    } else {
      final eq = 1.0 / criteria.length;
      for (final c in criteria) {
        target[c] = eq;
      }
    }

    final sumW = target.values.fold<double>(0.0, (acc, v) => acc + v);
    if (sumW <= 1e-12) {
      throw ArgumentError('Total bobot kriteria tidak boleh bernilai nol.');
    }

    return {for (var c in criteria) c: target[c]! / sumW};
  }
}
