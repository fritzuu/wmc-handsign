import 'dart:math';

/// Status pergerakan pengguna dalam simulasi Random Waypoint.
enum MobilityMovementStatus {
  moving,
  paused,
}

/// Representasi titik koordinat 2 dimensi (dalam meter).
class MobilityPoint {
  final double x;
  final double y;

  const MobilityPoint(this.x, this.y);

  /// Menghitung jarak Euclidean ke titik tujuan.
  double distanceTo(MobilityPoint other) {
    final dx = other.x - x;
    final dy = other.y - y;
    return sqrt(dx * dx + dy * dy);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MobilityPoint &&
          runtimeType == other.runtimeType &&
          (x - other.x).abs() < 1e-6 &&
          (y - other.y).abs() < 1e-6;

  @override
  int get hashCode => Object.hash((x * 1000).round(), (y * 1000).round());

  @override
  String toString() => '(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory MobilityPoint.fromJson(Map<String, dynamic> json) {
    return MobilityPoint(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }
}

/// Pola lintasan mobilitas pengguna dalam area simulasi.
enum MobilityPattern {
  /// Pola loop/circuit natural 14-node yang mengitari kampus, melintasi zona Wi-Fi Cafe Hub,
  /// ruang terbuka 5G LoS, dan gedung beton 4G secara berkesinambungan dan natural.
  naturalCircuit,

  /// Pola dwelling mikro di dalam area Coworking Cafe Hub (Wi-Fi optimal).
  /// Pengguna beraktivitas santai di meja kerja, lounge, dan terrace tanpa keluar dari Wi-Fi.
  wifiDwell,

  /// Pola pergerakan di koridor terbuka Tech Plaza dengan Line-of-Sight prima ke pemancar 5G.
  fiveGOpenPlaza,

  /// Pola pergerakan di dalam gedung beton tebal (NLoS) di mana sinyal 5G teredam
  /// dan jaringan 4G menjadi konektivitas paling andal.
  fourGObstacleShelter,

  /// Pola waypoint acak murni ke seluruh area simulasi (standar RWP).
  uniformRandom,
}

/// Konfigurasi parameter simulasi Random Waypoint Model.
class RandomWaypointConfig {
  /// Lebar area simulasi dalam meter (sumbu X: [0, areaWidth]).
  final double areaWidth;

  /// Tinggi area simulasi dalam meter (sumbu Y: [0, areaHeight]).
  final double areaHeight;

  /// Posisi awal pengguna. Jika null, akan ditempatkan di tengah area (width/2, height/2).
  final MobilityPoint? initialPosition;

  /// Kecepatan minimum dalam meter per detik (m/s).
  final double minSpeed;

  /// Kecepatan maksimum dalam meter per detik (m/s).
  final double maxSpeed;

  /// Waktu jeda minimum saat mencapai waypoint (detik).
  final double minPauseTime;

  /// Waktu jeda maksimum saat mencapai waypoint (detik).
  final double maxPauseTime;

  /// Interval pembaruan simulasi (detik per tick).
  final double updateInterval;

  /// Seed acak opsional untuk reprodusibilitas eksperimen/testing.
  final int? seed;

  /// Pola pergerakan mobilitas (default: naturalCircuit untuk transisi berkala Wi-Fi, 5G, 4G).
  final MobilityPattern pattern;

  const RandomWaypointConfig({
    this.areaWidth = 500.0,
    this.areaHeight = 500.0,
    this.initialPosition,
    this.minSpeed = 1.0,
    this.maxSpeed = 5.0,
    this.minPauseTime = 0.0,
    this.maxPauseTime = 3.0,
    this.updateInterval = 1.0,
    this.seed,
    this.pattern = MobilityPattern.naturalCircuit,
  })  : assert(areaWidth > 0, 'areaWidth harus lebih besar dari 0'),
        assert(areaHeight > 0, 'areaHeight harus lebih besar dari 0'),
        assert(minSpeed >= 0, 'minSpeed tidak boleh negatif'),
        assert(maxSpeed >= minSpeed, 'maxSpeed harus >= minSpeed'),
        assert(minPauseTime >= 0, 'minPauseTime tidak boleh negatif'),
        assert(maxPauseTime >= minPauseTime, 'maxPauseTime harus >= minPauseTime'),
        assert(updateInterval > 0, 'updateInterval harus > 0');

  RandomWaypointConfig copyWith({
    double? areaWidth,
    double? areaHeight,
    MobilityPoint? initialPosition,
    double? minSpeed,
    double? maxSpeed,
    double? minPauseTime,
    double? maxPauseTime,
    double? updateInterval,
    int? seed,
    MobilityPattern? pattern,
  }) {
    return RandomWaypointConfig(
      areaWidth: areaWidth ?? this.areaWidth,
      areaHeight: areaHeight ?? this.areaHeight,
      initialPosition: initialPosition ?? this.initialPosition,
      minSpeed: minSpeed ?? this.minSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      minPauseTime: minPauseTime ?? this.minPauseTime,
      maxPauseTime: maxPauseTime ?? this.maxPauseTime,
      updateInterval: updateInterval ?? this.updateInterval,
      seed: seed ?? this.seed,
      pattern: pattern ?? this.pattern,
    );
  }

  /// Validasi apakah sebuah titik berada di dalam boundary area.
  bool contains(MobilityPoint point) {
    return point.x >= 0 &&
        point.x <= areaWidth &&
        point.y >= 0 &&
        point.y <= areaHeight;
  }
}

/// Representasi snapshot state mobilitas pengguna pada suatu waktu simulasi.
class MobilityState {
  /// Waktu simulasi berlalu dalam detik.
  final double elapsedSeconds;

  /// Posisi saat ini (koordinat X dan Y dalam meter).
  final MobilityPoint position;

  /// Titik waypoint tujuan saat ini.
  final MobilityPoint currentWaypoint;

  /// Kecepatan saat ini (m/s). Bernilai 0 saat paused.
  final double currentSpeed;

  /// Kecepatan jelajah saat aktif bergerak (m/s).
  final double cruisingSpeed;

  /// Status pergerakan (moving atau paused).
  final MobilityMovementStatus status;

  /// Sisa waktu pause jika sedang dalam status paused (detik).
  final double remainingPauseTime;

  const MobilityState({
    required this.elapsedSeconds,
    required this.position,
    required this.currentWaypoint,
    required this.currentSpeed,
    required this.cruisingSpeed,
    required this.status,
    this.remainingPauseTime = 0.0,
  });

  bool get isMoving => status == MobilityMovementStatus.moving;
  bool get isPaused => status == MobilityMovementStatus.paused;

  Map<String, dynamic> toJson() => {
        'timestamp': elapsedSeconds,
        'x': double.parse(position.x.toStringAsFixed(3)),
        'y': double.parse(position.y.toStringAsFixed(3)),
        'speed': double.parse(currentSpeed.toStringAsFixed(3)),
        'cruisingSpeed': double.parse(cruisingSpeed.toStringAsFixed(3)),
        'waypoint': currentWaypoint.toJson(),
        'state': status.name,
        'remainingPauseTime':
            double.parse(remainingPauseTime.toStringAsFixed(3)),
      };

  @override
  String toString() {
    return 'MobilityState(t=${elapsedSeconds.toStringAsFixed(1)}s, '
        'pos=$position, wp=$currentWaypoint, '
        'v=${currentSpeed.toStringAsFixed(2)} m/s, status=${status.name})';
  }
}
