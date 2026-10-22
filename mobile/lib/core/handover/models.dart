enum TrafficClass { conversational, streaming, interactive, background }

enum NetworkTechnology { lte, nr, wlan }

extension NetworkTechnologyDisplay on NetworkTechnology {
  /// Nama ringkas teknologi (misal: "4G", "5G", "Wi-Fi")
  String get shortName {
    switch (this) {
      case NetworkTechnology.lte:
        return '4G';
      case NetworkTechnology.nr:
        return '5G';
      case NetworkTechnology.wlan:
        return 'Wi-Fi';
    }
  }

  /// Nama tampilan ramah pengguna (misal: "4G", "5G", "Wi-Fi")
  String get displayName {
    switch (this) {
      case NetworkTechnology.lte:
        return '4G';
      case NetworkTechnology.nr:
        return '5G';
      case NetworkTechnology.wlan:
        return 'Wi-Fi';
    }
  }
}

/// Helper fungsi untuk memformat identifier jaringan menjadi nama tampilan yang ramah pengguna.
/// Menangani format standar ('4g_lte', '5g_nr', 'wifi') dan format lama ('lte_macro', 'nr_smallcell', 'wifi_ap').
String formatNetworkLabel(String? networkId) {
  if (networkId == null || networkId.trim().isEmpty) return '-';
  final lower = networkId.trim().toLowerCase();
  if (lower == '5g' || lower == '5g_nr' || lower == 'nr_smallcell' || lower == 'nr') {
    return '5G';
  }
  if (lower == '4g' || lower == '4g_lte' || lower == 'lte_macro' || lower == 'lte') {
    return '4G';
  }
  if (lower == 'wifi' || lower == 'wifi_ap' || lower == 'wlan') {
    return 'Wi-Fi';
  }
  return networkId;
}

enum ParameterSource { estimated, measured, synthetic }

double unitInterval(double value) => value.clamp(0.0, 1.0).toDouble();

void requireFinite(
  String name,
  double value, {
  double? minimum,
  double? maximum,
}) {
  if (!value.isFinite ||
      (minimum != null && value < minimum) ||
      (maximum != null && value > maximum)) {
    throw ArgumentError.value(value, name, 'Nilai di luar rentang yang valid');
  }
}

/// BER is a ratio, data rate is Mbps, delay is ms, RSS is dBm.
class NetworkSnapshot {
  final String id;
  final NetworkTechnology technology;
  final double rssDbm;
  final double dataRateMbps;
  final double delayMs;
  final double ber;
  final bool available;
  final ParameterSource parameterSource;

  NetworkSnapshot({
    required this.id,
    required this.technology,
    required this.rssDbm,
    required this.dataRateMbps,
    required this.delayMs,
    required this.ber,
    this.available = true,
    this.parameterSource = ParameterSource.estimated,
  }) {
    if (id.trim().isEmpty)
      throw ArgumentError('ID jaringan tidak boleh kosong');
    requireFinite('rssDbm', rssDbm);
    requireFinite('dataRateMbps', dataRateMbps, minimum: 0);
    requireFinite('delayMs', delayMs, minimum: 0);
    requireFinite('ber', ber, minimum: 0, maximum: 1);
  }

  Map<String, Object> toJson() => {
    'id': id,
    'technology': technology.name,
    'rss_dbm': rssDbm,
    'data_rate_mbps': dataRateMbps,
    'delay_ms': delayMs,
    'ber': ber,
    'available': available,
    'parameter_source': parameterSource.name,
  };
}

extension NetworkSnapshotDisplay on NetworkSnapshot {
  /// Nama tampilan ramah pengguna (misal: "Wi-Fi", "5G NR", "4G LTE").
  String get displayName => formatNetworkLabel(id);
}

class NetworkRank {
  final String networkId;
  final double score;
  const NetworkRank(this.networkId, this.score);
  Map<String, Object> toJson() => {'network_id': networkId, 'score': score};
}

enum DecisionAction { stay, recommendSwitch, insufficientData }

enum DecisionReason {
  currentNetworkMissing,
  currentNetworkUnavailable,
  belowThreshold,
  currentNetworkBest,
  candidateSelected,
  hysteresis,
  waitingForDwell,
}

class DecisionResult {
  final DecisionAction action;
  final DecisionReason reason;
  final String currentNetworkId;
  final String? targetNetworkId;
  final TrafficClass trafficClass;
  final double velocityMps;
  final double? qosFactor;
  final double? handoverFactor;
  final double threshold;
  final List<NetworkRank> ranking;
  final List<NetworkRank> baselineTopsisRanking;
  final String? baselineTopsisNetworkId;
  final String? baselineRssNetworkId;
  final List<NetworkSnapshot> networks;

  DecisionResult({
    required this.action,
    required this.reason,
    required this.currentNetworkId,
    required this.trafficClass,
    required this.velocityMps,
    required this.threshold,
    required List<NetworkSnapshot> networks,
    this.targetNetworkId,
    this.qosFactor,
    this.handoverFactor,
    List<NetworkRank> ranking = const [],
    List<NetworkRank> baselineTopsisRanking = const [],
    this.baselineTopsisNetworkId,
    this.baselineRssNetworkId,
  }) : networks = List.unmodifiable(networks),
       ranking = List.unmodifiable(ranking),
       baselineTopsisRanking = List.unmodifiable(baselineTopsisRanking);

  DecisionResult stayBecause(DecisionReason reason) => DecisionResult(
    action: DecisionAction.stay,
    reason: reason,
    currentNetworkId: currentNetworkId,
    targetNetworkId: currentNetworkId,
    trafficClass: trafficClass,
    velocityMps: velocityMps,
    qosFactor: qosFactor,
    handoverFactor: handoverFactor,
    threshold: threshold,
    ranking: ranking,
    baselineTopsisRanking: baselineTopsisRanking,
    baselineTopsisNetworkId: baselineTopsisNetworkId,
    baselineRssNetworkId: baselineRssNetworkId,
    networks: networks,
  );

  Map<String, Object?> toJson() => {
    'action': action.name,
    'reason': reason.name,
    'current_network_id': currentNetworkId,
    'target_network_id': targetNetworkId,
    'traffic_class': trafficClass.name,
    'velocity_mps': velocityMps,
    'qos_factor': qosFactor,
    'handover_factor': handoverFactor,
    'threshold': threshold,
    'ranking': ranking.map((r) => r.toJson()).toList(),
    'baseline_topsis_ranking': baselineTopsisRanking
        .map((r) => r.toJson())
        .toList(),
    'baseline_topsis_network_id': baselineTopsisNetworkId,
    'baseline_rss_network_id': baselineRssNetworkId,
    'networks': networks.map((n) => n.toJson()).toList(),
  };
}
