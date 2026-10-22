import 'dart:async';
import 'package:flutter/foundation.dart';

import '../application/application.dart';
import '../handover/handover.dart';
import '../mobility/mobility.dart';
import 'network_environment.dart';
import 'simulation_models.dart';

/// Controller utama untuk mengorkestrasi seluruh alur simulasi Vertical Handover.
///
/// Mengintegrasikan:
/// - Mobilitas pengguna 2D (Random Waypoint Model)
/// - Lingkungan propagasi RF multi-teknologi (SyntheticNetworkEnvironment)
/// - Mesin keputusan dua tahap (HandoverDecisionEngine: Fuzzy FIS 1 & 2 + TOPSIS)
/// - Penstabil rekomendasi (RecommendationStabilizer: dwell-time & hysteresis)
/// - Riwayat audit log terikat batas (Bounded History) & metrik performa
///
/// Beroperasi secara ADVISORY:
/// Merekomendasikan perpindahan jaringan kepada pengguna tanpa memutus atau
/// mengganti jaringan aktif secara diam-diam.
class SimulationController extends ChangeNotifier {
  final RandomWaypointGenerator _rwpGenerator;
  final NetworkDataProvider _networkProvider;
  HandoverDecisionEngine _engine;
  final RecommendationStabilizer _stabilizer;
  final int maxHistoryCapacity;

  // State simulasi
  int _stepIndex = 0;
  double _elapsedSeconds = 0.0;
  bool _isRunning = false;
  Timer? _timer;

  String _activeNetworkId;
  TrafficClass _trafficClass;
  AppProfile _activeAppProfile;
  final AppNetworkEvaluator _appEvaluator;
  AppSuitabilityReport? _currentAppReport;

  List<NetworkSnapshot> _currentSnapshots = const [];
  DecisionResult? _latestRawDecision;
  DecisionResult? _latestDecision;

  final List<DecisionRecord> _history = [];
  final SimulationMetrics _metrics = SimulationMetrics();

  // Pelacakan deteksi ping-pong (perpindahan balik dalam jendela waktu tertentu)
  String? _lastSwitchedFromId;
  double _lastSwitchedFromTime = -100.0;
  final double pingPongWindowSeconds;

  static final HandoverConfiguration defaultPracticalConfiguration =
      HandoverConfiguration(
    thresholds: const {
      TrafficClass.conversational: 0.40,
      TrafficClass.streaming: 0.45,
      TrafficClass.interactive: 0.45,
      TrafficClass.background: 0.50,
    },
  );

  SimulationController({
    RandomWaypointGenerator? rwpGenerator,
    NetworkDataProvider? networkProvider,
    HandoverDecisionEngine? engine,
    RecommendationStabilizer? stabilizer,
    AppNetworkEvaluator? appEvaluator,
    AppProfile? initialAppProfile,
    String initialActiveNetworkId = 'lte_macro',
    TrafficClass initialTrafficClass = TrafficClass.streaming,
    this.maxHistoryCapacity = 1000,
    this.pingPongWindowSeconds = 5.0,
  })  : _rwpGenerator = rwpGenerator ?? RandomWaypointGenerator(),
        _networkProvider = networkProvider ?? SyntheticNetworkEnvironment(),
        _engine = engine ??
            HandoverDecisionEngine(configuration: defaultPracticalConfiguration),
        _stabilizer = stabilizer ?? RecommendationStabilizer(),
        _appEvaluator = appEvaluator ??
            AppNetworkEvaluator(configuration: defaultPracticalConfiguration),
        _activeAppProfile = initialAppProfile ?? AppCatalog.defaultProfiles.first,
        _activeNetworkId = initialActiveNetworkId,
        _trafficClass = initialAppProfile?.trafficClass ?? initialTrafficClass {
    // Evaluasi awal pada t = 0s
    _evaluateCurrentState();
  }

  // --- Getters ---

  int get stepIndex => _stepIndex;
  double get elapsedSeconds => _elapsedSeconds;
  bool get isRunning => _isRunning;
  String get activeNetworkId => _activeNetworkId;
  TrafficClass get trafficClass => _trafficClass;
  AppProfile get activeAppProfile => _activeAppProfile;
  AppSuitabilityReport? get currentAppReport => _currentAppReport;
  AppNetworkEvaluator get appEvaluator => _appEvaluator;

  MobilityState get mobilityState => _rwpGenerator.currentState;
  MobilityPoint get userPosition => _rwpGenerator.currentState.position;
  double get velocityMps => _rwpGenerator.currentState.currentSpeed;
  RandomWaypointGenerator get rwpGenerator => _rwpGenerator;

  List<NetworkSnapshot> get snapshots => List.unmodifiable(_currentSnapshots);
  DecisionResult? get latestDecision => _latestDecision;
  DecisionResult? get latestRawDecision => _latestRawDecision;
  DecisionRecord? get latestRecord => _history.isNotEmpty ? _history.last : null;
  List<DecisionRecord> get history => List.unmodifiable(_history);
  SimulationMetrics get metrics => _metrics;

  /// Snapshot dari jaringan aktif saat ini.
  NetworkSnapshot? get activeNetworkSnapshot =>
      _currentSnapshots.where((s) => s.id == _activeNetworkId).firstOrNull;

  /// Apakah jaringan aktif saat ini berada di luar jangkauan / terputus.
  bool get isActiveNetworkUnavailable =>
      activeNetworkSnapshot == null || !activeNetworkSnapshot!.available;

  /// Target fallback otomatis saat jaringan aktif terputus (di luar jangkauan).
  String? get fallbackTargetId {
    if (!isActiveNetworkUnavailable) return null;
    final best = _latestDecision?.baselineTopsisNetworkId ??
        _latestDecision?.baselineRssNetworkId;
    if (best != null && best != _activeNetworkId) return best;
    return _currentSnapshots
        .where((s) => s.available && s.id != _activeNetworkId)
        .firstOrNull
        ?.id;
  }

  /// Apakah sistem saat ini merekomendasikan perpindahan ke jaringan target
  /// (baik melalui evaluasi Fuzzy-TOPSIS normal maupun fallback link-failure).
  bool get isHandoverRecommended {
    if (isActiveNetworkUnavailable) {
      return fallbackTargetId != null;
    }
    return _latestDecision != null &&
        _latestDecision!.action == DecisionAction.recommendSwitch &&
        _latestDecision!.targetNetworkId != null &&
        _latestDecision!.targetNetworkId != _activeNetworkId;
  }

  /// ID jaringan target yang direkomendasikan jika ada.
  String? get recommendedTargetId {
    if (isActiveNetworkUnavailable) {
      return fallbackTargetId;
    }
    return isHandoverRecommended ? _latestDecision!.targetNetworkId : null;
  }

  int _playbackSpeed = 1;

  int get playbackSpeed => _playbackSpeed;

  /// Mengubah kecepatan simulasi live (1x, 2x, 5x, 10x, 20x).
  void setPlaybackSpeed(int speed) {
    if (speed <= 0 || _playbackSpeed == speed) return;
    _playbackSpeed = speed;
    if (_isRunning) {
      _timer?.cancel();
      final intervalMs = (1000 ~/ _playbackSpeed).clamp(20, 1000);
      _timer = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (_) => step(1.0),
      );
    }
    notifyListeners();
  }

  // --- Kontrol Simulasi (Playback) ---

  /// Memulai timer simulasi real-time sesuai kecepatan playback.
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    final intervalMs = (1000 ~/ _playbackSpeed).clamp(20, 1000);
    _timer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => step(1.0),
    );
    notifyListeners();
  }

  /// Menjeda jalannya timer simulasi.
  void pause() {
    if (!_isRunning) return;
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    notifyListeners();
  }

  /// Menjalankan simulasi maju satu langkah sebesar `dt` detik (default 1.0s).
  void step([double dt = 1.0]) {
    _stepIndex++;
    _elapsedSeconds += dt;

    // 1. Perbarui mobilitas pengguna
    _rwpGenerator.step(dt);

    // 2. Evaluasi kondisi jaringan dan mesin handover
    _evaluateCurrentState();

    notifyListeners();
  }

  /// Melompat maju sebanyak [count] langkah sekaligus dalam satu frame.
  /// Sangat efisien untuk shortcut pengujian (+10s, +50s, +100s, +500s).
  void fastForward(int count, [double dtPerStep = 1.0]) {
    if (count <= 0) return;
    for (var i = 0; i < count; i++) {
      _stepIndex++;
      _elapsedSeconds += dtPerStep;
      _rwpGenerator.step(dtPerStep);
      _evaluateCurrentState();
    }
    notifyListeners();
  }

  /// Internal: Evaluasi posisi saat ini ke jaringan dan algoritma keputusan.
  void _evaluateCurrentState() {
    // Ambil parameter kanal jaringan terbaru
    _currentSnapshots = _networkProvider.getSnapshots(
      userPosition: userPosition,
      elapsedSeconds: _elapsedSeconds,
    );

    // Hitung keputusan dasar melalui Decision Engine
    _latestRawDecision = _engine.evaluate(
      trafficClass: _trafficClass,
      velocityMps: velocityMps,
      currentNetworkId: _activeNetworkId,
      networks: _currentSnapshots,
    );

    // Terapkan penstabil (hysteresis gain + dwell time)
    final elapsedDuration = Duration(
      milliseconds: (_elapsedSeconds * 1000.0).round(),
    );
    _latestDecision = _stabilizer.apply(
      _latestRawDecision!,
      elapsed: elapsedDuration,
    );

    // Evaluasi kecocokan kandidat jaringan terhadap aplikasi aktif
    _currentAppReport = _appEvaluator.evaluate(
      appProfile: _activeAppProfile,
      candidates: _currentSnapshots,
    );

    // Perbarui metrik performa
    _metrics.totalSteps = _stepIndex;
    _metrics.totalEvaluations++;

    if (isHandoverRecommended) {
      _metrics.recommendationCount++;
      final target = recommendedTargetId;
      if (target != null) {
        _metrics.targetDistribution[target] =
            (_metrics.targetDistribution[target] ?? 0) + 1;
      }
    } else if (_latestDecision!.action == DecisionAction.stay) {
      _metrics.stayCount++;
    } else if (_latestDecision!.action == DecisionAction.insufficientData) {
      _metrics.insufficientDataCount++;
    }

    // Buat catatan riwayat audit log
    final record = DecisionRecord(
      stepIndex: _stepIndex,
      timestamp: DateTime.now(),
      elapsedSeconds: _elapsedSeconds,
      userPosition: userPosition,
      velocityMps: velocityMps,
      activeNetworkId: _activeNetworkId,
      trafficClass: _trafficClass,
      qosFactor: _latestDecision!.qosFactor,
      handoverFactor: _latestDecision!.handoverFactor,
      threshold: _latestDecision!.threshold,
      rawAction: _latestRawDecision!.action,
      rawReason: _latestRawDecision!.reason,
      rawTargetId: _latestRawDecision!.targetNetworkId,
      stabilizedAction: _latestDecision!.action,
      stabilizedReason: _latestDecision!.reason,
      stabilizedTargetId: _latestDecision!.targetNetworkId,
      baselineRssTargetId: _latestDecision!.baselineRssNetworkId,
      baselineTopsisTargetId: _latestDecision!.baselineTopsisNetworkId,
      snapshots: _currentSnapshots,
      ranking: _latestDecision!.ranking,
    );

    _history.add(record);

    // Jaga batas memori (Bounded Buffer)
    if (_history.length > maxHistoryCapacity) {
      _history.removeAt(0);
    }
  }

  // --- Aksi Pengguna (Advisory Interactions) ---

  /// Menerima rekomendasi handover dan berpindah ke jaringan target.
  void acceptHandover() {
    if (!isHandoverRecommended) return;
    final target = recommendedTargetId!;
    switchActiveNetwork(target);
  }

  /// Mengganti jaringan aktif secara eksplisit ke ID tertentu.
  void switchActiveNetwork(String newNetworkId) {
    if (newNetworkId == _activeNetworkId) return;

    // Deteksi ping-pong: jika berpindah kembali ke jaringan sebelumnya dalam jendela waktu tertentu
    if (_lastSwitchedFromId == newNetworkId &&
        (_elapsedSeconds - _lastSwitchedFromTime) <= pingPongWindowSeconds) {
      _metrics.pingPongCount++;
    }

    _lastSwitchedFromId = _activeNetworkId;
    _lastSwitchedFromTime = _elapsedSeconds;

    _activeNetworkId = newNetworkId;
    _stabilizer.reset();

    // Catat eksekusi handover ke metrik
    _metrics.executedHandoverCount++;

    // Evaluasi ulang segera dengan jaringan aktif yang baru
    _evaluateCurrentState();
    notifyListeners();
  }

  /// Mengubah profil kelas trafik yang aktif secara langsung.
  void setTrafficClass(TrafficClass newClass) {
    if (_trafficClass == newClass) return;
    _trafficClass = newClass;
    if (_activeAppProfile.trafficClass != newClass) {
      _activeAppProfile = AppCatalog.getById('custom').copyWith(trafficClass: newClass);
    }
    _stabilizer.reset();
    _evaluateCurrentState();
    notifyListeners();
  }

  /// Mengganti profil aplikasi spesifik yang disimulasikan.
  void selectAppProfile(AppProfile profile) {
    _activeAppProfile = profile;
    _trafficClass = profile.trafficClass;
    if (profile.customThreshold != null) {
      setThreshold(profile.customThreshold!);
    }
    _stabilizer.reset();
    _evaluateCurrentState();
    notifyListeners();
  }

  /// Reset simulasi ke kondisi awal.
  void reset({
    int? newSeed,
    String initialActiveNetworkId = 'lte_macro',
    TrafficClass? initialTrafficClass,
  }) {
    pause();
    _stepIndex = 0;
    _elapsedSeconds = 0.0;
    _activeNetworkId = initialActiveNetworkId;
    if (initialTrafficClass != null) {
      _trafficClass = initialTrafficClass;
    }
    _lastSwitchedFromId = null;
    _lastSwitchedFromTime = -100.0;

    _rwpGenerator.reset(customSeed: newSeed);
    _stabilizer.reset();
    _history.clear();
    _metrics.reset();

    _evaluateCurrentState();
    notifyListeners();
  }

  /// Nilai ambang inisiasi handover aktif untuk kelas trafik saat ini.
  double get currentThreshold =>
      _engine.configuration.thresholds[_trafficClass] ?? 0.45;

  /// Mengatur ambang batas handover (Threshold) untuk kelas trafik saat ini.
  void setThreshold(double newThreshold) {
    final currentConfig = _engine.configuration;
    final updatedThresholds =
        Map<TrafficClass, double>.from(currentConfig.thresholds);
    updatedThresholds[_trafficClass] = newThreshold;
    updateConfiguration(
      HandoverConfiguration(
        weights: currentConfig.weights,
        requirements: currentConfig.requirements,
        thresholds: updatedThresholds,
        rssRanges: currentConfig.rssRanges,
      ),
    );
  }

  /// Memperbarui konfigurasi ambang Fuzzy dan bobot TOPSIS secara dinamis.
  void updateConfiguration(HandoverConfiguration newConfiguration) {
    _engine = HandoverDecisionEngine(configuration: newConfiguration);
    _evaluateCurrentState();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
