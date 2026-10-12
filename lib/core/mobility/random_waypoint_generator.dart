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
  final RandomWaypointConfig config;
  late Random _rng;

  late MobilityPoint _currentPosition;
  late MobilityPoint _currentWaypoint;
  late double _cruisingSpeed;
  late double _currentSpeed;
  late MobilityMovementStatus _status;
  late double _remainingPauseTime;
  double _elapsedSeconds = 0.0;

  RandomWaypointGenerator({RandomWaypointConfig? config})
      : config = config ?? const RandomWaypointConfig() {
    reset();
  }

  /// Reset generator ke konfigurasi dan kondisi awal.
  void reset({int? customSeed}) {
    final effectiveSeed = customSeed ?? config.seed;
    _rng = effectiveSeed != null ? Random(effectiveSeed) : Random();
    _elapsedSeconds = 0.0;

    // Tentukan posisi awal
    if (config.initialPosition != null) {
      _currentPosition = _clampPoint(config.initialPosition!);
    } else {
      _currentPosition = MobilityPoint(
        config.areaWidth / 2.0,
        config.areaHeight / 2.0,
      );
    }

    _remainingPauseTime = 0.0;
    _status = MobilityMovementStatus.moving;

    // Pilih waypoint dan kecepatan pertama
    _currentWaypoint = _generateRandomWaypoint();
    _cruisingSpeed = _generateRandomSpeed();
    _currentSpeed = _cruisingSpeed;
  }

  /// Menghasilkan titik acak di dalam batas area [0, areaWidth] x [0, areaHeight].
  MobilityPoint _generateRandomWaypoint() {
    final x = _rng.nextDouble() * config.areaWidth;
    final y = _rng.nextDouble() * config.areaHeight;
    return MobilityPoint(x, y);
  }

  /// Menghasilkan nilai kecepatan acak dalam rentang [minSpeed, maxSpeed].
  double _generateRandomSpeed() {
    if (config.maxSpeed == config.minSpeed) {
      return config.minSpeed;
    }
    return config.minSpeed +
        _rng.nextDouble() * (config.maxSpeed - config.minSpeed);
  }

  /// Menghasilkan durasi jeda acak dalam rentang [minPauseTime, maxPauseTime].
  double _generateRandomPauseTime() {
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
