import 'dart:math';
import 'mobility_models.dart';

/// Implementasi Random Waypoint Model (RWP) untuk simulasi mobilitas pengguna.
///
/// Modul ini menghasilkan pergerakan realistis pada area 2D:
/// 1. Memilih waypoint acak di dalam boundary area.
/// 2. Menentukan kecepatan acak dalam rentang [minSpeed, maxSpeed].
/// 3. Menggerakkan pengguna menuju waypoint dengan step distance = speed * deltaTime.
/// 4. Menghentikan pengguna saat mencapai waypoint selama jeda acak [minPauseTime, maxPauseTime].
/// 5. Mengulang proses dengan memilih waypoint dan kecepatan baru.
class RandomWaypointGenerator {
  RandomWaypointConfig _config;
  RandomWaypointConfig get config => _config;
  late Random _rng;

  late MobilityPoint _currentPosition;
  late MobilityPoint _currentWaypoint;
  late double _cruisingSpeed;
  late double _currentSpeed;
  late MobilityMovementStatus _status;
  late double _remainingPauseTime;
  double _elapsedSeconds = 0.0;
  int _circuitIndex = 0;

  /// Titik-titik acuan sirkuit loop multi-zona perkotaan/kampus:
  /// - Zona 1 (Wi-Fi Coworking Cafe Hub): Nodes 0-4 (5 titik aktivitas di dalam kafe/kantor)
  /// - Zona 2 (Tech Promenade & 5G LoS Plaza): Nodes 5-8 (ruang terbuka Line-of-Sight)
  /// - Zona 3 (Gedung Beton / Urban Canyon): Nodes 9-11 (NLoS, 5G drop, 4G shelter)
  /// - Zona 4 (South Boulevard & Return Pathways): Nodes 12-14 (perjalanan kembali ke kafe)
  static const List<MobilityPoint> defaultCircuitNodes = [
    // --- Zona 1: Coworking Cafe Hub (Wi-Fi AP di 120, 120) ---
    MobilityPoint(110.0, 110.0), // 0. Cafe Entrance & Reception (Wi-Fi)
    MobilityPoint(120.0, 130.0), // 1. Coffee Bar & Lounge Area (Wi-Fi)
    MobilityPoint(135.0, 115.0), // 2. Coworking Hot Desks (Wi-Fi optimal)
    MobilityPoint(115.0, 95.0),  // 3. Focus & Meeting Pods (Wi-Fi)
    MobilityPoint(145.0, 140.0), // 4. Outdoor Cafe Terrace (Wi-Fi boundary, radius ~32m)

    // --- Zona 2: Tech Promenade & Open Plaza (5G LoS) ---
    MobilityPoint(180.0, 175.0), // 5. Promenade Gate (keluar jangkauan Wi-Fi, handover ke 5G)
    MobilityPoint(220.0, 210.0), // 6. Tech Plaza Entrance (5G LoS prima, kecepatan tinggi)
    MobilityPoint(250.0, 250.0), // 7. Central Smart Tower Plaza (5G Core & 4G Macro Center)
    MobilityPoint(295.0, 270.0), // 8. East Promenade Garden (5G LoS prima)

    // --- Zona 3: Kompleks Gedung Beton (Obstacle NLoS / 4G Shelter) ---
    MobilityPoint(350.0, 310.0), // 9. Akses Masuk Kawasan Gedung Tinggi
    MobilityPoint(385.0, 365.0), // 10. Di Dalam Gedung Beton (5G NLoS drop, 4G penyelamat)
    MobilityPoint(415.0, 395.0), // 11. Gedung Timur & Koridor Internal (4G stabil)

    // --- Zona 4: South Boulevard & Return Pathway ---
    MobilityPoint(300.0, 420.0), // 12. South Boulevard (jangkauan 4G Macro Luar)
    MobilityPoint(170.0, 330.0), // 13. West Green Corridor (mendekati kampus barat)
    MobilityPoint(105.0, 200.0), // 14. Cafe South Access Pathway (mulai masuk radius Wi-Fi ~80m)
  ];

  RandomWaypointGenerator({RandomWaypointConfig? config})
      : _config = config ?? const RandomWaypointConfig() {
    reset();
  }

  /// Mengubah pola lintasan mobilitas secara dinamis.
  void setPattern(MobilityPattern newPattern) {
    if (_config.pattern == newPattern) return;
    _config = _config.copyWith(pattern: newPattern);
    _circuitIndex = 0;
    _currentWaypoint = _generateRandomWaypoint();
  }

  /// Memindahkan posisi pengguna seketika ke koordinat tertentu (untuk pengujian skenario).
  void setPosition(
    MobilityPoint newPosition, {
    MobilityPoint? newWaypoint,
    double? speed,
    bool pause = false,
  }) {
    _currentPosition = _clampPoint(newPosition);
    if (newWaypoint != null) {
      _currentWaypoint = _clampPoint(newWaypoint);
    } else {
      _currentWaypoint = _generateRandomWaypoint();
    }
    if (speed != null) {
      _cruisingSpeed = speed;
      _currentSpeed = pause ? 0.0 : speed;
    }
    if (pause) {
      _status = MobilityMovementStatus.paused;
      _remainingPauseTime = 9999.0;
    } else {
      _status = MobilityMovementStatus.moving;
      _remainingPauseTime = 0.0;
    }
  }

  /// Reset generator ke konfigurasi dan kondisi awal.
  void reset({int? customSeed}) {
    final effectiveSeed = customSeed ?? _config.seed;
    _rng = effectiveSeed != null ? Random(effectiveSeed) : Random();
    _elapsedSeconds = 0.0;
    _circuitIndex = 0;

    // Tentukan posisi awal
    if (_config.initialPosition != null) {
      _currentPosition = _clampPoint(_config.initialPosition!);
    } else {
      _currentPosition = MobilityPoint(
        _config.areaWidth / 2.0,
        _config.areaHeight / 2.0,
      );
    }

    _remainingPauseTime = 0.0;
    _status = MobilityMovementStatus.moving;

    // Pilih waypoint dan kecepatan pertama
    _currentWaypoint = _generateRandomWaypoint();
    _cruisingSpeed = _generateRandomSpeed();
    _currentSpeed = _cruisingSpeed;
  }

  /// Menghasilkan titik tujuan waypoint berikutnya sesuai pola yang aktif.
  MobilityPoint _generateRandomWaypoint() {
    switch (_config.pattern) {
      case MobilityPattern.wifiDwell:
        // Dwelling mikro di dalam Coworking Cafe Hub (AP di 120, 120)
        // Waypoint selalu berada di dalam radius 6m - 42m dari AP (sweet-spot Wi-Fi 6)
        final distance = 6.0 + _rng.nextDouble() * 36.0;
        final angle = _rng.nextDouble() * 2 * pi;
        final targetX = 120.0 + distance * cos(angle);
        final targetY = 120.0 + distance * sin(angle);
        return _clampPoint(MobilityPoint(targetX, targetY));

      case MobilityPattern.fiveGOpenPlaza:
        // Koridor terbuka Tech Plaza dengan Line-of-Sight bebas hambatan
        final targetX = 200.0 + _rng.nextDouble() * 80.0;
        final targetY = 190.0 + _rng.nextDouble() * 70.0;
        return _clampPoint(MobilityPoint(targetX, targetY));

      case MobilityPattern.fourGObstacleShelter:
        // Di dalam kompleks gedung beton (340, 320) s/d (430, 410)
        final targetX = 355.0 + _rng.nextDouble() * 60.0;
        final targetY = 335.0 + _rng.nextDouble() * 60.0;
        return _clampPoint(MobilityPoint(targetX, targetY));

      case MobilityPattern.naturalCircuit:
        final baseNode = defaultCircuitNodes[_circuitIndex % defaultCircuitNodes.length];
        _circuitIndex++;

        // Skalakan ke dimensi area aktif jika berbeda dari 500x500
        final scaleX = _config.areaWidth / 500.0;
        final scaleY = _config.areaHeight / 500.0;

        // Variasi gaussian/jitter natural (radius 3m - 12m) agar rute organik
        final jitterRadius = 3.0 + _rng.nextDouble() * 9.0;
        final jitterAngle = _rng.nextDouble() * 2 * pi;
        final targetX = (baseNode.x * scaleX) + jitterRadius * cos(jitterAngle);
        final targetY = (baseNode.y * scaleY) + jitterRadius * sin(jitterAngle);

        return _clampPoint(MobilityPoint(targetX, targetY));

      case MobilityPattern.uniformRandom:
        final x = _rng.nextDouble() * _config.areaWidth;
        final y = _rng.nextDouble() * _config.areaHeight;
        return MobilityPoint(x, y);
    }
  }

  /// Menghasilkan nilai kecepatan acak dalam rentang yang sesuai pola.
  double _generateRandomSpeed() {
    if (_config.pattern == MobilityPattern.wifiDwell) {
      // Kecepatan santai pejalan kaki di dalam kafe/kantor (0.8 - 1.3 m/s)
      return 0.8 + _rng.nextDouble() * 0.5;
    }
    if (_config.pattern == MobilityPattern.fourGObstacleShelter) {
      // Kecepatan pejalan kaki di dalam gedung (1.0 - 1.5 m/s)
      return 1.0 + _rng.nextDouble() * 0.5;
    }
    if (config.maxSpeed == config.minSpeed) {
      return config.minSpeed;
    }
    return config.minSpeed +
        _rng.nextDouble() * (config.maxSpeed - config.minSpeed);
  }

  /// Menghasilkan durasi jeda acak dalam rentang yang sesuai pola.
  double _generateRandomPauseTime() {
    if (_config.pattern == MobilityPattern.wifiDwell) {
      // Jeda duduk/kerja santai di meja kafe (10 - 25 detik)
      return 10.0 + _rng.nextDouble() * 15.0;
    }
    if (config.maxPauseTime == config.minPauseTime) {
      return config.minPauseTime;
    }
    return config.minPauseTime +
        _rng.nextDouble() * (config.maxPauseTime - config.minPauseTime);
  }

  /// Memastikan titik koordinat tetap berada di dalam boundary area.
  MobilityPoint _clampPoint(MobilityPoint p) {
    final clampedX = p.x.clamp(0.0, config.areaWidth);
    final clampedY = p.y.clamp(0.0, config.areaHeight);
    return MobilityPoint(clampedX, clampedY);
  }

  /// Snapshot state mobilitas saat ini.
  MobilityState get currentState => MobilityState(
        elapsedSeconds: _elapsedSeconds,
        position: _currentPosition,
        currentWaypoint: _currentWaypoint,
        currentSpeed: _currentSpeed,
        cruisingSpeed: _cruisingSpeed,
        status: _status,
        remainingPauseTime: _remainingPauseTime,
      );

  /// Menjalankan satu langkah pembaruan simulasi (advance by deltaTime seconds).
  ///
  /// Jika parameter [dt] tidak diisi, interval default dari config digunakan.
  MobilityState step([double? dt]) {
    final deltaTime = dt ?? config.updateInterval;
    if (deltaTime <= 0) {
      throw ArgumentError('deltaTime harus bernilai positif');
    }

    _elapsedSeconds += deltaTime;

    // Kasus 1: Sedang dalam status PAUSED
    if (_status == MobilityMovementStatus.paused) {
      _remainingPauseTime -= deltaTime;
      _currentSpeed = 0.0;

      if (_remainingPauseTime <= 0.0) {
        // Pause selesai: beralih kembali ke status moving
        _remainingPauseTime = 0.0;
        _status = MobilityMovementStatus.moving;
        _currentWaypoint = _generateRandomWaypoint();
        _cruisingSpeed = _generateRandomSpeed();
        _currentSpeed = _cruisingSpeed;
      }

      return currentState;
    }

    // Kasus 2: Sedang dalam status MOVING
    final distance = _currentPosition.distanceTo(_currentWaypoint);
    final stepDistance = _cruisingSpeed * deltaTime;

    if (stepDistance >= distance || distance < 1e-6) {
      // Waypoint tercapai!
      _currentPosition = _currentWaypoint;
      final pauseDuration = _generateRandomPauseTime();

      if (pauseDuration > 0.0) {
        _status = MobilityMovementStatus.paused;
        _remainingPauseTime = pauseDuration;
        _currentSpeed = 0.0;
      } else {
        // Tanpa jeda, langsung beralih ke waypoint berikutnya
        _currentWaypoint = _generateRandomWaypoint();
        _cruisingSpeed = _generateRandomSpeed();
        _currentSpeed = _cruisingSpeed;
      }
    } else {
      // Bergerak menuju waypoint
      final ratio = stepDistance / distance;
      final newX = _currentPosition.x + (_currentWaypoint.x - _currentPosition.x) * ratio;
      final newY = _currentPosition.y + (_currentWaypoint.y - _currentPosition.y) * ratio;

      _currentPosition = _clampPoint(MobilityPoint(newX, newY));
      _currentSpeed = _cruisingSpeed;
    }

    return currentState;
  }

  /// Menghasilkan urutan snapshot mobilitas untuk N langkah (berguna untuk batch scenario).
  List<MobilityState> generatePath({required int steps, double? dt}) {
    if (steps <= 0) {
      throw ArgumentError('steps harus lebih besar dari 0');
    }

    final path = <MobilityState>[currentState];
    for (int i = 0; i < steps; i++) {
      path.add(step(dt));
    }
    return path;
  }
}
