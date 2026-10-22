import '../handover/handover.dart';
import '../mobility/mobility.dart';

/// Konfigurasi pemancar / Base Station pada area simulasi 2D.
class BaseStationNode {
  final String id;
  final String name;
  final NetworkTechnology technology;
  final MobilityPoint position;
  final double coverageRadiusM;
  final double rssMin;
  final double rssMax;
  final double dataRateMin;
  final double dataRateMax;
  final double delayMin;
  final double delayMax;
  final double berMin;
  final double berMax;

  const BaseStationNode({
    required this.id,
    required this.name,
    required this.technology,
    required this.position,
    required this.coverageRadiusM,
    required this.rssMin,
    required this.rssMax,
    required this.dataRateMin,
    required this.dataRateMax,
    required this.delayMin,
    required this.delayMax,
    required this.berMin,
    required this.berMax,
  });

  /// Jarak Euclidean (meter) dari node ini ke posisi pengguna.
  double distanceTo(MobilityPoint userPosition) =>
      position.distanceTo(userPosition);

  /// Cek apakah pengguna berada dalam radius jangkauan.
  bool isInRange(MobilityPoint userPosition) =>
      distanceTo(userPosition) <= coverageRadiusM;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'technology': technology.name,
        'position': position.toJson(),
        'coverage_radius_m': coverageRadiusM,
        'rss_range': [rssMin, rssMax],
        'data_rate_range': [dataRateMin, dataRateMax],
        'delay_range': [delayMin, delayMax],
        'ber_range': [berMin, berMax],
      };
}

/// Daftar default node pemancar heterogen (4G, 5G, Wi-Fi)
/// pada area simulasi 500m x 500m sesuai spesifikasi PRD v2.0.
final List<BaseStationNode> defaultSimulationBaseStations = [
  const BaseStationNode(
    id: '4g_lte',
    name: '4G',
    technology: NetworkTechnology.lte,
    position: MobilityPoint(250.0, 250.0),
    coverageRadiusM: 1000.0, // Menjangkau seluruh area (umbrella coverage)
    rssMin: -120.0,
    rssMax: -50.0,
    dataRateMin: 1.0,
    dataRateMax: 100.0,
    delayMin: 10.0,
    delayMax: 100.0,
    berMin: 1e-6,
    berMax: 1e-3,
  ),
  const BaseStationNode(
    id: '5g_nr',
    name: '5G',
    technology: NetworkTechnology.nr,
    position: MobilityPoint(250.0, 250.0),
    coverageRadiusM: 350.0, // Hotspot kecepatan tinggi di tengah area
    rssMin: -110.0,
    rssMax: -40.0,
    dataRateMin: 50.0,
    dataRateMax: 1000.0,
    delayMin: 1.0,
    delayMax: 20.0,
    berMin: 1e-8,
    berMax: 1e-5,
  ),
  const BaseStationNode(
    id: 'wifi',
    name: 'Wi-Fi',
    technology: NetworkTechnology.wlan,
    position: MobilityPoint(120.0, 120.0),
    coverageRadiusM: 100.0, // Jangkauan lokal indoor/kantor
    rssMin: -90.0,
    rssMax: -30.0,
    dataRateMin: 1.0,
    dataRateMax: 600.0,
    delayMin: 5.0,
    delayMax: 50.0,
    berMin: 1e-7,
    berMax: 1e-4,
  ),
];

/// Representasi zona rintangan fisik (gedung beton / rintangan arsitektural)
/// yang menyebabkan redaman Non-Line-of-Sight (NLoS) signifikan terutama pada sinyal 5G berfrekuensi tinggi.
class ObstacleZone {
  final String id;
  final String name;
  final double x;
  final double y;
  final double width;
  final double height;
  final double attenuation5gDb;
  final double attenuation4gDb;

  const ObstacleZone({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.attenuation5gDb = 24.0, // Redaman drastis 5G saat terhalang gedung (NLoS)
    this.attenuation4gDb = 5.0,  // Redaman penetrasi ringan pada 4G (gelombang lebih panjang)
  });

  /// Memeriksa apakah suatu titik koordinat berada di dalam area rintangan ini.
  bool contains(MobilityPoint p) {
    return p.x >= x && p.x <= (x + width) && p.y >= y && p.y <= (y + height);
  }

  /// Memeriksa apakah garis pandang (Line-of-Sight) antara dua titik terhalang oleh gedung beton ini.
  /// Mendeteksi jika titik berada di dalam gedung maupun jika sinyal harus menembus dinding gedung.
  bool blocksLine(MobilityPoint p1, MobilityPoint p2) {
    if (contains(p1) || contains(p2)) return true;

    final xMin = x;
    final xMax = x + width;
    final yMin = y;
    final yMax = y + height;

    double tMin = 0.0;
    double tMax = 1.0;

    final dx = p2.x - p1.x;
    final dy = p2.y - p1.y;

    // Uji slab sumbu X
    if (dx.abs() < 1e-9) {
      if (p1.x < xMin || p1.x > xMax) return false;
    } else {
      double t1 = (xMin - p1.x) / dx;
      double t2 = (xMax - p1.x) / dx;
      if (t1 > t2) {
        final tmp = t1;
        t1 = t2;
        t2 = tmp;
      }
      if (t1 > tMin) tMin = t1;
      if (t2 < tMax) tMax = t2;
      if (tMin > tMax) return false;
    }

    // Uji slab sumbu Y
    if (dy.abs() < 1e-9) {
      if (p1.y < yMin || p1.y > yMax) return false;
    } else {
      double t1 = (yMin - p1.y) / dy;
      double t2 = (yMax - p1.y) / dy;
      if (t1 > t2) {
        final tmp = t1;
        t1 = t2;
        t2 = tmp;
      }
      if (t1 > tMin) tMin = t1;
      if (t2 < tMax) tMax = t2;
      if (tMin > tMax) return false;
    }

    return tMax >= 0.0 && tMin <= 1.0 && tMin <= tMax;
  }
}

/// Daftar rintangan gedung beton default pada area simulasi 500m x 500m (Wilayah Tenggara).
final List<ObstacleZone> defaultSimulationObstacles = [
  const ObstacleZone(
    id: 'building_complex_se',
    name: 'Gedung Beton (NLoS)',
    x: 340.0,
    y: 320.0,
    width: 90.0,
    height: 90.0,
    attenuation5gDb: 24.0,
    attenuation4gDb: 5.0,
  ),
];

/// Preset skenario demonstrasi cepat untuk menguji kondisi optimal tiap teknologi (Wi-Fi, 4G, 5G).
enum SimulationPresetScenario {
  /// Skenario Wi-Fi Terbaik: Pengguna di dalam jangkauan optimal AP (120, 120).
  wifiOptimal,

  /// Skenario 5G Terbaik (LoS): Pengguna di ruang terbuka Line-of-Sight langsung ke tower.
  fiveGLineOfSight,

  /// Skenario 4G Terbaik (Obstacle): Pengguna di dalam zona gedung beton di mana 5G teredam masif.
  fourGObstacle,

  /// Skenario Sirkuit Dinamis: Mobilitas alami memutar melewati ketiga zona secara berulang.
  circuitLoop,
}

/// Kontrak abstrak penyedia data jaringan (Network Data Provider).
///
/// Mengantisipasi integrasi sensor fisik Android/iOS di masa depan:
/// Implementasi sintetis (SyntheticNetworkEnvironment) dapat diganti
/// secara transparan oleh sensor perangkat nyata tanpa mengubah controller.
abstract class NetworkDataProvider {
  List<NetworkSnapshot> getSnapshots({
    required MobilityPoint userPosition,
    required double elapsedSeconds,
  });
}

/// Rekaman forensik satu langkah keputusan simulasi untuk riwayat audit log.
class DecisionRecord {
  final int stepIndex;
  final DateTime timestamp;
  final double elapsedSeconds;
  final MobilityPoint userPosition;
  final double velocityMps;
  final String activeNetworkId;
  final TrafficClass trafficClass;
  final double? qosFactor;
  final double? handoverFactor;
  final double? threshold;
  final DecisionAction rawAction;
  final DecisionReason rawReason;
  final String? rawTargetId;
  final DecisionAction stabilizedAction;
  final DecisionReason stabilizedReason;
  final String? stabilizedTargetId;
  final String? baselineRssTargetId;
  final String? baselineTopsisTargetId;
  final List<NetworkSnapshot> snapshots;
  final List<NetworkRank> ranking;

  const DecisionRecord({
    required this.stepIndex,
    required this.timestamp,
    required this.elapsedSeconds,
    required this.userPosition,
    required this.velocityMps,
    required this.activeNetworkId,
    required this.trafficClass,
    this.qosFactor,
    this.handoverFactor,
    this.threshold,
    required this.rawAction,
    required this.rawReason,
    this.rawTargetId,
    required this.stabilizedAction,
    required this.stabilizedReason,
    this.stabilizedTargetId,
    this.baselineRssTargetId,
    this.baselineTopsisTargetId,
    required this.snapshots,
    this.ranking = const [],
  });

  /// Apakah langkah ini menghasilkan rekomendasi perpindahan yang aktif
  /// (baik Fuzzy-TOPSIS reguler maupun fallback link-failure).
  bool get isHandoverRecommended {
    if (stabilizedAction == DecisionAction.recommendSwitch &&
        stabilizedTargetId != null &&
        stabilizedTargetId != activeNetworkId) {
      return true;
    }
    final activeSnap = snapshots.where((s) => s.id == activeNetworkId).firstOrNull;
    if (activeSnap != null && !activeSnap.available && effectiveTargetId != null) {
      return true;
    }
    return false;
  }

  /// Target jaringan efektif yang direkomendasikan pada langkah ini.
  String? get effectiveTargetId {
    if (stabilizedTargetId != null && stabilizedTargetId != activeNetworkId) {
      return stabilizedTargetId;
    }
    final activeSnap = snapshots.where((s) => s.id == activeNetworkId).firstOrNull;
    if (activeSnap == null || !activeSnap.available) {
      return baselineTopsisTargetId ??
          baselineRssTargetId ??
          snapshots.where((s) => s.available && s.id != activeNetworkId).firstOrNull?.id;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'step_index': stepIndex,
        'timestamp': timestamp.toIso8601String(),
        'elapsed_seconds': elapsedSeconds,
        'user_position': userPosition.toJson(),
        'velocity_mps': velocityMps,
        'active_network_id': activeNetworkId,
        'traffic_class': trafficClass.name,
        'qos_factor': qosFactor,
        'handover_factor': handoverFactor,
        'threshold': threshold,
        'raw_action': rawAction.name,
        'raw_reason': rawReason.name,
        'raw_target_id': rawTargetId,
        'stabilized_action': stabilizedAction.name,
        'stabilized_reason': stabilizedReason.name,
        'stabilized_target_id': stabilizedTargetId,
        'baseline_rss_target_id': baselineRssTargetId,
        'baseline_topsis_target_id': baselineTopsisTargetId,
        'snapshots': snapshots.map((s) => s.toJson()).toList(),
        'ranking': ranking.map((r) => r.toJson()).toList(),
      };
}

/// Metrik kumulatif performa handover selama sesi simulasi.
class SimulationMetrics {
  int totalSteps = 0;
  int totalEvaluations = 0;
  int recommendationCount = 0;
  int executedHandoverCount = 0;
  int pingPongCount = 0;
  int stayCount = 0;
  int insufficientDataCount = 0;
  final Map<String, int> targetDistribution = {};

  SimulationMetrics();

  void reset() {
    totalSteps = 0;
    totalEvaluations = 0;
    recommendationCount = 0;
    executedHandoverCount = 0;
    pingPongCount = 0;
    stayCount = 0;
    insufficientDataCount = 0;
    targetDistribution.clear();
  }

  /// Rasio ping-pong terhadap total rekomendasi yang diterbitkan.
  double get pingPongRate => recommendationCount == 0
      ? 0.0
      : (pingPongCount / recommendationCount) * 100.0;

  Map<String, dynamic> toJson() => {
        'total_steps': totalSteps,
        'total_evaluations': totalEvaluations,
        'recommendation_count': recommendationCount,
        'executed_handover_count': executedHandoverCount,
        'ping_pong_count': pingPongCount,
        'ping_pong_rate_pct': pingPongRate,
        'stay_count': stayCount,
        'insufficient_data_count': insufficientDataCount,
        'target_distribution': targetDistribution,
      };
}
