import 'dart:convert';

import '../../lib/core/handover/handover.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void near(double actual, double expected, [double tolerance = 1e-6]) =>
    check((actual - expected).abs() <= tolerance, '$actual != $expected');

void rejects(void Function() operation) {
  try {
    operation();
  } on ArgumentError {
    return;
  }
  throw StateError('Input invalid tidak ditolak');
}

void checkMonotoneSurface(
  double Function(List<double>) evaluate,
  List<bool> increasing,
) {
  const segments = 20;
  const count = segments + 1;
  const strides = [count * count, count, 1];
  final values = List<double>.filled(count * count * count, 0);
  for (var a = 0; a < count; a++) {
    for (var b = 0; b < count; b++) {
      for (var c = 0; c < count; c++) {
        final coordinate = [a, b, c];
        final index = a * strides[0] + b * strides[1] + c;
        final value = evaluate([a / segments, b / segments, c / segments]);
        check(
          value.isFinite && value >= 0 && value <= 1,
          'Invalid fuzzy output',
        );
        values[index] = value;
        for (var axis = 0; axis < 3; axis++) {
          if (coordinate[axis] == 0) continue;
          final previous = values[index - strides[axis]];
          check(
            increasing[axis]
                ? value >= previous - 1e-12
                : value <= previous + 1e-12,
            'Non-monotone axis=$axis at $coordinate: $previous -> $value',
          );
        }
      }
    }
  }
}

NetworkSnapshot network(
  String id, {
  double rate = 10,
  double delay = 10,
  double ber = 1e-7,
  double rss = -35,
  bool available = true,
  NetworkTechnology technology = NetworkTechnology.wlan,
}) => NetworkSnapshot(
  id: id,
  technology: technology,
  rssDbm: rss,
  dataRateMbps: rate,
  delayMs: delay,
  ber: ber,
  available: available,
  parameterSource: ParameterSource.synthetic,
);

void handoverCases(void Function(String, void Function()) test) {
  final config = HandoverConfiguration();
  final qos = QosCalculator(config);
  final fuzzy = HandoverFuzzyEvaluator();
  final topsis = TopsisRanker();
  final engine = HandoverDecisionEngine();
  final equalWeights = CriterionWeights(1, 1, 1);
  final bad = network('wifi', rate: 0, delay: 1000, ber: .01, rss: -90);
  final good = network('cell', technology: NetworkTechnology.lte, rss: -55);
  DecisionResult evaluate(
    List<NetworkSnapshot> networks, {
    String current = 'wifi',
    double speed = 1.4,
  }) => engine.evaluate(
    trafficClass: TrafficClass.conversational,
    velocityMps: speed,
    currentNetworkId: current,
    networks: networks,
  );

  test('Runtime validation rejects invalid units and non-finite values', () {
    for (final invalid in [double.nan, double.infinity, -.1]) {
      rejects(() => network('a', rate: invalid));
      rejects(() => network('a', delay: invalid));
      rejects(() => network('a', ber: invalid));
    }
    rejects(() => network('a', ber: 1.1));
    rejects(() => network(' ', rate: 1));
    rejects(() => network('a', rss: double.nan));
    rejects(() => evaluate([good], speed: -1));
  });
  test(
    'Weights normalize and reject zero totals, negative and missing config',
    () {
      near(equalWeights.dataRate, 1 / 3);
      rejects(() => CriterionWeights(0, 0, 0));
      rejects(() => CriterionWeights(-1, 1, 1));
      rejects(() => HandoverConfiguration(thresholds: {}));
      rejects(() => HandoverConfiguration(rssRanges: {}));
      for (final weights in config.weights.values) {
        near(weights.values.reduce((a, b) => a + b), 1);
      }
    },
  );
  test('Table 1 conversion preserves Mbps and BER ratio', () {
    final conversation = config.requirements[TrafficClass.conversational]!;
    near(conversation.rateHighMbps, 1.920);
    near(conversation.berScale, .0001);
    near(config.requirements[TrafficClass.background]!.berScale, .00001);
  });
  test('Technology-specific RSS maps equivalent signal quality equally', () {
    near(config.normalizedRss(network('wifi', rss: -60)), .5);
    near(
      config.normalizedRss(
        network('lte', rss: -85, technology: NetworkTechnology.lte),
      ),
      .5,
    );
    near(
      config.normalizedRss(
        network('nr', rss: -75, technology: NetworkTechnology.nr),
      ),
      .5,
    );
    near(config.normalizedRss(network('weak', rss: -150)), 0);
    near(config.normalizedRss(network('strong', rss: -10)), 1);
  });
  test('Gaussian membership matches exp(-0.5) one sigma from center', () {
    final mf = GaussianMembership(.5, .1);
    near(mf.degree(.5), 1);
    near(mf.degree(.6), .6065306597);
    rejects(() => GaussianMembership(.5, 0));
  });
  test('Mamdani symmetric output has centroid 0.5', () {
    final system = MamdaniSystem(
      inputs: [
        [GaussianMembership(.5, .2)],
      ],
      outputs: [GaussianMembership(.5, .2)],
      rules: [
        FuzzyRule([0], 0),
      ],
    );
    near(system.evaluate([.5]), .5);
    rejects(() => system.evaluate([double.nan]));
    rejects(() => system.evaluate([]));
    rejects(
      () => MamdaniSystem(
        inputs: [
          [GaussianMembership(.5, .2)],
        ],
        outputs: [GaussianMembership(.5, .2)],
        rules: [
          FuzzyRule([2], 0),
        ],
      ),
    );
  });
  for (final traffic in TrafficClass.values) {
    test(
      '${traffic.name}: good and poor QoS produce separated bounded outputs',
      () {
        final high = qos.evaluate(good, traffic);
        final low = qos.evaluate(bad, traffic);
        check(high > .75 && low < .25, 'QoS good=$high poor=$low');
        check(high > low, 'QoS direction inverted');
      },
    );
    test('${traffic.name}: improving each QoS criterion never reduces QoS', () {
      final r = config.requirements[traffic]!;
      final mid = (r.rateLowMbps + r.rateHighMbps) / 2;
      final original = network(
        'a',
        rate: mid,
        delay: r.delayScaleMs / 2,
        ber: r.berScale / 2,
      );
      final base = qos.evaluate(original, traffic);
      for (final improved in [
        network(
          'a',
          rate: r.rateHighMbps,
          delay: original.delayMs,
          ber: original.ber,
        ),
        network('a', rate: mid, delay: 0, ber: original.ber),
        network('a', rate: mid, delay: original.delayMs, ber: 0),
      ])
        check(qos.evaluate(improved, traffic) >= base - 1e-9, 'QoS decreases');
    });
  }
  test('Traffic class changes QoS under delay and BER constraints', () {
    final input = network('a', rate: 10, delay: 100, ber: 1e-8);
    check(
      qos.evaluate(input, TrafficClass.streaming) >
          qos.evaluate(input, TrafficClass.conversational),
      'Class priority ignored',
    );
  });
  test('HF reflects poor QoS, weak RSS and movement', () {
    final low = fuzzy.evaluate(qosFactor: 1, normalizedRss: 1, velocityMps: 0);
    final high = fuzzy.evaluate(
      qosFactor: 0,
      normalizedRss: 0,
      velocityMps: 100 / 3.6,
    );
    check(low < .2 && high > .8, 'HF low=$low high=$high');
    final fast = fuzzy.evaluate(
      qosFactor: .3,
      normalizedRss: .3,
      velocityMps: 100 / 3.6,
    );
    final slow = fuzzy.evaluate(
      qosFactor: .3,
      normalizedRss: .3,
      velocityMps: 0,
    );
    check(fast >= slow, 'Speed direction inverted');
    near(
      fuzzy.evaluate(qosFactor: .3, normalizedRss: .3, velocityMps: 1000),
      fast,
    );
  });
  test('Threshold comparison is strictly greater than 0.7', () {
    check(!HandoverDecisionEngine.shouldInitiate(.7, .7), 'Equality must stay');
    check(
      HandoverDecisionEngine.shouldInitiate(.70001, .7),
      'Above threshold must initiate',
    );
    rejects(() => HandoverDecisionEngine.shouldInitiate(double.nan, .7));
  });
  test(
    'Audit regression: improving QoS or RSS cannot activate the HF gate',
    () {
      for (final values in [
        [.22, .23, .05, 60.0],
        [.22, .23, .05, 70.0],
      ]) {
        final before = fuzzy.evaluate(
          qosFactor: values[0],
          normalizedRss: values[2],
          velocityMps: values[3] / 3.6,
        );
        final after = fuzzy.evaluate(
          qosFactor: values[1],
          normalizedRss: values[2],
          velocityMps: values[3] / 3.6,
        );
        check(after <= before + 1e-12, 'Improved QoS raised HF');
        check(before > .7 || after <= .7, 'Improved QoS activated gate');
      }
      for (final values in [
        [0.0, .84, .85, 30.0],
        [.35, .27, .28, 100.0],
      ]) {
        final before = fuzzy.evaluate(
          qosFactor: values[0],
          normalizedRss: values[1],
          velocityMps: values[3] / 3.6,
        );
        final after = fuzzy.evaluate(
          qosFactor: values[0],
          normalizedRss: values[2],
          velocityMps: values[3] / 3.6,
        );
        check(after <= before + 1e-12, 'Improved RSS raised HF');
        check(before > .7 || after <= .7, 'Improved RSS activated gate');
      }
    },
  );
  test('HF is monotone on all three axes across the full normalized cube', () {
    checkMonotoneSurface(
      (values) => fuzzy.evaluate(
        qosFactor: values[0],
        normalizedRss: values[1],
        velocityMps: values[2] * 100 / 3.6,
      ),
      [false, false, true],
    );
  });
  for (final traffic in TrafficClass.values) {
    test(
      '${traffic.name}: QoS is monotone across the full normalized cube',
      () {
        final r = config.requirements[traffic]!;
        checkMonotoneSurface(
          (v) => qos.evaluate(
            network(
              'grid',
              rate: r.rateLowMbps + v[0] * (r.rateHighMbps - r.rateLowMbps),
              delay: v[1] * r.delayScaleMs,
              ber: v[2] * r.berScale,
            ),
            traffic,
          ),
          [true, false, false],
        );
      },
    );
  }
  test(
    'HF rule base includes all combinations and explicit paper examples',
    () {
      check(fuzzy.system.rules.length == 48, 'Incomplete HF rules');
      final poorWeakHigh = fuzzy.system.rules.firstWhere(
        (r) =>
            r.antecedents[0] == 0 &&
            r.antecedents[1] == 0 &&
            r.antecedents[2] == 2,
      );
      check(poorWeakHigh.consequent == 3, 'Paper High example changed');
      final excellentStrongLow = fuzzy.system.rules.firstWhere(
        (r) =>
            r.antecedents[0] == 3 &&
            r.antecedents[1] == 2 &&
            r.antecedents[2] == 0,
      );
      check(
        excellentStrongLow.consequent == 0,
        'Paper Very Low example changed',
      );
    },
  );
  test(
    'Class threshold configuration changes the gate without changing ranking',
    () {
      final custom = HandoverDecisionEngine(
        configuration: HandoverConfiguration(
          thresholds: {for (final c in TrafficClass.values) c: 1},
        ),
      );
      final result = custom.evaluate(
        trafficClass: TrafficClass.conversational,
        velocityMps: 1.4,
        currentNetworkId: 'wifi',
        networks: [bad, good],
      );
      check(
        result.action == DecisionAction.stay && result.threshold == 1,
        'Configured threshold ignored',
      );
      check(
        result.baselineTopsisNetworkId == 'cell',
        'Threshold affected baseline',
      );
    },
  );
  test('TOPSIS yields ideal=1 and worst=0 for a dominating candidate', () {
    final ranking = topsis.rank([
      network('best', rate: 100, delay: 1, ber: 1e-8),
      network('worst', rate: 1, delay: 100, ber: 1e-3),
    ], equalWeights);
    check(ranking.first.networkId == 'best', 'Wrong best');
    near(ranking.first.score, 1);
    near(ranking.last.score, 0);
  });
  test('TOPSIS agrees with independent hand-calculated two-criterion case', () {
    final ranking = topsis.rank([
      network('a', rate: 3, delay: 4, ber: 0),
      network('b', rate: 4, delay: 3, ber: 0),
    ], CriterionWeights(1, 1, 0));
    // Norms are 5; b has both ideal coordinates (0.4,0.3).
    near(ranking.first.score, 1);
    check(ranking.first.networkId == 'b', 'Cost criterion inverted');
  });
  test('TOPSIS tradeoff ranking changes with criterion weights', () {
    final input = [
      network('fast', rate: 100, delay: 100, ber: 1e-4),
      network('responsive', rate: 10, delay: 1, ber: 1e-4),
    ];
    check(
      topsis.rank(input, CriterionWeights(9, 1, 0)).first.networkId == 'fast',
      'Rate weight ignored',
    );
    check(
      topsis.rank(input, CriterionWeights(1, 9, 0)).first.networkId ==
          'responsive',
      'Delay weight ignored',
    );
  });
  test('TOPSIS handles identical, zero, single and unavailable candidates', () {
    near(topsis.rank([network('a')], equalWeights).single.score, .5);
    final zero = topsis.rank(
      [
        network('a', rate: 0, delay: 0, ber: 0),
        network('b', rate: 0, delay: 0, ber: 0),
      ],
      equalWeights,
      preferredNetworkId: 'b',
    );
    near(zero.first.score, .5);
    check(zero.first.networkId == 'b', 'Tie should retain active network');
    check(
      topsis.rank([network('a', available: false)], equalWeights).isEmpty,
      'Unavailable candidate included',
    );
    rejects(() => topsis.rank([network('a'), network('a')], equalWeights));
  });
  test('TOPSIS preserves scores under uniform unit rescaling', () {
    final original = topsis.rank([
      network('a', rate: 1, delay: 30),
      network('b', rate: 3, delay: 10),
    ], equalWeights);
    final scaled = topsis.rank([
      network('a', rate: 1000, delay: 30000),
      network('b', rate: 3000, delay: 10000),
    ], equalWeights);
    near(original.first.score, scaled.first.score);
    check(
      original.first.networkId == scaled.first.networkId,
      'Units change winner',
    );
  });
  test('TOPSIS safely normalizes very large finite values', () {
    final ranks = topsis.rank([
      network('a', rate: 1e300, delay: 1e300),
      network('b', rate: 5e299, delay: 5e299),
    ], equalWeights);
    check(ranks.every((r) => r.score.isFinite), 'Overflow in TOPSIS');
  });
  test(
    'Missing active network returns insufficient data without fabricated HF',
    () {
      final result = evaluate([good]);
      check(
        result.action == DecisionAction.insufficientData &&
            result.handoverFactor == null,
        'Fabricated active network',
      );
      check(
        result.baselineTopsisNetworkId == 'cell',
        'Baseline should still be available',
      );
      check(
        evaluate([]).baselineRssNetworkId == null,
        'Empty baseline fabricated',
      );
    },
  );
  test(
    'Unavailable active network is explicit and never silently replaced',
    () {
      final result = evaluate([network('wifi', available: false), good]);
      check(
        result.reason == DecisionReason.currentNetworkUnavailable,
        'Unavailable active ignored',
      );
    },
  );
  test('Good active connection stays while baseline runs independently', () {
    final result = evaluate([
      network('wifi', rate: 10),
      network('cell', rate: 100),
    ]);
    check(
      result.action == DecisionAction.stay && result.ranking.isEmpty,
      'Fuzzy gate ignored',
    );
    check(result.baselineTopsisNetworkId == 'cell', 'Baseline not calculated');
  });
  test('Poor active connection recommends the dominating available target', () {
    final result = evaluate([bad, good]);
    check(
      result.action == DecisionAction.recommendSwitch &&
          result.targetNetworkId == 'cell',
      'No switch: ${result.toJson()}',
    );
    check(result.handoverFactor! > result.threshold, 'Switch without HF gate');
    check(result.currentNetworkId == 'wifi', 'OS network was changed');
  });
  test('HF above threshold still stays if current network is TOPSIS best', () {
    final result = evaluate([bad]);
    check(
      result.handoverFactor! > .7 &&
          result.reason == DecisionReason.currentNetworkBest,
      'Single active must stay',
    );
  });
  test('RSS baseline compares normalized quality rather than raw dBm', () {
    final result = evaluate([
      network('wifi', rss: -70),
      network('cell', rss: -80, technology: NetworkTechnology.lte),
    ]);
    check(
      result.baselineRssNetworkId == 'cell',
      'Raw RSS used across technologies',
    );
  });
  test(
    'Result serialization includes provenance and cannot mutate input lists',
    () {
      final input = [bad, good];
      final result = evaluate(input);
      input.clear();
      check(result.networks.length == 2, 'Mutable input retained');
      final json =
          jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>;
      check(
        json['networks'][0]['parameter_source'] == 'synthetic',
        'Provenance missing',
      );
    },
  );
  test(
    'Dwell uses elapsed time, retains OS active network, resets on stay',
    () {
      final stabilizer = RecommendationStabilizer();
      final raw = evaluate([bad, good]);
      check(
        stabilizer.apply(raw, elapsed: Duration.zero).reason ==
            DecisionReason.waitingForDwell,
        'No dwell',
      );
      check(
        stabilizer.apply(raw, elapsed: const Duration(seconds: 2)).action ==
            DecisionAction.stay,
        'Early dwell release',
      );
      check(
        stabilizer.apply(raw, elapsed: const Duration(seconds: 3)).action ==
            DecisionAction.recommendSwitch,
        'Dwell never releases',
      );
      stabilizer.apply(
        evaluate([network('wifi'), good]),
        elapsed: const Duration(seconds: 4),
      );
      check(
        stabilizer.apply(raw, elapsed: const Duration(seconds: 5)).reason ==
            DecisionReason.waitingForDwell,
        'Pending not cleared',
      );
      rejects(() => stabilizer.apply(raw, elapsed: const Duration(seconds: 1)));
      stabilizer.reset();
      stabilizer.apply(raw, elapsed: Duration.zero);
    },
  );
  test('Hysteresis can block a target even after fuzzy initiation', () {
    final ranks = [
      const NetworkRank('wifi', .48),
      const NetworkRank('cell', .52),
    ];
    final raw = DecisionResult(
      action: DecisionAction.recommendSwitch,
      reason: DecisionReason.candidateSelected,
      currentNetworkId: 'wifi',
      targetNetworkId: 'cell',
      trafficClass: TrafficClass.streaming,
      velocityMps: 0,
      threshold: .7,
      ranking: ranks,
      networks: [bad, good],
    );
    check(
      RecommendationStabilizer().apply(raw, elapsed: Duration.zero).reason ==
          DecisionReason.hysteresis,
      'Score margin ignored',
    );
  });
}
