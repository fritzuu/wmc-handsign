import 'configuration.dart';
import 'mamdani.dart';
import 'models.dart';

class QosCalculator {
  static final _defaultSystems = <(double, double, double), MamdaniSystem>{};
  static final _surfaceCache = Expando<MonotoneMamdaniSurface>();
  final HandoverConfiguration configuration;
  final Map<TrafficClass, MamdaniSystem> _systems;
  late final Map<TrafficClass, MonotoneMamdaniSurface> _surfaces;

  QosCalculator(this.configuration, {Map<TrafficClass, MamdaniSystem>? systems})
    : _systems = Map.unmodifiable(
        systems ??
            {
              for (final c in TrafficClass.values)
                c: _defaultSystem(configuration.weights[c]!),
            },
      ) {
    for (final c in TrafficClass.values) {
      final system = _systems[c];
      if (system == null ||
          system.inputs.length != 3 ||
          system.outputs.length != 4) {
        throw ArgumentError(
          'FIS QoS ${c.name} harus memiliki 3 input dan 4 output',
        );
      }
    }
    _surfaces = Map.unmodifiable({
      for (final c in TrafficClass.values)
        c: _surfaceCache[_systems[c]!] ??= MonotoneMamdaniSurface(
          _systems[c]!,
          increasing: [true, false, false],
        ),
    });
  }

  static MamdaniSystem _defaultSystem(CriterionWeights weights) =>
      _defaultSystems.putIfAbsent((
        weights.dataRate,
        weights.delay,
        weights.ber,
      ), () => _build(weights));

  // Complete 27-rule reconstruction. AHP priorities choose rule consequents;
  // the output is calibrated Mamdani inference, not a weighted input sum.
  static MamdaniSystem _build(CriterionWeights weights) {
    final rules = <FuzzyRule>[];
    for (var rate = 0; rate < 3; rate++) {
      for (var delay = 0; delay < 3; delay++) {
        for (var ber = 0; ber < 3; ber++) {
          final quality =
              weights.dataRate * rate / 2 +
              weights.delay * (1 - delay / 2) +
              weights.ber * (1 - ber / 2);
          rules.add(FuzzyRule([rate, delay, ber], (quality * 3).round()));
        }
      }
    }
    return MamdaniSystem(
      inputs: [for (var i = 0; i < 3; i++) evenlySpacedMemberships(3)],
      outputs: evenlySpacedMemberships(4),
      rules: rules,
    );
  }

  double evaluate(NetworkSnapshot network, TrafficClass trafficClass) {
    final r = configuration.requirements[trafficClass]!;
    return _surfaces[trafficClass]!.evaluate([
      unitInterval(
        (network.dataRateMbps - r.rateLowMbps) /
            (r.rateHighMbps - r.rateLowMbps),
      ),
      unitInterval(network.delayMs / r.delayScaleMs),
      unitInterval(network.ber / r.berScale),
    ]);
  }
}

class HandoverFuzzyEvaluator {
  static final _defaultSystem = _build();
  static final _surfaceCache = Expando<MonotoneMamdaniSurface>();
  final MamdaniSystem system;
  late final MonotoneMamdaniSurface _surface;
  HandoverFuzzyEvaluator({MamdaniSystem? system})
    : system = system ?? _defaultSystem {
    if (this.system.inputs.length != 3 || this.system.outputs.length != 5) {
      throw ArgumentError('FIS HF harus memiliki 3 input dan 5 output');
    }
    _surface = _surfaceCache[this.system] ??= MonotoneMamdaniSurface(
      this.system,
      increasing: [false, false, true],
      lowerEnvelope: false,
    );
  }

  // Complete 48-rule reconstruction; high QoS/strong RSS/low speed lowers HF.
  static MamdaniSystem _build() {
    final rules = <FuzzyRule>[];
    for (var qos = 0; qos < 4; qos++) {
      for (var rss = 0; rss < 3; rss++) {
        for (var speed = 0; speed < 4; speed++) {
          final urgency =
              .6 * (1 - qos / 3) + .3 * (1 - rss / 2) + .1 * speed / 3;
          // Reserve Very High for the worst combination. Poor/Weak/High
          // maps to High, matching the explicit example in section 3.2.1.
          final consequent = urgency > .975
              ? 4
              : urgency >= .625
              ? 3
              : urgency >= .375
              ? 2
              : urgency >= .125
              ? 1
              : 0;
          rules.add(FuzzyRule([qos, rss, speed], consequent));
        }
      }
    }
    return MamdaniSystem(
      inputs: [
        evenlySpacedMemberships(4),
        evenlySpacedMemberships(3),
        evenlySpacedMemberships(4),
      ],
      outputs: evenlySpacedMemberships(5),
      rules: rules,
    );
  }

  double evaluate({
    required double qosFactor,
    required double normalizedRss,
    required double velocityMps,
  }) {
    requireFinite('velocityMps', velocityMps, minimum: 0);
    // Paper domain: 0-100 km/h; faster movement saturates at the highest set.
    return _surface.evaluate([
      qosFactor,
      normalizedRss,
      unitInterval(velocityMps * 3.6 / 100),
    ]);
  }
}
