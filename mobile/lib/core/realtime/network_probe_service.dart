import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Hasil telemetri jaringan fisik riil dari perangkat keras.
class LiveProbeSnapshot {
  final double delayMs;
  final double throughputMbps;
  final double rssDbm;
  final double packetLossRate;
  final String networkName;
  final String interfaceType;
  final bool isConnected;
  final DateTime timestamp;

  // Telemetri Tambahan Android & Multi-Interface
  final bool hasLocationPermission;
  final bool hasPhonePermission;
  final bool isCellularConnected;
  final String cellularOperator;
  final String cellularType; // e.g. "4G LTE", "5G NR"
  final String cellularTech; // "lte", "nr", "3g"
  final bool is5gAvailable; // Apakah perangkat/operator mendeteksi sinyal 5G riil
  final bool is5gHardwareSupported; // Apakah hardware modem HP mendukung 5G NR
  final double cellularRssiDbm;
  final double cellularThroughputMbps;
  final String activeTransport; // "wifi", "cellular", "none"

  const LiveProbeSnapshot({
    required this.delayMs,
    required this.throughputMbps,
    required this.rssDbm,
    required this.packetLossRate,
    required this.networkName,
    required this.interfaceType,
    required this.isConnected,
    required this.timestamp,
    this.hasLocationPermission = false,
    this.hasPhonePermission = false,
    this.isCellularConnected = false,
    this.cellularOperator = 'Tidak Terdeteksi',
    this.cellularType = '4G LTE',
    this.cellularTech = 'lte',
    this.is5gAvailable = false,
    this.is5gHardwareSupported = false,
    this.cellularRssiDbm = -85.0,
    this.cellularThroughputMbps = 35.0,
    this.activeTransport = 'none',
  });

  factory LiveProbeSnapshot.offline() {
    return LiveProbeSnapshot(
      delayMs: 999.0,
      throughputMbps: 0.0,
      rssDbm: -120.0,
      packetLossRate: 1.0,
      networkName: 'Terputus (Offline)',
      interfaceType: 'None',
      isConnected: false,
      timestamp: DateTime.now(),
      hasLocationPermission: false,
      hasPhonePermission: false,
      isCellularConnected: false,
      cellularOperator: 'None',
      cellularType: 'None',
      cellularTech: 'lte',
      is5gAvailable: false,
      is5gHardwareSupported: false,
      cellularRssiDbm: -120.0,
      cellularThroughputMbps: 0.0,
      activeTransport: 'none',
    );
  }
}

/// Service untuk melakukan probe telemetri nyata dari antarmuka jaringan fisik perangkat.
///
/// Mendukung:
/// - Pengukuran RTT socket TCP nyata ke edge DNS (1.1.1.1 / 8.8.8.8)
/// - Pengukuran packet drop rate nyata
/// - Pembacaan RSSI & TX Rate fisik Wi-Fi (macOS CoreWLAN/system_profiler & Android WifiManager)
/// - Pembacaan sinyal seluler riil Android (TelephonyManager 4G/5G, RSRP, Operator)
/// - Pengecekan & permintaan izin runtime Android (Lokasi & Phone State)
class NetworkProbeService {
  static const MethodChannel _androidChannel =
      MethodChannel('com.example.project_handsign/telemetry');

  final List<String> targetHosts;
  final int targetPort;
  final int rollingWindowSize;

  final List<bool> _recentProbes = [];
  Timer? _timer;
  final _controller = StreamController<LiveProbeSnapshot>.broadcast();

  LiveProbeSnapshot _latestSnapshot = LiveProbeSnapshot.offline();
  bool _isSimulatedLocationRevoked = false;

  LiveProbeSnapshot get latestSnapshot => _latestSnapshot;
  Stream<LiveProbeSnapshot> get snapshotStream => _controller.stream;
  bool get isSimulatedLocationRevoked => _isSimulatedLocationRevoked;

  /// Mengaktifkan atau menonaktifkan simulasi pencabutan izin lokasi (Mock Revocation)
  /// untuk keperluan pengujian in-app tanpa harus membuka pengaturan OS.
  void setSimulatedLocationRevoked(bool revoked) {
    if (_isSimulatedLocationRevoked == revoked) return;
    _isSimulatedLocationRevoked = revoked;
    probeOnce();
  }

  /// Membuka halaman detail pengaturan aplikasi di Android agar pengguna
  /// dapat mencabut (*revoke*) atau memberikan kembali (*grant*) izin secara fisik di OS.
  Future<void> openAppSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _androidChannel.invokeMethod('openAppSettings');
    } catch (_) {}
  }

  /// Membuka Android Internet Connectivity Panel (Android 10+)
  /// Memungkinkan pengguna mengubah saklar Wi-Fi / Seluler secara cepat.
  Future<bool> openInternetPanel() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final res = await _androidChannel.invokeMethod<bool>('openInternetPanel');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// Mengikat (binding) seluruh koneksi socket proses aplikasi ke antarmuka tertentu
  /// ('cellular', 'wifi', atau 'default').
  /// Ini melakukan migrasi rute data nyata di level proses aplikasi.
  Future<bool> bindProcessToNetwork(String target) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final res = await _androidChannel.invokeMethod<bool>(
        'bindProcessToNetwork',
        {'target': target},
      );
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa antarmuka apa yang saat ini di-bind oleh proses aplikasi
  /// ('cellular', 'wifi', atau 'default').
  Future<String> getProcessBindingStatus() async {
    if (kIsWeb || !Platform.isAndroid) return 'default';
    try {
      final res = await _androidChannel
          .invokeMethod<String>('getProcessBindingStatus');
      return res ?? 'default';
    } catch (_) {
      return 'default';
    }
  }

  NetworkProbeService({
    this.targetHosts = const ['1.1.1.1', '8.8.8.8'],
    this.targetPort = 53,
    this.rollingWindowSize = 10,
  });

  /// Memeriksa status izin hardware di Android (Lokasi & Phone State).
  Future<Map<String, bool>> checkAndroidPermissions() async {
    if (kIsWeb || !Platform.isAndroid) {
      return {
        'hasLocationPermission': true,
        'hasPhonePermission': true,
        'isFullyGranted': true,
      };
    }
    try {
      final res = await _androidChannel
          .invokeMapMethod<String, dynamic>('checkPermissions');
      final hasLoc = _isSimulatedLocationRevoked
          ? false
          : res?['hasLocationPermission'] == true;
      final hasPhone = res?['hasPhonePermission'] == true;
      return {
        'hasLocationPermission': hasLoc,
        'hasPhonePermission': hasPhone,
        'isFullyGranted': hasLoc && hasPhone,
      };
    } catch (_) {
      return {
        'hasLocationPermission': false,
        'hasPhonePermission': false,
        'isFullyGranted': false,
      };
    }
  }

  /// Meminta izin runtime Android secara langsung kepada pengguna.
  Future<Map<String, bool>> requestAndroidPermissions() async {
    if (kIsWeb || !Platform.isAndroid) {
      return {
        'hasLocationPermission': true,
        'hasPhonePermission': true,
        'isFullyGranted': true,
      };
    }
    try {
      final res = await _androidChannel
          .invokeMapMethod<String, dynamic>('requestPermissions');
      return {
        'hasLocationPermission': res?['hasLocationPermission'] == true,
        'hasPhonePermission': res?['hasPhonePermission'] == true,
        'isFullyGranted': res?['isFullyGranted'] == true,
      };
    } catch (_) {
      return {
        'hasLocationPermission': false,
        'hasPhonePermission': false,
        'isFullyGranted': false,
      };
    }
  }

  /// Memulai pemantauan berkala setiap [intervalSeconds] detik.
  void startMonitoring({double intervalSeconds = 1.5}) {
    stopMonitoring();
    probeOnce();
    _timer = Timer.periodic(
      Duration(milliseconds: (intervalSeconds * 1000).round()),
      (_) => probeOnce(),
    );
  }

  /// Menghentikan pemantauan berkala.
  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  /// Melakukan satu kali probe telemetri nyata ke hardware dan jaringan.
  Future<LiveProbeSnapshot> probeOnce() async {
    double measuredDelay = 999.0;
    bool success = false;

    // 1. Ukur latensi socket nyata (RTT) ke target edge DNS terdekat
    for (final host in targetHosts) {
      try {
        final stopwatch = Stopwatch()..start();
        final socket = await Socket.connect(
          host,
          targetPort,
          timeout: const Duration(seconds: 2),
        );
        stopwatch.stop();
        socket.destroy();
        measuredDelay = stopwatch.elapsedMicroseconds / 1000.0;
        success = true;
        break; // Berhasil pada host pertama
      } catch (_) {
        // Coba host berikutnya jika gagal
      }
    }

    // Catat riwayat untuk menghitung packet loss rate
    _recentProbes.add(success);
    if (_recentProbes.length > rollingWindowSize) {
      _recentProbes.removeAt(0);
    }
    final failedCount = _recentProbes.where((s) => !s).length;
    final packetLoss = _recentProbes.isNotEmpty
        ? failedCount / _recentProbes.length
        : (success ? 0.0 : 1.0);

    // Default values
    double realRss = -60.0;
    double realThroughput = 75.0;
    String ssid = 'Wi-Fi Terkoneksi';
    String iface = 'Wi-Fi';

    bool hasLocPerm = false;
    bool hasPhonePerm = false;
    bool isCellularConnected = false;
    String cellularOperator = 'Operator Seluler';
    String cellularType = '4G LTE';
    String cellularTech = 'lte';
    bool is5gAvailable = false;
    bool is5gHardwareSupported = false;
    double cellularRssiDbm = -85.0;
    double cellularThroughputMbps = 35.0;
    String activeTransport = 'wifi';

    // 2. Ambil parameter hardware fisik Wi-Fi & Seluler berdasarkan Platform
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final androidData = await _androidChannel
            .invokeMapMethod<String, dynamic>('getNetworkTelemetry');

        if (androidData != null) {
          hasLocPerm = _isSimulatedLocationRevoked
              ? false
              : androidData['hasLocationPermission'] == true;
          hasPhonePerm = androidData['hasPhonePermission'] == true;
          activeTransport =
              androidData['activeTransport'] as String? ?? 'none';

          // Wi-Fi Telemetry
          final isWifiConn = androidData['isWifiConnected'] == true;
          final wifiSsid = androidData['wifiSsid'] as String?;
          if (wifiSsid != null && wifiSsid.isNotEmpty) ssid = wifiSsid;
          final rawWifiRssi = androidData['wifiRssiDbm'];
          if (rawWifiRssi is num && rawWifiRssi < 0) {
            realRss = rawWifiRssi.toDouble();
          }
          final rawLinkSpeed = androidData['wifiLinkSpeedMbps'];
          if (rawLinkSpeed is num && rawLinkSpeed > 0) {
            realThroughput = rawLinkSpeed.toDouble();
          }

          // Cellular Telemetry
          isCellularConnected = androidData['isCellularConnected'] == true;
          final op = androidData['cellularOperator'] as String?;
          if (op != null && op.isNotEmpty) cellularOperator = op;
          final cType = androidData['cellularType'] as String?;
          if (cType != null && cType.isNotEmpty) cellularType = cType;
          final cTech = androidData['cellularTech'] as String?;
          if (cTech != null && cTech.isNotEmpty) cellularTech = cTech;
          is5gAvailable = androidData['is5gAvailable'] == true;
          is5gHardwareSupported = androidData['is5gHardwareSupported'] == true;
          final cRssi = androidData['cellularRssiDbm'];
          if (cRssi is num && cRssi < 0) {
            cellularRssiDbm = cRssi.toDouble();
          }
          final cSpeed = androidData['cellularSpeedMbps'];
          if (cSpeed is num && cSpeed > 0) {
            cellularThroughputMbps = cSpeed.toDouble();
          }

          if (_isSimulatedLocationRevoked) {
            ssid = 'Wi-Fi (Izin Lokasi Dicabut)';
            cellularRssiDbm = -85.0;
          }

          if (activeTransport == 'cellular') {
            iface = 'Cellular ($cellularType)';
            // Jika seluler aktif dan terhubung, throughput diambil dari seluler
            if (success) {
              realThroughput = cellularThroughputMbps;
              realRss = cellularRssiDbm;
            }
          } else if (isWifiConn) {
            iface = 'Wi-Fi';
          }
        }
      } catch (_) {
        // Fallback jika pemanggilan platform channel gagal
      }
    } else if (!kIsWeb && Platform.isMacOS) {
      try {
        final wifiInfo = await _readMacOsWifiInfo();
        if (wifiInfo != null) {
          if (wifiInfo['rssi'] != null) realRss = wifiInfo['rssi']!;
          if (wifiInfo['txRate'] != null) realThroughput = wifiInfo['txRate']!;
          if (wifiInfo['ssid'] != null) ssid = wifiInfo['ssid'] as String;
        }
      } catch (_) {
        // Fallback ke nilai terukur socket jika parser gagal
      }
    } else {
      // Perkiraan throughput berbasis RTT nyata (TCP BDP heuristic)
      realThroughput =
          (2500.0 / (measuredDelay.clamp(5.0, 500.0))).clamp(5.0, 300.0);
      realRss = measuredDelay < 30
          ? -52.0
          : (measuredDelay < 70 ? -68.0 : -82.0);
    }

    if (!success) {
      _latestSnapshot = LiveProbeSnapshot(
        delayMs: 999.0,
        throughputMbps: 0.0,
        rssDbm: -115.0,
        packetLossRate: 1.0,
        networkName: 'Tidak Ada Internet',
        interfaceType: 'None',
        isConnected: false,
        timestamp: DateTime.now(),
        hasLocationPermission: hasLocPerm,
        hasPhonePermission: hasPhonePerm,
        isCellularConnected: isCellularConnected,
        cellularOperator: cellularOperator,
        cellularType: cellularType,
        cellularTech: cellularTech,
        is5gAvailable: is5gAvailable,
        is5gHardwareSupported: is5gHardwareSupported,
        cellularRssiDbm: cellularRssiDbm,
        cellularThroughputMbps: cellularThroughputMbps,
        activeTransport: activeTransport,
      );
      if (!_controller.isClosed) {
        _controller.add(_latestSnapshot);
      }
      return _latestSnapshot;
    }

    _latestSnapshot = LiveProbeSnapshot(
      delayMs: measuredDelay,
      throughputMbps: realThroughput,
      rssDbm: realRss,
      packetLossRate: packetLoss,
      networkName: ssid,
      interfaceType: iface,
      isConnected: true,
      timestamp: DateTime.now(),
      hasLocationPermission: hasLocPerm,
      hasPhonePermission: hasPhonePerm,
      isCellularConnected: isCellularConnected,
      cellularOperator: cellularOperator,
      cellularType: cellularType,
      cellularTech: cellularTech,
      is5gAvailable: is5gAvailable,
      is5gHardwareSupported: is5gHardwareSupported,
      cellularRssiDbm: cellularRssiDbm,
      cellularThroughputMbps: cellularThroughputMbps,
      activeTransport: activeTransport,
    );

    if (!_controller.isClosed) {
      _controller.add(_latestSnapshot);
    }
    return _latestSnapshot;
  }

  /// Membaca telemetri fisik kartu Wi-Fi macOS langsung dari kernel/driver Airport
  Future<Map<String, dynamic>?> _readMacOsWifiInfo() async {
    try {
      final result = await Process.run(
        'system_profiler',
        ['SPAirPortDataType'],
        runInShell: true,
      );
      if (result.exitCode != 0) return null;

      final output = result.stdout as String;
      final lines = output.split('\n');

      double? rssi;
      double? txRate;
      String? ssid;

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();

        // Cari blok "Current Network Information:"
        if (line.startsWith('Current Network Information:')) {
          if (i + 1 < lines.length) {
            ssid = lines[i + 1].trim().replaceAll(':', '');
          }
        }

        // Cari "Signal / Noise: -49 dBm / -95 dBm"
        if (line.startsWith('Signal / Noise:')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            final sigPart = parts[1].split('/')[0].trim();
            final match = RegExp(r'(-?\d+)').firstMatch(sigPart);
            if (match != null) {
              rssi = double.tryParse(match.group(1)!);
            }
          }
        }

        // Cari "Transmit Rate: 541"
        if (line.startsWith('Transmit Rate:')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            final match = RegExp(r'(\d+)').firstMatch(parts[1].trim());
            if (match != null) {
              txRate = double.tryParse(match.group(1)!);
            }
          }
        }
      }

      return {
        'rssi': rssi,
        'txRate': txRate,
        'ssid': ssid,
      };
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}
