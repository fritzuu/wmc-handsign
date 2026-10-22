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
    final threshold = configuration.thresholds[trafficClass]!;
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
      threshold: threshold,
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
    final hf = fuzzy.evaluate(
      qosFactor: quality,
      normalizedRss: configuration.normalizedRss(current),
      velocityMps: velocityMps,
    );
    if (!shouldInitiate(hf, threshold)) {
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
  String? _pendingTarget;
  Duration? _pendingSince;
  Duration? _lastTime;
  String? _current;
  TrafficClass? _trafficClass;

  RecommendationStabilizer({
    this.minimumScoreGain = .05,
    this.dwellTime = const Duration(seconds: 3),
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
    if (elapsed - _pendingSince! < dwellTime)
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
