import 'models.dart';

class CriterionWeights {
  final double dataRate;
  final double delay;
  final double ber;

  CriterionWeights(double dataRate, double delay, double ber)
    : dataRate = _normalize(dataRate, dataRate, delay, ber),
      delay = _normalize(delay, dataRate, delay, ber),
      ber = _normalize(ber, dataRate, delay, ber);

  static double _normalize(
    double value,
    double rate,
    double delay,
    double ber,
  ) {
    for (final w in [rate, delay, ber]) {
      requireFinite('weight', w, minimum: 0);
    }
    final total = rate + delay + ber;
    if (!total.isFinite || total <= 0) {
      throw ArgumentError('Jumlah bobot harus positif dan finite');
    }
    return value / total;
  }

  List<double> get values => [dataRate, delay, ber];
}

/// Table 1 of Ndegwa (2023); rate bounds converted from kbps to Mbps,
/// BER percentages converted to ratios. These are fuzzy scaling bounds,
/// not hard acceptance limits for every modern application.
class QosRequirements {
  final double rateLowMbps;
  final double rateHighMbps;
  final double delayScaleMs;
  final double berScale;

  QosRequirements({
    required this.rateLowMbps,
    required this.rateHighMbps,
    required this.delayScaleMs,
    required this.berScale,
  }) {
    requireFinite('rateLowMbps', rateLowMbps, minimum: 0);
    requireFinite('rateHighMbps', rateHighMbps, minimum: 0);
    requireFinite('delayScaleMs', delayScaleMs, minimum: 0);
    requireFinite('berScale', berScale, minimum: 0, maximum: 1);
    if (rateHighMbps <= rateLowMbps || delayScaleMs == 0 || berScale == 0) {
      throw ArgumentError('Rentang QoS harus memiliki skala positif');
    }
  }
}

class RssRange {
  final double weakDbm;
  final double strongDbm;
  RssRange(this.weakDbm, this.strongDbm) {
    requireFinite('weakDbm', weakDbm);
    requireFinite('strongDbm', strongDbm);
    if (strongDbm <= weakDbm) throw ArgumentError('Rentang RSS tidak valid');
  }
  double normalize(double dbm) {
    requireFinite('rssDbm', dbm);
    return unitInterval((dbm - weakDbm) / (strongDbm - weakDbm));
  }
}

class HandoverConfiguration {
  final Map<TrafficClass, CriterionWeights> weights;
  final Map<TrafficClass, QosRequirements> requirements;
  final Map<TrafficClass, double> thresholds;
  final Map<NetworkTechnology, RssRange> rssRanges;

  HandoverConfiguration({
    Map<TrafficClass, CriterionWeights>? weights,
    Map<TrafficClass, QosRequirements>? requirements,
    Map<TrafficClass, double>? thresholds,
    Map<NetworkTechnology, RssRange>? rssRanges,
  }) : weights = Map.unmodifiable(weights ?? defaultWeights()),
       requirements = Map.unmodifiable(requirements ?? defaultRequirements()),
       thresholds = Map.unmodifiable(
         thresholds ?? {for (final c in TrafficClass.values) c: 0.7},
       ),
       rssRanges = Map.unmodifiable(
         rssRanges ??
             {
               NetworkTechnology.lte: RssRange(-120, -50),
               NetworkTechnology.nr: RssRange(-110, -40),
               NetworkTechnology.wlan: RssRange(-90, -30),
             },
       ) {
    for (final c in TrafficClass.values) {
      if (!this.weights.containsKey(c) ||
          !this.requirements.containsKey(c) ||
          !this.thresholds.containsKey(c)) {
        throw ArgumentError('Konfigurasi kelas ${c.name} belum lengkap');
      }
      requireFinite('threshold', this.thresholds[c]!, minimum: 0, maximum: 1);
    }
    for (final t in NetworkTechnology.values) {
      if (!this.rssRanges.containsKey(t))
        throw ArgumentError('Rentang RSS ${t.name} belum ada');
    }
  }

  double normalizedRss(NetworkSnapshot network) =>
      rssRanges[network.technology]!.normalize(network.rssDbm);

  // Table 2 AHP subset, renormalized for the PRD's three TOPSIS criteria.
  static Map<TrafficClass, CriterionWeights> defaultWeights() => {
    TrafficClass.conversational: CriterionWeights(.03996, .27983, .03996),
    TrafficClass.streaming: CriterionWeights(.2601, .0695, .0299),
    TrafficClass.interactive: CriterionWeights(.03946, .1111, .2091),
    TrafficClass.background: CriterionWeights(.05438, .01863, .2869),
  };

  /// Persyaratan SLA modern (YouTube HD/4K, Game Online, Video Call HD).
  /// Menggantikan batasan kuno 0.700 Mbps (700 kbps) dengan kebutuhan aplikasi riil modern.
  static Map<TrafficClass, QosRequirements> modernRequirements() => {
    TrafficClass.conversational: QosRequirements(
      rateLowMbps: 0.5,
      rateHighMbps: 4.0, // Video Call HD / Zoom / Meet
      delayScaleMs: 120,
      berScale: .0001,
    ),
    TrafficClass.streaming: QosRequirements(
      rateLowMbps: 2.0,
      rateHighMbps: 15.0, // YouTube 1080p/4K / Netflix
      delayScaleMs: 300,
      berScale: .0001,
    ),
    TrafficClass.interactive: QosRequirements(
      rateLowMbps: 0.5,
      rateHighMbps: 5.0, // Cloud Gaming / Mobile Legends / Browse
      delayScaleMs: 100,
      berScale: .00001,
    ),
    TrafficClass.background: QosRequirements(
      rateLowMbps: .01,
      rateHighMbps: 2.0, // Background Sync / Download
      delayScaleMs: 500,
      berScale: .00001,
    ),
  };

  static Map<TrafficClass, QosRequirements> defaultRequirements() => {
    TrafficClass.conversational: QosRequirements(
      rateLowMbps: .064,
      rateHighMbps: 1.920,
      delayScaleMs: 100,
      berScale: .0001,
    ),
    TrafficClass.streaming: QosRequirements(
      rateLowMbps: .005,
      rateHighMbps: .700,
      delayScaleMs: 400,
      berScale: .0001,
    ),
    TrafficClass.interactive: QosRequirements(
      rateLowMbps: .0282,
      rateHighMbps: .500,
      delayScaleMs: 200,
      berScale: .00001,
    ),
    TrafficClass.background: QosRequirements(
      rateLowMbps: .001,
      rateHighMbps: .024,
      delayScaleMs: 600,
      berScale: .00001,
    ),
  };
}
