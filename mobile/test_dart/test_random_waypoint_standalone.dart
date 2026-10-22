/// Skrip pengujian mandiri untuk Modul Random Waypoint Model (RWP).
///
/// Menguji 10 spesifikasi fungsional task:
/// 1. Initial position berada di dalam area.
/// 2. Waypoint selalu berada di dalam boundary.
/// 3. Speed berada dalam rentang min-max speed.
/// 4. Posisi berubah ketika state moving.
/// 5. Posisi tidak berubah ketika state paused.
/// 6. Pengguna mencapai waypoint sebelum memilih waypoint baru.
/// 7. Pengguna tidak pernah keluar dari area simulasi (boundary clamp).
/// 8. Delta time menghasilkan perpindahan yang sesuai (dist = speed * dt).
/// 9. Random seed menghasilkan trajectory yang reproducible.
/// 10. Modul dapat dihentikan/reset dengan benar.

import 'dart:math';

// =====================================================================
// DATA MODELS & GENERATOR (Standalone representation for test execution)
// =====================================================================

enum MobilityMovementStatus { moving, paused }

class MobilityPoint {
  final double x;
  final double y;

  const MobilityPoint(this.x, this.y);

  double distanceTo(MobilityPoint other) {
    final dx = other.x - x;
    final dy = other.y - y;
    return sqrt(dx * dx + dy * dy);
  }

  @override
  String toString() => '(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}

class RandomWaypointConfig {
  final double areaWidth;
  final double areaHeight;
  final MobilityPoint? initialPosition;
  final double minSpeed;
  final double maxSpeed;
  final double minPauseTime;
  final double maxPauseTime;
  final double updateInterval;
  final int? seed;

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
  });

  bool contains(MobilityPoint p) {
    return p.x >= 0 && p.x <= areaWidth && p.y >= 0 && p.y <= areaHeight;
  }
}

class MobilityState {
  final double elapsedSeconds;
  final MobilityPoint position;
  final MobilityPoint currentWaypoint;
  final double currentSpeed;
  final double cruisingSpeed;
  final MobilityMovementStatus status;
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
}

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

  void reset({int? customSeed}) {
    final effectiveSeed = customSeed ?? config.seed;
    _rng = effectiveSeed != null ? Random(effectiveSeed) : Random();
    _elapsedSeconds = 0.0;

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

    _currentWaypoint = _generateRandomWaypoint();
    _cruisingSpeed = _generateRandomSpeed();
    _currentSpeed = _cruisingSpeed;
  }

  MobilityPoint _generateRandomWaypoint() {
    final x = _rng.nextDouble() * config.areaWidth;
    final y = _rng.nextDouble() * config.areaHeight;
    return MobilityPoint(x, y);
  }

  double _generateRandomSpeed() {
    if (config.maxSpeed == config.minSpeed) return config.minSpeed;
    return config.minSpeed +
        _rng.nextDouble() * (config.maxSpeed - config.minSpeed);
  }

  double _generateRandomPauseTime() {
    if (config.maxPauseTime == config.minPauseTime) return config.minPauseTime;
    return config.minPauseTime +
        _rng.nextDouble() * (config.maxPauseTime - config.minPauseTime);
  }

  MobilityPoint _clampPoint(MobilityPoint p) {
    return MobilityPoint(
      p.x.clamp(0.0, config.areaWidth),
      p.y.clamp(0.0, config.areaHeight),
    );
  }

  MobilityState get currentState => MobilityState(
        elapsedSeconds: _elapsedSeconds,
        position: _currentPosition,
        currentWaypoint: _currentWaypoint,
        currentSpeed: _currentSpeed,
        cruisingSpeed: _cruisingSpeed,
        status: _status,
        remainingPauseTime: _remainingPauseTime,
      );

  MobilityState step([double? dt]) {
    final deltaTime = dt ?? config.updateInterval;
    if (deltaTime <= 0) throw ArgumentError('deltaTime must be > 0');

    _elapsedSeconds += deltaTime;

    if (_status == MobilityMovementStatus.paused) {
      _remainingPauseTime -= deltaTime;
      _currentSpeed = 0.0;

      if (_remainingPauseTime <= 0.0) {
        _remainingPauseTime = 0.0;
        _status = MobilityMovementStatus.moving;
        _currentWaypoint = _generateRandomWaypoint();
        _cruisingSpeed = _generateRandomSpeed();
        _currentSpeed = _cruisingSpeed;
      }
      return currentState;
    }

    final distance = _currentPosition.distanceTo(_currentWaypoint);
    final stepDistance = _cruisingSpeed * deltaTime;

    if (stepDistance >= distance || distance < 1e-6) {
      _currentPosition = _currentWaypoint;
      final pauseDuration = _generateRandomPauseTime();

      if (pauseDuration > 0.0) {
        _status = MobilityMovementStatus.paused;
        _remainingPauseTime = pauseDuration;
        _currentSpeed = 0.0;
      } else {
        _currentWaypoint = _generateRandomWaypoint();
        _cruisingSpeed = _generateRandomSpeed();
        _currentSpeed = _cruisingSpeed;
      }
    } else {
      final ratio = stepDistance / distance;
      final newX = _currentPosition.x + (_currentWaypoint.x - _currentPosition.x) * ratio;
      final newY = _currentPosition.y + (_currentWaypoint.y - _currentPosition.y) * ratio;

      _currentPosition = _clampPoint(MobilityPoint(newX, newY));
      _currentSpeed = _cruisingSpeed;
    }

    return currentState;
  }
}

// =====================================================================
// TEST HARNESS
// =====================================================================

int _passed = 0;
int _failed = 0;
int _total = 0;

void _assert(bool condition, String message) {
  _total++;
  if (condition) {
    _passed++;
    print('  ✓ PASS: $message');
  } else {
    _failed++;
    print('  ✗ FAIL: $message');
  }
}

void _header(String title) {
  print('\n=== $title ===');
}

void testInitialPositionInArea() {
  _header('TEST 1: Initial position berada di dalam area');

  // Case 1.1: Default center position
  final gen1 = RandomWaypointGenerator(
    config: const RandomWaypointConfig(areaWidth: 400.0, areaHeight: 300.0),
  );
  _assert(
    gen1.currentState.position.x == 200.0 && gen1.currentState.position.y == 150.0,
    'Posisi default berada di pusat area (200, 150)',
  );
  _assert(gen1.config.contains(gen1.currentState.position), 'Posisi awal valid dalam boundary');

  // Case 1.2: Explicit initial position
  final gen2 = RandomWaypointGenerator(
    config: const RandomWaypointConfig(
      areaWidth: 500.0,
      areaHeight: 500.0,
      initialPosition: MobilityPoint(50.0, 75.0),
    ),
  );
  _assert(
    gen2.currentState.position.x == 50.0 && gen2.currentState.position.y == 75.0,
    'Posisi kustom terpasang dengan tepat (50, 75)',
  );

  // Case 1.3: Out-of-bounds initial position is clamped
  final gen3 = RandomWaypointGenerator(
    config: const RandomWaypointConfig(
      areaWidth: 100.0,
      areaHeight: 100.0,
      initialPosition: MobilityPoint(250.0, -20.0),
    ),
  );
  _assert(
    gen3.currentState.position.x == 100.0 && gen3.currentState.position.y == 0.0,
    'Posisi out-of-bounds di-clamp ke batas area (100, 0)',
  );
}

void testWaypointInBoundary() {
  _header('TEST 2: Waypoint selalu berada di dalam boundary');

  final gen = RandomWaypointGenerator(
    config: const RandomWaypointConfig(areaWidth: 300.0, areaHeight: 200.0, seed: 123),
  );

  bool allInBoundary = true;
  for (int i = 0; i < 50; i++) {
    gen.step(1.0);
    final wp = gen.currentState.currentWaypoint;
    if (wp.x < 0 || wp.x > 300.0 || wp.y < 0 || wp.y > 200.0) {
      allInBoundary = false;
      break;
    }
  }

  _assert(allInBoundary, 'Semua 50 waypoint berada di dalam batas [0, 300] x [0, 200]');
}

void testSpeedRange() {
  _header('TEST 3: Speed berada dalam rentang min-max speed');

  final gen = RandomWaypointGenerator(
    config: const RandomWaypointConfig(minSpeed: 1.5, maxSpeed: 4.5, seed: 42),
  );

  bool validRange = true;
  for (int i = 0; i < 60; i++) {
    gen.step(1.0);
    final s = gen.currentState;
    if (s.status == MobilityMovementStatus.moving) {
      if (s.currentSpeed < 1.499 || s.currentSpeed > 4.501) {
        validRange = false;
        break;
      }
    } else {
      if (s.currentSpeed != 0.0) {
        validRange = false;
        break;
      }
    }
  }

  _assert(validRange, 'Kecepatan selalu dalam rentang [1.5, 4.5] m/s saat moving, dan 0 m/s saat paused');
}

void testPositionChangesWhenMoving() {
  _header('TEST 4: Posisi berubah ketika state moving');

  final gen = RandomWaypointGenerator(
    config: const RandomWaypointConfig(
      areaWidth: 1000.0,
      areaHeight: 1000.0,
      initialPosition: MobilityPoint(0.0, 0.0),
      minSpeed: 5.0,
      maxSpeed: 5.0,
      seed: 99,
    ),
  );

  final initialPos = gen.currentState.position;
  final state1 = gen.step(1.0);

  _assert(state1.status == MobilityMovementStatus.moving, 'Status terkonfirmasi moving');
  _assert(
    initialPos.distanceTo(state1.position) > 0.1,
    'Posisi bergeser setelah step moving (${initialPos} -> ${state1.position})',
  );
}

void testPositionDoesNotChangeWhenPaused() {
  _header('TEST 5: Posisi tidak berubah ketika state paused');

  // Setup generator dengan waypoint sangat dekat sehingga langsung tercapai
  final gen = RandomWaypointGenerator(
    config: const RandomWaypointConfig(
      areaWidth: 100.0,
      areaHeight: 100.0,
      initialPosition: MobilityPoint(50.0, 50.0),
      minSpeed: 100.0,
      maxSpeed: 100.0,
      minPauseTime: 5.0,
      maxPauseTime: 5.0,
      seed: 1,
    ),
  );

  // Langkah pertama: mencapai waypoint dan masuk state paused
  final stateAfterReach = gen.step(1.0);
  _assert(stateAfterReach.status == MobilityMovementStatus.paused, 'Generator masuk status paused');

  final pausedPos = stateAfterReach.position;
  // Step lagi saat paused
  final statePaused2 = gen.step(1.0);

  _assert(statePaused2.status == MobilityMovementStatus.paused, 'Masih dalam status paused');
  _assert(
    (statePaused2.position.x - pausedPos.x).abs() < 1e-6 &&
        (statePaused2.position.y - pausedPos.y).abs() < 1e-6,
    'Posisi sama persis selama paused ($pausedPos)',
  );
  _assert(statePaused2.currentSpeed == 0.0, 'Kecepatan terukur 0 m/s saat paused');
}

void testWaypointReachedBeforeNewWaypoint() {
  _header('TEST 6: Pengguna mencapai waypoint sebelum memilih waypoint baru');

  final gen = RandomWaypointGenerator(
    config: const RandomWaypointConfig(
      areaWidth: 500.0,
      areaHeight: 500.0,
      initialPosition: MobilityPoint(0.0, 0.0),
      minSpeed: 10.0,
      maxSpeed: 10.0,
      minPauseTime: 2.0,
      maxPauseTime: 2.0,
      seed: 77,
    ),
  );

  final targetWaypoint = gen.currentState.currentWaypoint;
  bool reached = false;

  for (int step = 0; step < 100; step++) {
    final s = gen.step(1.0);
    if (s.status == MobilityMovementStatus.paused) {
      // Pada saat pause baru dimulai, posisi harus sama dengan target waypoint sebelumnya
      if (s.position.distanceTo(targetWaypoint) < 1e-4) {
        reached = true;
        break;
      }
    }
  }

  _assert(reached, 'Pengguna tiba tepat pada target waypoint sebelum beralih/pause');
}

void testSimulationBoundaryClamped() {
  _header('TEST 7: Pengguna tidak keluar dari area simulasi');

  final gen = RandomWaypointGenerator(
    config: const RandomWaypointConfig(
      areaWidth: 100.0,
      areaHeight: 100.0,
      minSpeed: 20.0,
      maxSpeed: 30.0,
      seed: 33,
    ),
  );

  bool neverOutOfBounds = true;
  for (int i = 0; i < 200; i++) {
    final s = gen.step(0.5);
    if (s.position.x < 0.0 ||
        s.position.x > 100.0 ||
        s.position.y < 0.0 ||
        s.position.y > 100.0) {
      neverOutOfBounds = false;
      break;
    }
  }

  _assert(neverOutOfBounds, '200 langkah simulasi selalu berada dalam boundary [0, 100]');
}

void testDeltaTimeDisplacement() {
  _header('TEST 8: Delta time menghasilkan perpindahan yang sesuai (v * dt)');

  // Jarak jauh agar tidak mencapai waypoint dalam 1 langkah
  final gen = RandomWaypointGenerator(
    config: const RandomWaypointConfig(
      areaWidth: 10000.0,
      areaHeight: 10000.0,
      initialPosition: MobilityPoint(0.0, 0.0),
      minSpeed: 4.0,
      maxSpeed: 4.0,
      seed: 10,
    ),
  );

  final pos0 = gen.currentState.position;
  final dt = 2.5; // seconds
  final pos1 = gen.step(dt).position;

  final actualDisplacement = pos0.distanceTo(pos1);
  final expectedDisplacement = 4.0 * dt; // 10.0 meters

  _assert(
    (actualDisplacement - expectedDisplacement).abs() < 1e-4,
    'Perpindahan terhitung ${actualDisplacement.toStringAsFixed(3)} m (ekspektasi 4 m/s * 2.5s = $expectedDisplacement m)',
  );
}

void testSeedReproducibility() {
  _header('TEST 9: Random seed menghasilkan trajectory yang reproducible');

  final genA = RandomWaypointGenerator(
    config: const RandomWaypointConfig(seed: 2026),
  );
  final pathA = <MobilityPoint>[];
  for (int i = 0; i < 20; i++) {
    pathA.add(genA.step(1.0).position);
  }

  final genB = RandomWaypointGenerator(
    config: const RandomWaypointConfig(seed: 2026),
  );
  final pathB = <MobilityPoint>[];
  for (int i = 0; i < 20; i++) {
    pathB.add(genB.step(1.0).position);
  }

  bool identicalPaths = true;
  for (int i = 0; i < 20; i++) {
    if (pathA[i].distanceTo(pathB[i]) > 1e-6) {
      identicalPaths = false;
      break;
    }
  }

  _assert(identicalPaths, 'Dua generator dengan seed identik menghasilkan 20 koordinat posisi yang sama persis');
}

void testStopAndReset() {
  _header('TEST 10: Modul dapat dihentikan dan di-reset dengan benar');

  final gen = RandomWaypointGenerator(
    config: const RandomWaypointConfig(
      areaWidth: 500.0,
      areaHeight: 500.0,
      initialPosition: MobilityPoint(100.0, 100.0),
      seed: 55,
    ),
  );

  // Jalankan beberapa langkah
  for (int i = 0; i < 15; i++) {
    gen.step(1.0);
  }
  _assert(gen.currentState.elapsedSeconds == 15.0, 'Simulasi telah berjalan 15.0 detik');
  _assert(gen.currentState.position.distanceTo(const MobilityPoint(100.0, 100.0)) > 5.0, 'Posisi telah berpindah');

  // Lakukan reset
  gen.reset();
  _assert(gen.currentState.elapsedSeconds == 0.0, 'Elapsed time kembali ke 0.0 detik setelah reset');
  _assert(
    gen.currentState.position.x == 100.0 && gen.currentState.position.y == 100.0,
    'Posisi kembali ke posisi awal (100, 100) setelah reset',
  );
  _assert(gen.currentState.status == MobilityMovementStatus.moving, 'Status awal kembali moving');
}

void main() {
  print('╔══════════════════════════════════════════════════════════════════════╗');
  print('║  TEST SUITE — Random Waypoint Model (RWP) Mobility Module          ║');
  print('║  Proyek: WMC Vertical Handover Decision Recommender               ║');
  print('╚══════════════════════════════════════════════════════════════════════╝');

  testInitialPositionInArea();
  testWaypointInBoundary();
  testSpeedRange();
  testPositionChangesWhenMoving();
  testPositionDoesNotChangeWhenPaused();
  testWaypointReachedBeforeNewWaypoint();
  testSimulationBoundaryClamped();
  testDeltaTimeDisplacement();
  testSeedReproducibility();
  testStopAndReset();

  print('\n${'=' * 70}');
  if (_failed == 0) {
    print(' ✅ SEMUA $_total TEST LULUS! Modul Random Waypoint bekerja sempurna.');
  } else {
    print(' ❌ $_failed dari $_total test GAGAL!');
  }
  print(' Passed: $_passed | Failed: $_failed | Total: $_total');
  print('=' * 70);
}
