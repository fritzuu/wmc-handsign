import 'dart:math' as math;
import '../handover/configuration.dart';
import '../handover/models.dart';
import 'app_profile.dart';

enum SuitabilityLevel {
  optimal,
  acceptable,
  violated,
}

class CandidateSuitability {
  final NetworkSnapshot candidate;
  final double suitabilityScore; // 0 - 100%
  final double dataRateScore; // 0 - 1.0
  final double delayScore; // 0 - 1.0
  final double berScore; // 0 - 1.0
  final bool isSlaViolated;
  final List<String> violations;
  final SuitabilityLevel level;
  final String statusLabel;

  const CandidateSuitability({
    required this.candidate,
    required this.suitabilityScore,
    required this.dataRateScore,
    required this.delayScore,
    required this.berScore,
    required this.isSlaViolated,
    required this.violations,
    required this.level,
    required this.statusLabel,
  });
}

class AppSuitabilityReport {
  final AppProfile appProfile;
  final CandidateSuitability? bestCandidate;
  final List<CandidateSuitability> rankings;
  final String summary;

  const AppSuitabilityReport({
    required this.appProfile,
    required this.bestCandidate,
    required this.rankings,
    required this.summary,
  });
}

/// Evaluator kesesuaian jaringan khusus berdasarkan SLA aplikasi spesifik.
///
/// Mengacu pada formulasi matematis di docs/spesifikasi-rekomendasi-aplikasi.md
class AppNetworkEvaluator {
  final HandoverConfiguration configuration;

  AppNetworkEvaluator({HandoverConfiguration? configuration})
      : configuration = configuration ?? HandoverConfiguration();

  AppSuitabilityReport evaluate({
    required AppProfile appProfile,
    required List<NetworkSnapshot> candidates,
  }) {
    final availableCandidates = candidates.where((c) => c.available).toList();
    if (availableCandidates.isEmpty) {
      return AppSuitabilityReport(
        appProfile: appProfile,
        bestCandidate: null,
        rankings: const [],
        summary: 'Tidak ada kandidat jaringan yang tersedia saat ini.',
      );
    }

    // Dapatkan bobot AHP (dari customWeights jika ada, atau default configuration)
    final weights = appProfile.customWeights ??
        configuration.weights[appProfile.trafficClass] ??
        CriterionWeights(0.333, 0.333, 0.334);

    final evaluatedList = availableCandidates.map((c) {
      return _evaluateCandidate(c, appProfile, weights);
    }).toList();

    // Urutkan berdasarkan suitabilityScore menurun
    evaluatedList.sort((a, b) => b.suitabilityScore.compareTo(a.suitabilityScore));

    final best = evaluatedList.first;
    final summary = _generateSummary(appProfile, best, evaluatedList);

    return AppSuitabilityReport(
      appProfile: appProfile,
      bestCandidate: best,
      rankings: evaluatedList,
      summary: summary,
    );
  }

  CandidateSuitability _evaluateCandidate(
    NetworkSnapshot candidate,
    AppProfile appProfile,
    CriterionWeights weights,
  ) {
    final sla = appProfile.sla;
    final violations = <String>[];

    // 1. Evaluasi Throughput (Data Rate)
    double rateScore;
    if (candidate.dataRateMbps < sla.minDataRateMbps) {
      rateScore = 0.0;
      violations.add(
        'Throughput (${candidate.dataRateMbps.toStringAsFixed(1)} Mbps) di bawah batas minimum (${sla.minDataRateMbps} Mbps)',
      );
    } else if (candidate.dataRateMbps >= sla.targetDataRateMbps) {
      rateScore = 1.0;
    } else {
      final denominator = sla.targetDataRateMbps - sla.minDataRateMbps;
      rateScore = denominator > 0
          ? (candidate.dataRateMbps - sla.minDataRateMbps) / denominator
          : 1.0;
    }

    // 2. Evaluasi Latensi (Delay)
    double delayScore;
    if (candidate.delayMs <= sla.targetDelayMs) {
      delayScore = 1.0;
    } else if (candidate.delayMs > sla.maxDelayMs) {
      delayScore = 0.0;
      violations.add(
        'Latensi (${candidate.delayMs.toStringAsFixed(1)} ms) melampaui batas toleransi (${sla.maxDelayMs} ms)',
      );
    } else {
      final denominator = sla.maxDelayMs - sla.targetDelayMs;
      delayScore = denominator > 0
          ? (sla.maxDelayMs - candidate.delayMs) / denominator
          : 1.0;
    }

    // 3. Evaluasi BER (Log-scale)
    double berScore;
    final candidateBer = math.max(1e-12, candidate.ber);
    final maxBer = math.max(1e-12, sla.maxBer);
    final targetBer = math.max(1e-12, sla.targetBer);

    if (candidateBer <= targetBer) {
      berScore = 1.0;
    } else if (candidateBer > maxBer) {
      berScore = 0.0;
      violations.add(
        'Packet Loss / BER (${candidate.ber.toStringAsExponential(1)}) di atas batas aman (${sla.maxBer.toStringAsExponential(1)})',
      );
    } else {
      final logCandidate = -math.log(candidateBer) / math.ln10;
      final logMax = -math.log(maxBer) / math.ln10;
      final logTarget = -math.log(targetBer) / math.ln10;
      final denominator = logTarget - logMax;
      berScore = denominator > 0 ? (logCandidate - logMax) / denominator : 1.0;
    }

    // Kombinasi Terbobot AHP
    double rawScore = (weights.dataRate * rateScore +
            weights.delay * delayScore +
            weights.ber * berScore) *
        100.0;

    final isViolated = violations.isNotEmpty;

    // Terapkan penalti jika melanggar SLA batas minimum
    if (isViolated) {
      rawScore = math.min(rawScore, 49.0);
    }

    final finalScore = rawScore.clamp(0.0, 100.0);

    SuitabilityLevel level;
    String statusLabel;
    if (finalScore >= 80.0 && !isViolated) {
      level = SuitabilityLevel.optimal;
      statusLabel = 'Sangat Direkomendasikan';
    } else if (finalScore >= 50.0 && !isViolated) {
      level = SuitabilityLevel.acceptable;
      statusLabel = 'Cukup Memadai';
    } else {
      level = SuitabilityLevel.violated;
      statusLabel = isViolated ? 'Melanggar SLA' : 'Kurang Sesuai';
    }

    return CandidateSuitability(
      candidate: candidate,
      suitabilityScore: finalScore,
      dataRateScore: rateScore.clamp(0.0, 1.0),
      delayScore: delayScore.clamp(0.0, 1.0),
      berScore: berScore.clamp(0.0, 1.0),
      isSlaViolated: isViolated,
      violations: violations,
      level: level,
      statusLabel: statusLabel,
    );
  }

  String _generateSummary(
    AppProfile appProfile,
    CandidateSuitability best,
    List<CandidateSuitability> all,
  ) {
    final techName = best.candidate.technology.name.toUpperCase();
    final id = best.candidate.id;
    final scoreStr = best.suitabilityScore.toStringAsFixed(0);

    if (best.level == SuitabilityLevel.optimal) {
      return '$techName ($id) adalah pilihan terbaik untuk ${appProfile.name} dengan skor kesesuaian $scoreStr%. Kualitas throughput (${best.candidate.dataRateMbps.toStringAsFixed(1)} Mbps) dan latensi (${best.candidate.delayMs.toStringAsFixed(1)} ms) sangat memenuhi standar pengalaman pengguna.';
    } else if (best.level == SuitabilityLevel.acceptable) {
      return '$techName ($id) cukup memadai untuk ${appProfile.name} ($scoreStr%), meskipun terdapat beberapa parameter yang belum mencapai target optimal.';
    } else {
      return 'Tidak ada jaringan yang memenuhi SLA ideal untuk ${appProfile.name}. $techName ($id) memiliki skor tertinggi ($scoreStr%), namun disarankan mencari jangkauan sinyal yang lebih baik.';
    }
  }
}
