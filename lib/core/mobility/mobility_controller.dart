import 'dart:async';
import 'package:flutter/foundation.dart';
import 'mobility_models.dart';
import 'random_waypoint_generator.dart';

/// Mode penyedia parameter kecepatan mobilitas untuk sistem handover.
enum MobilitySpeedMode {
  /// Kecepatan statis/manual yang diatur pengguna (Sesuai batas teknis PRD v2.0).
  manualStatic,

  /// Kecepatan dinamis dari simulasi Random Waypoint Model (untuk skenario pengujian).
  randomWaypoint,
}

/// Controller / Service untuk mengelola mobilitas pengguna dan menyediakan
/// parameter kecepatan (`effectiveSpeed`) yang dapat dihubungkan ke Fuzzy Logic.
///
/// Modul ini dirancang terisolasi:
/// - TIDAK mengganti mekanisme pembacaan RSS aktual.
/// - TIDAK mengganggu alur TOPSIS, Baseline RSS-only, maupun Decision Logging.
/// - Menyediakan toggle transparan antara manual static speed dan RWP simulation speed.
class MobilityController extends ChangeNotifier {
  MobilitySpeedMode _mode;
  double _manualSpeed;
  final RandomWaypointGenerator _rwpGenerator;
  Timer? _timer;
  bool _isRunning = false;

  MobilityController({
    MobilitySpeedMode initialMode = MobilitySpeedMode.manualStatic,
    double initialManualSpeed = 1.4, // Kecepatan rata-rata jalan kaki (1.4 m/s)
    RandomWaypointConfig? rwpConfig,
  })  : _mode = initialMode,
        _manualSpeed = initialManualSpeed,
        _rwpGenerator = RandomWaypointGenerator(config: rwpConfig);

  /// Mode sumber kecepatan saat ini.
  MobilitySpeedMode get mode => _mode;

  /// Apakah mode simulasi Random Waypoint sedang aktif sebagai sumber kecepatan.
  bool get isRandomWaypointActive => _mode == MobilitySpeedMode.randomWaypoint;

  /// Nilai kecepatan manual statis (m/s).
  double get manualSpeed => _manualSpeed;

  /// Snapshot kondisi mobilitas RWP saat ini.
  MobilityState get mobilityState => _rwpGenerator.currentState;

  /// Generator RWP yang digunakan.
  RandomWaypointGenerator get generator => _rwpGenerator;

  /// Status apakah timer simulasi berkala sedang berjalan.
  bool get isRunning => _isRunning;

  /// Kecepatan efektif (m/s) yang diteruskan ke sistem Fuzzy Logic:
  /// - Jika mode manualStatic: mengembalikan manualSpeed.
  /// - Jika mode randomWaypoint: mengembalikan currentSpeed dari simulasi RWP.
  double get effectiveSpeed {
    switch (_mode) {
      case MobilitySpeedMode.manualStatic:
        return _manualSpeed;
      case MobilitySpeedMode.randomWaypoint:
        return _rwpGenerator.currentState.currentSpeed;
    }
  }

  /// Mengubah mode penyedia kecepatan.
  void setMode(MobilitySpeedMode mode) {
    if (_mode != mode) {
      _mode = mode;
      notifyListeners();
    }
  }

  /// Mengatur nilai kecepatan manual statis (m/s).
  void setManualSpeed(double speed) {
    if (speed >= 0 && _manualSpeed != speed) {
      _manualSpeed = speed;
      if (_mode == MobilitySpeedMode.manualStatic) {
        notifyListeners();
      }
    }
  }

  /// Memulai simulasi Random Waypoint dengan timer berkala.
  void startSimulation() {
    if (_isRunning) return;
    _isRunning = true;

    final intervalMs = (_rwpGenerator.config.updateInterval * 1000).toInt();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      _rwpGenerator.step();
      notifyListeners();
    });

    notifyListeners();
  }

  /// Menghentikan sementara timer simulasi.
  void stopSimulation() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    notifyListeners();
  }

  /// Menjalankan tepat satu langkah pembaruan simulasi (berguna untuk stepping/testing).
  MobilityState stepSimulation([double? dt]) {
    final state = _rwpGenerator.step(dt);
    notifyListeners();
    return state;
  }

  /// Mereset simulasi Random Waypoint ke kondisi awal.
  void resetSimulation({int? customSeed}) {
    stopSimulation();
    _rwpGenerator.reset(customSeed: customSeed);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
