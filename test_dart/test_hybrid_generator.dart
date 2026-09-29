/// Skrip pengujian mandiri untuk Hybrid Profile Generator.
///
/// Bisa dijalankan langsung tanpa Flutter:
///   dart run test/test_hybrid_generator.dart
///
/// Atau di-copy ke folder `test/` proyek Flutter nanti.
///
/// Menguji semua aspek generator sesuai FR-03 PRD v2.0:
/// 1. Quality factor dari RSS
/// 2. Estimasi Data Rate proporsional terhadap RSS
/// 3. Estimasi Delay berbanding terbalik terhadap RSS
/// 4. Estimasi BER berbanding terbalik (log-scale) terhadap RSS
/// 5. Ketersediaan jaringan
/// 6. Reprodusibilitas seed
/// 7. Batch estimation
/// 8. Validasi rentang output
/// 9. Skenario realistis (walk test simulasi)

// Karena ini standalone test script, kita import secara relatif
// Jika sudah dalam proyek Flutter, ganti dengan:
//   import 'package:wmc_handsign/core/models/technology_profile.dart';
//   import 'package:wmc_handsign/core/generator/hybrid_profile_generator.dart';

import 'dart:math';

// =====================================================================
// COPY DARI MODELS — untuk standalone test tanpa dependency
// (Di proyek Flutter nanti, cukup import dari package)
// =====================================================================

enum TrafficClass { conversational, streaming, interactive, background }

enum NetworkTechnology {
  lte('4G'),
  nr('5G'),
  wlan('WLAN');

  const NetworkTechnology(this.label);
  final String label;

  static NetworkTechnology fromLabel(String label) {
    return NetworkTechnology.values.firstWhere(
      (t) => t.label == label,
      orElse: () => throw ArgumentError('Teknologi "$label" tidak dikenal'),
    );
  }
}

class TechnologyProfile {
  final NetworkTechnology technology;
  final double rssMin, rssMax;
  final double dataRateMin, dataRateMax;
  final double delayMin, delayMax;
  final double berMin, berMax;
  final double coverageRadiusM;

  const TechnologyProfile({
    required this.technology,
    required this.rssMin, required this.rssMax,
    required this.dataRateMin, required this.dataRateMax,
    required this.delayMin, required this.delayMax,
    required this.berMin, required this.berMax,
    this.coverageRadiusM = 500.0,
  });

  double get rssRange => rssMax - rssMin;
}

class NetworkSnapshot {
  final String id;
  final NetworkTechnology technology;
  final double rssDbm, dataRateMbps, delayMs, ber;
  final bool available;
  final DateTime timestamp;

  const NetworkSnapshot({
    required this.id, required this.technology,
    required this.rssDbm, required this.dataRateMbps,
    required this.delayMs, required this.ber,
    this.available = true, required this.timestamp,
  });
}

final Map<NetworkTechnology, TechnologyProfile> defaultProfiles = {
  NetworkTechnology.lte: const TechnologyProfile(
    technology: NetworkTechnology.lte,
    rssMin: -120.0, rssMax: -50.0,
    dataRateMin: 1.0, dataRateMax: 100.0,
    delayMin: 10.0, delayMax: 100.0,
    berMin: 1e-6, berMax: 1e-3,
    coverageRadiusM: 1000.0,
  ),
  NetworkTechnology.nr: const TechnologyProfile(
    technology: NetworkTechnology.nr,
    rssMin: -110.0, rssMax: -40.0,
    dataRateMin: 50.0, dataRateMax: 1000.0,
    delayMin: 1.0, delayMax: 20.0,
    berMin: 1e-8, berMax: 1e-5,
    coverageRadiusM: 500.0,
  ),
  NetworkTechnology.wlan: const TechnologyProfile(
    technology: NetworkTechnology.wlan,
    rssMin: -90.0, rssMax: -30.0,
    dataRateMin: 1.0, dataRateMax: 600.0,
    delayMin: 5.0, delayMax: 50.0,
    berMin: 1e-7, berMax: 1e-4,
    coverageRadiusM: 100.0,
  ),
};

// =====================================================================
// COPY DARI GENERATOR — untuk standalone test
// =====================================================================

class DetectedNetwork {
  final String id;
  final NetworkTechnology technology;
  final double rssDbm;
  const DetectedNetwork({required this.id, required this.technology, required this.rssDbm});
}

class HybridEstimation {
  final String networkId;
  final NetworkTechnology technology;
  final double rssDbm, qualityFactor, dataRateMbps, delayMs, ber;
  final bool available;

  const HybridEstimation({
    required this.networkId, required this.technology,
    required this.rssDbm, required this.qualityFactor,
    required this.dataRateMbps, required this.delayMs,
    required this.ber, this.available = true,
  });

  NetworkSnapshot toNetworkSnapshot({DateTime? timestamp}) {
    return NetworkSnapshot(
      id: networkId, technology: technology,
      rssDbm: rssDbm, dataRateMbps: dataRateMbps,
      delayMs: delayMs, ber: ber,
      available: available, timestamp: timestamp ?? DateTime.now(),
    );
  }
}

class HybridProfileGenerator {
  final Map<NetworkTechnology, TechnologyProfile> profiles;
  final Random _rng;
  final double noiseStd;
  final double? unavailableThresholdDbm;

  HybridProfileGenerator({
    Map<NetworkTechnology, TechnologyProfile>? profiles,
    Random? rng,
    this.noiseStd = 0.03,
    this.unavailableThresholdDbm,
  })  : profiles = profiles ?? defaultProfiles,
        _rng = rng ?? Random();

  factory HybridProfileGenerator.seeded(int seed, {double noiseStd = 0.03}) {
    return HybridProfileGenerator(rng: Random(seed), noiseStd: noiseStd);
  }

  static double _lerp(double lo, double hi, double t) {
    return lo + (hi - lo) * t.clamp(0.0, 1.0);
  }

  static double _lerpLog(double lo, double hi, double t) {
    if (lo <= 0 || hi <= 0) return lo;
    final logLo = log(lo) / ln10;
    final logHi = log(hi) / ln10;
    return pow(10, logLo + (logHi - logLo) * t.clamp(0.0, 1.0)).toDouble();
  }

  double _gaussianNoise(double mean, double stdDev) {
    final u1 = _rng.nextDouble();
    final u2 = _rng.nextDouble();
    final safeU1 = u1 == 0 ? 0.0001 : u1;
    final z = sqrt(-2.0 * log(safeU1)) * cos(2.0 * pi * u2);
    return mean + z * stdDev;
  }

  double computeQualityFactor(double rssDbm, TechnologyProfile profile) {
    if (profile.rssRange == 0) return 0.5;
    return ((rssDbm - profile.rssMin) / profile.rssRange).clamp(0.0, 1.0);
  }

  bool isAvailable(double rssDbm, TechnologyProfile profile) {
    final threshold = unavailableThresholdDbm ?? profile.rssMin;
    return rssDbm >= threshold;
  }

  HybridEstimation estimate(DetectedNetwork network) {
    final profile = profiles[network.technology]!;
    final rawQuality = computeQualityFactor(network.rssDbm, profile);
    final noisyQuality = (rawQuality + _gaussianNoise(0, noiseStd)).clamp(0.0, 1.0);

    final dataRate = _lerp(profile.dataRateMin, profile.dataRateMax, noisyQuality)
        .clamp(profile.dataRateMin, profile.dataRateMax);
    final delay = _lerp(profile.delayMax, profile.delayMin, noisyQuality)
        .clamp(profile.delayMin, profile.delayMax);
    final ber = _lerpLog(profile.berMin, profile.berMax, 1.0 - noisyQuality)
        .clamp(0.0, 1.0);

    return HybridEstimation(
      networkId: network.id,
      technology: network.technology,
      rssDbm: network.rssDbm,
      qualityFactor: double.parse(rawQuality.toStringAsFixed(4)),
      dataRateMbps: double.parse(dataRate.toStringAsFixed(3)),
      delayMs: double.parse(delay.toStringAsFixed(3)),
      ber: ber,
      available: isAvailable(network.rssDbm, profile),
    );
  }

  List<HybridEstimation> estimateAll(List<DetectedNetwork> networks) {
    return networks.map(estimate).toList();
  }
}

// =====================================================================
// TEST FRAMEWORK MINIMAL
// =====================================================================

int _passed = 0;
int _failed = 0;
int _total = 0;

void _assert(bool condition, String message) {
  _total++;
  if (condition) {
    _passed++;
    print('  ✓ $message');
  } else {
    _failed++;
    print('  ✗ GAGAL: $message');
  }
}

void _assertRange(double value, double min, double max, String name) {
  _assert(
    value >= min && value <= max,
    '$name = ${value.toStringAsFixed(4)} dalam rentang [$min, $max]',
  );
}

void _header(String title) {
  print('\n${'=' * 70}');
  print(' $title');
  print('=' * 70);
}

// =====================================================================
// TEST CASES
// =====================================================================

void testQualityFactor() {
  _header('TEST 1: Quality Factor dari RSS');

  final gen = HybridProfileGenerator.seeded(42, noiseStd: 0.0);
  final profile4G = defaultProfiles[NetworkTechnology.lte]!;
  final profileWlan = defaultProfiles[NetworkTechnology.wlan]!;

  // RSS terkuat → quality = 1.0
  _assert(
    gen.computeQualityFactor(-50.0, profile4G) == 1.0,
    '4G RSS=-50 dBm (terkuat) → quality = 1.0',
  );

  // RSS terlemah → quality = 0.0
  _assert(
    gen.computeQualityFactor(-120.0, profile4G) == 0.0,
    '4G RSS=-120 dBm (terlemah) → quality = 0.0',
  );

  // RSS tengah → quality ≈ 0.5
  final mid = gen.computeQualityFactor(-85.0, profile4G);
  _assert(
    (mid - 0.5).abs() < 0.01,
    '4G RSS=-85 dBm (tengah) → quality ≈ 0.5 (actual: ${mid.toStringAsFixed(4)})',
  );

  // WLAN: -60 dBm → quality = 0.5
  final wlanMid = gen.computeQualityFactor(-60.0, profileWlan);
  _assert(
    (wlanMid - 0.5).abs() < 0.01,
    'WLAN RSS=-60 dBm (tengah) → quality ≈ 0.5 (actual: ${wlanMid.toStringAsFixed(4)})',
  );

  // RSS di luar range → di-clamp
  _assert(
    gen.computeQualityFactor(-10.0, profile4G) == 1.0,
    '4G RSS=-10 dBm (di atas max) → quality clamp ke 1.0',
  );
  _assert(
    gen.computeQualityFactor(-150.0, profile4G) == 0.0,
    '4G RSS=-150 dBm (di bawah min) → quality clamp ke 0.0',
  );
}

void testDataRateProportional() {
  _header('TEST 2: Data Rate Proporsional terhadap RSS');

  // noiseStd = 0 agar deterministik
  final gen = HybridProfileGenerator.seeded(42, noiseStd: 0.0);
  final profile4G = defaultProfiles[NetworkTechnology.lte]!;

  // Sinyal kuat → data rate tinggi
  final strong = gen.estimate(DetectedNetwork(
    id: 'lte_strong', technology: NetworkTechnology.lte, rssDbm: -55.0,
  ));
  // Sinyal lemah → data rate rendah
  final weak = gen.estimate(DetectedNetwork(
    id: 'lte_weak', technology: NetworkTechnology.lte, rssDbm: -115.0,
  ));

  _assert(
    strong.dataRateMbps > weak.dataRateMbps,
    'RSS kuat (-55) → rate ${strong.dataRateMbps} > RSS lemah (-115) → rate ${weak.dataRateMbps}',
  );

  _assertRange(strong.dataRateMbps, profile4G.dataRateMin, profile4G.dataRateMax, '4G strong data rate');
  _assertRange(weak.dataRateMbps, profile4G.dataRateMin, profile4G.dataRateMax, '4G weak data rate');
}

void testDelayInversely() {
  _header('TEST 3: Delay Berbanding Terbalik terhadap RSS');

  final gen = HybridProfileGenerator.seeded(42, noiseStd: 0.0);

  final strong = gen.estimate(DetectedNetwork(
    id: 'nr_strong', technology: NetworkTechnology.nr, rssDbm: -45.0,
  ));
  final weak = gen.estimate(DetectedNetwork(
    id: 'nr_weak', technology: NetworkTechnology.nr, rssDbm: -105.0,
  ));

  _assert(
    strong.delayMs < weak.delayMs,
    '5G RSS kuat (-45) → delay ${strong.delayMs}ms < RSS lemah (-105) → delay ${weak.delayMs}ms',
  );

  final profile5G = defaultProfiles[NetworkTechnology.nr]!;
  _assertRange(strong.delayMs, profile5G.delayMin, profile5G.delayMax, '5G strong delay');
  _assertRange(weak.delayMs, profile5G.delayMin, profile5G.delayMax, '5G weak delay');
}

void testBerInverseLog() {
  _header('TEST 4: BER Berbanding Terbalik (Log-Scale) terhadap RSS');

  final gen = HybridProfileGenerator.seeded(42, noiseStd: 0.0);

  final strong = gen.estimate(DetectedNetwork(
    id: 'wlan_strong', technology: NetworkTechnology.wlan, rssDbm: -35.0,
  ));
  final weak = gen.estimate(DetectedNetwork(
    id: 'wlan_weak', technology: NetworkTechnology.wlan, rssDbm: -85.0,
  ));

  _assert(
    strong.ber < weak.ber,
    'WLAN RSS kuat (-35) → BER ${strong.ber.toStringAsExponential(2)} < RSS lemah (-85) → BER ${weak.ber.toStringAsExponential(2)}',
  );

  _assert(
    strong.ber >= 0 && strong.ber <= 1,
    'BER strong dalam rentang [0, 1]',
  );
  _assert(
    weak.ber >= 0 && weak.ber <= 1,
    'BER weak dalam rentang [0, 1]',
  );
}

void testAvailability() {
  _header('TEST 5: Ketersediaan Jaringan');

  final gen = HybridProfileGenerator.seeded(42, noiseStd: 0.0);

  // WLAN: rss_min = -90, jadi di bawah -90 → not available
  final inRange = gen.estimate(DetectedNetwork(
    id: 'wifi_ok', technology: NetworkTechnology.wlan, rssDbm: -70.0,
  ));
  final outRange = gen.estimate(DetectedNetwork(
    id: 'wifi_out', technology: NetworkTechnology.wlan, rssDbm: -95.0,
  ));

  _assert(inRange.available == true, 'WLAN RSS=-70 dBm → available = true');
  _assert(outRange.available == false, 'WLAN RSS=-95 dBm → available = false');
}

void testSeedReproducibility() {
  _header('TEST 6: Reprodusibilitas Seed');

  final gen1 = HybridProfileGenerator.seeded(123);
  final gen2 = HybridProfileGenerator.seeded(123);

  final net = DetectedNetwork(
    id: 'test', technology: NetworkTechnology.lte, rssDbm: -80.0,
  );

  final r1 = gen1.estimate(net);
  final r2 = gen2.estimate(net);

  _assert(
    r1.dataRateMbps == r2.dataRateMbps,
    'Seed 123 run 1 rate ${r1.dataRateMbps} == run 2 rate ${r2.dataRateMbps}',
  );
  _assert(
    r1.delayMs == r2.delayMs,
    'Seed 123 run 1 delay ${r1.delayMs} == run 2 delay ${r2.delayMs}',
  );
  _assert(
    r1.ber == r2.ber,
    'Seed 123 run 1 BER ${r1.ber} == run 2 BER ${r2.ber}',
  );
}

void testBatchEstimation() {
  _header('TEST 7: Batch Estimation (Multiple Networks)');

  final gen = HybridProfileGenerator.seeded(42);

  final networks = [
    DetectedNetwork(id: 'lte_1', technology: NetworkTechnology.lte, rssDbm: -85.0),
    DetectedNetwork(id: 'nr_1', technology: NetworkTechnology.nr, rssDbm: -70.0),
    DetectedNetwork(id: 'wifi_1', technology: NetworkTechnology.wlan, rssDbm: -55.0),
  ];

  final results = gen.estimateAll(networks);

  _assert(results.length == 3, 'Batch menghasilkan 3 estimasi');
  _assert(results[0].networkId == 'lte_1', 'Estimasi pertama = lte_1');
  _assert(results[1].networkId == 'nr_1', 'Estimasi kedua = nr_1');
  _assert(results[2].networkId == 'wifi_1', 'Estimasi ketiga = wifi_1');

  // Semua harus dalam rentang valid
  for (final r in results) {
    final p = defaultProfiles[r.technology]!;
    _assertRange(r.dataRateMbps, p.dataRateMin, p.dataRateMax, '${r.networkId} data rate');
    _assertRange(r.delayMs, p.delayMin, p.delayMax, '${r.networkId} delay');
    _assert(r.ber >= 0 && r.ber <= 1, '${r.networkId} BER dalam [0, 1]');
  }
}

void testAllTechnologies() {
  _header('TEST 8: Validasi Semua Teknologi (4G, 5G, WLAN)');

  final gen = HybridProfileGenerator.seeded(42);

  // Test 100 sampel per teknologi
  for (final tech in NetworkTechnology.values) {
    final profile = defaultProfiles[tech]!;
    int violations = 0;

    for (int i = 0; i < 100; i++) {
      // RSS acak dalam rentang
      final rss = profile.rssMin +
          (profile.rssMax - profile.rssMin) * (i / 99.0);

      final result = gen.estimate(DetectedNetwork(
        id: '${tech.label}_$i',
        technology: tech,
        rssDbm: rss,
      ));

      if (result.dataRateMbps < profile.dataRateMin ||
          result.dataRateMbps > profile.dataRateMax) violations++;
      if (result.delayMs < profile.delayMin ||
          result.delayMs > profile.delayMax) violations++;
      if (result.ber < 0 || result.ber > 1) violations++;
    }

    _assert(
      violations == 0,
      '${tech.label}: 100 sampel, $violations pelanggaran rentang',
    );
  }
}

void testRealisticWalkScenario() {
  _header('TEST 9: Skenario Walk Test Realistis');

  final gen = HybridProfileGenerator.seeded(42);

  print('\n  Simulasi: Berjalan dari dekat WiFi ke jauh (RSS menurun)');
  print('  ${'RSS(dBm)':>10} ${'Quality':>10} ${'Rate(Mbps)':>12} ${'Delay(ms)':>10} ${'BER':>12} ${'Status':>8}');
  print('  ${'-' * 10} ${'-' * 10} ${'-' * 12} ${'-' * 10} ${'-' * 12} ${'-' * 8}');

  double prevRate = double.infinity;
  double prevDelay = 0;
  bool monotonicRate = true;
  bool monotonicDelay = true;
  // We track monotonicity trend, acknowledging noise can cause small violations

  final rssValues = [-35.0, -45.0, -55.0, -65.0, -75.0, -85.0, -92.0];

  for (final rss in rssValues) {
    final result = gen.estimate(DetectedNetwork(
      id: 'wifi_walk',
      technology: NetworkTechnology.wlan,
      rssDbm: rss,
    ));

    print('  ${rss.toStringAsFixed(1).padLeft(10)} '
        '${result.qualityFactor.toStringAsFixed(4).padLeft(10)} '
        '${result.dataRateMbps.toStringAsFixed(1).padLeft(12)} '
        '${result.delayMs.toStringAsFixed(1).padLeft(10)} '
        '${result.ber.toStringAsExponential(2).padLeft(12)} '
        '${(result.available ? "OK" : "OUT").padLeft(8)}');
  }

  // Verifikasi tren umum (bukan strictly monotonic karena noise)
  final firstResult = HybridProfileGenerator.seeded(100, noiseStd: 0.0).estimate(
    DetectedNetwork(id: 'w', technology: NetworkTechnology.wlan, rssDbm: -35.0),
  );
  final lastResult = HybridProfileGenerator.seeded(100, noiseStd: 0.0).estimate(
    DetectedNetwork(id: 'w', technology: NetworkTechnology.wlan, rssDbm: -85.0),
  );

  _assert(
    firstResult.dataRateMbps > lastResult.dataRateMbps,
    'Tren: Data rate menurun saat menjauh (${firstResult.dataRateMbps} → ${lastResult.dataRateMbps})',
  );
  _assert(
    firstResult.delayMs < lastResult.delayMs,
    'Tren: Delay meningkat saat menjauh (${firstResult.delayMs} → ${lastResult.delayMs})',
  );
  _assert(
    firstResult.ber < lastResult.ber,
    'Tren: BER meningkat saat menjauh (${firstResult.ber.toStringAsExponential(2)} → ${lastResult.ber.toStringAsExponential(2)})',
  );
}

void testQualityFactorPreserved() {
  _header('TEST 10: Quality Factor Tersimpan di Estimasi');

  final gen = HybridProfileGenerator.seeded(42, noiseStd: 0.0);
  final profile = defaultProfiles[NetworkTechnology.lte]!;

  // RSS -85 dBm di 4G (range -120 ~ -50, jadi quality = 35/70 = 0.5)
  final result = gen.estimate(DetectedNetwork(
    id: 'lte_test', technology: NetworkTechnology.lte, rssDbm: -85.0,
  ));

  _assert(
    result.qualityFactor == 0.5,
    'Quality factor tersimpan dengan benar: ${result.qualityFactor}',
  );

  // Quality factor harus selalu antara 0 dan 1
  final extreme1 = gen.estimate(DetectedNetwork(
    id: 'x', technology: NetworkTechnology.lte, rssDbm: -10.0,
  ));
  final extreme2 = gen.estimate(DetectedNetwork(
    id: 'x', technology: NetworkTechnology.lte, rssDbm: -200.0,
  ));

  _assert(
    extreme1.qualityFactor >= 0 && extreme1.qualityFactor <= 1,
    'Quality factor selalu [0, 1] bahkan saat RSS di atas range',
  );
  _assert(
    extreme2.qualityFactor >= 0 && extreme2.qualityFactor <= 1,
    'Quality factor selalu [0, 1] bahkan saat RSS di bawah range',
  );
}

void testToNetworkSnapshot() {
  _header('TEST 11: Konversi ke NetworkSnapshot');

  final gen = HybridProfileGenerator.seeded(42);
  final result = gen.estimate(DetectedNetwork(
    id: 'wifi_convert', technology: NetworkTechnology.wlan, rssDbm: -60.0,
  ));

  final now = DateTime(2026, 9, 29, 10, 0, 0);
  final snapshot = result.toNetworkSnapshot(timestamp: now);

  _assert(snapshot.id == 'wifi_convert', 'Snapshot id preserved');
  _assert(snapshot.technology == NetworkTechnology.wlan, 'Snapshot technology preserved');
  _assert(snapshot.rssDbm == result.rssDbm, 'Snapshot RSS preserved');
  _assert(snapshot.dataRateMbps == result.dataRateMbps, 'Snapshot data rate preserved');
  _assert(snapshot.delayMs == result.delayMs, 'Snapshot delay preserved');
  _assert(snapshot.ber == result.ber, 'Snapshot BER preserved');
  _assert(snapshot.timestamp == now, 'Snapshot timestamp preserved');
}

// =====================================================================
// MAIN
// =====================================================================

void main() {
  print('╔══════════════════════════════════════════════════════════════════════╗');
  print('║  TEST SUITE — Hybrid Profile Generator (FR-03 PRD v2.0)           ║');
  print('║  Proyek: WMC Vertical Handover Real-Time                          ║');
  print('╚══════════════════════════════════════════════════════════════════════╝');

  testQualityFactor();
  testDataRateProportional();
  testDelayInversely();
  testBerInverseLog();
  testAvailability();
  testSeedReproducibility();
  testBatchEstimation();
  testAllTechnologies();
  testRealisticWalkScenario();
  testQualityFactorPreserved();
  testToNetworkSnapshot();

  print('\n${'=' * 70}');
  if (_failed == 0) {
    print(' ✅ SEMUA $_total TEST LULUS! Generator Hybrid berjalan dengan baik.');
  } else {
    print(' ❌ $_failed dari $_total test GAGAL!');
  }
  print(' Passed: $_passed | Failed: $_failed | Total: $_total');
  print('=' * 70);
}
