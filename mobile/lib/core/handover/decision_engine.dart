import 'configuration.dart';
import 'fuzzy.dart';
import 'models.dart';
import 'topsis.dart';

class HandoverDecisionEngine {
  final HandoverConfiguration configuration;
  final QosCalculator qos;
  final HandoverFuzzyEvaluator fuzzy;
  final TopsisRanker topsis;

  factory HandoverDecisionEngine({HandoverConfiguration? configuration}) {
    final config = configuration ?? HandoverConfiguration();
    return HandoverDecisionEngine.withModules(
      configuration: config,
      qos: QosCalculator(config),
      fuzzy: HandoverFuzzyEvaluator(),
      topsis: TopsisRanker(),
    );
  }

  HandoverDecisionEngine.withModules({
    required this.configuration,
    required this.qos,
    required this.fuzzy,
    required this.topsis,
  }) {
    if (!identical(qos.configuration, configuration)) {
      throw ArgumentError(
        'QoS dan mesin keputusan harus memakai konfigurasi yang sama',
      );
    }
  }

  DecisionResult evaluate({
    required TrafficClass trafficClass,
    required double velocityMps,
    required String currentNetworkId,
    required List<NetworkSnapshot> networks,
    HandoverSensitivity sensitivity = HandoverSensitivity.balanced,
  }) {
    requireFinite('velocityMps', velocityMps, minimum: 0);
    if (currentNetworkId.trim().isEmpty) {
      throw ArgumentError('Jaringan aktif belum ditentukan');
    }
    final input = List<NetworkSnapshot>.unmodifiable(networks);
    final baseline = topsis.rank(
      input,
      configuration.weights[trafficClass]!,
      preferredNetworkId: currentNetworkId,
    );
    final rssCandidates = input.where((n) => n.available).toList()
      ..sort((a, b) {
        if (a.id == b.id) return 0;
        final order = configuration
            .normalizedRss(b)
            .compareTo(configuration.normalizedRss(a));
        if (order != 0) return order;
        if (a.id == currentNetworkId) return -1;
        if (b.id == currentNetworkId) return 1;
        return a.id.compareTo(b.id);
      });
    final current = input.where((n) => n.id == currentNetworkId).firstOrNull;
    final defaultThreshold = configuration.thresholds[trafficClass]!;

    // Adaptasi threshold inisiasi berdasarkan tingkat sensitivitas yang dipilih
    // Catatan: Jika konfigurasi secara eksplisit diset ke threshold ekstrem (misal 1.0 pada unit test),
    // hormati batas konfigurasi tersebut.
    var effectiveThreshold = defaultThreshold;
    if (defaultThreshold < 0.99) {
      if (sensitivity == HandoverSensitivity.balanced) {
        final normRss = current != null ? configuration.normalizedRss(current) : 1.0;
        if (normRss < 0.35) {
          effectiveThreshold = (defaultThreshold * 0.70).clamp(0.28, 1.0);
        }
      } else if (sensitivity == HandoverSensitivity.aggressive) {
        effectiveThreshold = (defaultThreshold * 0.50).clamp(0.20, 1.0);
      }
    }

    DecisionResult result(
      DecisionAction action,
      DecisionReason reason, {
      String? target,
      double? qosFactor,
      double? hf,
      List<NetworkRank> ranking = const [],
    }) => DecisionResult(
      action: action,
      reason: reason,
      currentNetworkId: currentNetworkId,
      targetNetworkId: target,
      trafficClass: trafficClass,
      velocityMps: velocityMps,
      qosFactor: qosFactor,
      handoverFactor: hf,
      threshold: effectiveThreshold,
      ranking: ranking,
      baselineTopsisRanking: baseline,
      baselineTopsisNetworkId: baseline.isEmpty
          ? null
          : baseline.first.networkId,
      baselineRssNetworkId: rssCandidates.isEmpty
          ? null
          : rssCandidates.first.id,
      networks: input,
    );
    if (current == null || !current.available) {
      return result(
        DecisionAction.insufficientData,
        current == null
            ? DecisionReason.currentNetworkMissing
            : DecisionReason.currentNetworkUnavailable,
      );
    }
    final quality = qos.evaluate(current, trafficClass);
    final normRss = configuration.normalizedRss(current);
    final hf = fuzzy.evaluate(
      qosFactor: quality,
      normalizedRss: normRss,
      velocityMps: velocityMps,
    );

    // Opportunistic Handover Check:
    // Jika sinyal saat ini lemah (<= 2 bar / normRss < 0.38) dan ada kandidat alternatif
    // dengan skor TOPSIS jauh lebih superior (selisih score >= 0.20 pada mode seimbang / 0.12 pada agresif),
    // picu inisiasi handover tanpa tertahan deadlock gerbang HF!
    final bestCandidate = baseline.isNotEmpty ? baseline.first : null;
    final currentRank = baseline.where((r) => r.networkId == currentNetworkId).firstOrNull;
    final currentScore = currentRank?.score ?? 0.0;
    final bestScore = bestCandidate?.score ?? 0.0;
    final scoreGain = bestScore - currentScore;

    final isOpportunisticCandidate = defaultThreshold < 0.99 &&
        bestCandidate != null &&
        bestCandidate.networkId != currentNetworkId &&
        normRss < 0.38 &&
        ((sensitivity == HandoverSensitivity.aggressive && scoreGain >= 0.12) ||
         (sensitivity == HandoverSensitivity.balanced && scoreGain >= 0.20));

    final meetsHf = shouldInitiate(hf, effectiveThreshold);

    if (!meetsHf && !isOpportunisticCandidate) {
      return result(
        DecisionAction.stay,
        DecisionReason.belowThreshold,
        target: currentNetworkId,
        qosFactor: quality,
        hf: hf,
      );
    }
    final best = baseline.first.networkId;
    return result(
      best == currentNetworkId
          ? DecisionAction.stay
          : DecisionAction.recommendSwitch,
      best == currentNetworkId
          ? DecisionReason.currentNetworkBest
          : DecisionReason.candidateSelected,
      target: best,
      qosFactor: quality,
      hf: hf,
      ranking: baseline,
    );
  }

  static bool shouldInitiate(double hf, double threshold) {
    requireFinite('handoverFactor', hf, minimum: 0, maximum: 1);
    requireFinite('threshold', threshold, minimum: 0, maximum: 1);
    return hf > threshold;
  }
}

/// One instance per experiment. It never changes the OS current network.
class RecommendationStabilizer {
  final double minimumScoreGain;
  final Duration dwellTime;
  final bool enableEmergencyFastTrack;
  String? _pendingTarget;
  Duration? _pendingSince;
  Duration? _lastTime;
  String? _current;
  TrafficClass? _trafficClass;

  RecommendationStabilizer({
    this.minimumScoreGain = .05,
    this.dwellTime = const Duration(seconds: 3),
    this.enableEmergencyFastTrack = false,
  }) {
    requireFinite('minimumScoreGain', minimumScoreGain, minimum: 0, maximum: 1);
    if (dwellTime.isNegative)
      throw ArgumentError('Dwell time tidak boleh negatif');
  }

  DecisionResult apply(DecisionResult raw, {required Duration elapsed}) {
    if (elapsed.isNegative || (_lastTime != null && elapsed < _lastTime!)) {
      throw ArgumentError('Waktu eksperimen harus meningkat');
    }
    if (_current != raw.currentNetworkId || _trafficClass != raw.trafficClass) {
      _clearPending();
    }
    _current = raw.currentNetworkId;
    _trafficClass = raw.trafficClass;
    _lastTime = elapsed;
    if (raw.action != DecisionAction.recommendSwitch) {
      _clearPending();
      return raw;
    }
    final currentScore = raw.ranking
        .firstWhere((r) => r.networkId == raw.currentNetworkId)
        .score;
    final targetScore = raw.ranking
        .firstWhere((r) => r.networkId == raw.targetNetworkId)
        .score;
    if (targetScore - currentScore < minimumScoreGain) {
      _clearPending();
      return raw.stayBecause(DecisionReason.hysteresis);
    }
    if (_pendingTarget != raw.targetNetworkId) {
      _pendingTarget = raw.targetNetworkId;
      _pendingSince = elapsed;
    }

    // Fast-Track Emergency Bypass:
    // Jika sinyal saat ini sangat lemah (misal Wi-Fi RSS <= -82 dBm / 1-2 bar kritis),
    // pangkas dwell time menjadi 1 detik agar pengguna tidak mengalami blackout koneksi.
    final currentNet = raw.networks.where((n) => n.id == raw.currentNetworkId).firstOrNull;
    final isCriticalSignal = enableEmergencyFastTrack && currentNet != null && currentNet.rssDbm <= -82.0;
    final effectiveDwell = isCriticalSignal ? const Duration(seconds: 1) : dwellTime;

    if (elapsed - _pendingSince! < effectiveDwell)
      return raw.stayBecause(DecisionReason.waitingForDwell);
    return raw;
  }

  void _clearPending() {
    _pendingTarget = null;
    _pendingSince = null;
  }

  void reset() {
    _clearPending();
    _lastTime = null;
    _current = null;
    _trafficClass = null;
  }
}
