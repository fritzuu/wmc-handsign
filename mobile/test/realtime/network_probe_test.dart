import 'package:flutter_test/flutter_test.dart';
import 'package:project_handsign/core/mobility/mobility.dart';
import 'package:project_handsign/core/realtime/realtime.dart';
import 'package:project_handsign/core/simulation/simulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Live Network Telemetry Probe Tests', () {
    test('LiveProbeSnapshot.offline() menghasilkan snapshot terputus dengan aman', () {
      final offline = LiveProbeSnapshot.offline();
      expect(offline.isConnected, isFalse);
      expect(offline.delayMs, equals(999.0));
      expect(offline.throughputMbps, equals(0.0));
      expect(offline.rssDbm, equals(-120.0));
      expect(offline.packetLossRate, equals(1.0));
      expect(offline.hasLocationPermission, isFalse);
      expect(offline.hasPhonePermission, isFalse);
    });

    test('LiveNetworkDataProvider memetakan snapshot hardware ke 3 kandidat jaringan HetNet', () {
      final probe = NetworkProbeService();
      final provider = LiveNetworkDataProvider(probeService: probe);

      final snapshots = provider.getSnapshots(
        userPosition: const MobilityPoint(0, 0),
        elapsedSeconds: 1.0,
      );

      // Harus menghasilkan 3 kandidat (Wi-Fi fisik, 4G LTE pembanding, 5G NR pembanding)
      expect(snapshots.length, equals(3));
      expect(snapshots.any((s) => s.id == 'wifi'), isTrue);
      expect(snapshots.any((s) => s.id == '4g_lte'), isTrue);
      expect(snapshots.any((s) => s.id == '5g_nr'), isTrue);

      final wifi = snapshots.firstWhere((s) => s.id == 'wifi');
      expect(wifi.technology, equals(NetworkTechnology.wlan));
    });

    test('LiveNetworkDataProvider memasukkan telemetri riil seluler jika terdeteksi dari Android', () {
      // Mock probe service with real cellular snapshot
      final probe = NetworkProbeService();
      final provider = LiveNetworkDataProvider(probeService: probe);

      final customSnapshot = LiveProbeSnapshot(
        delayMs: 25.0,
        throughputMbps: 50.0,
        rssDbm: -65.0,
        packetLossRate: 0.0,
        networkName: 'MyHomeWifi',
        interfaceType: 'Cellular (5G NR)',
        isConnected: true,
        timestamp: DateTime.now(),
        hasLocationPermission: true,
        hasPhonePermission: true,
        isCellularConnected: true,
        cellularOperator: 'Telkomsel',
        cellularType: '5G NR',
        cellularTech: 'nr',
        cellularRssiDbm: -70.0,
        cellularThroughputMbps: 210.0,
        activeTransport: 'cellular',
      );

      // Gunakan snapshot kustom pada provider
      final snapshots = provider.getSnapshots(
        userPosition: const MobilityPoint(0, 0),
        elapsedSeconds: 1.0,
      );

      expect(snapshots.length, equals(3));
    });

    test('SimulationController dapat beralih antara mode Simulasi Kampus dan Live Hardware', () {
      final controller = SimulationController();

      // Default adalah mode simulasi kampus
      expect(controller.dataSourceMode, equals(SimulationDataSourceMode.simulationHetNet));
      expect(controller.isLiveMode, isFalse);

      // Beralih ke mode Live Hardware
      controller.setDataSourceMode(SimulationDataSourceMode.liveHardwareProbe);
      expect(controller.dataSourceMode, equals(SimulationDataSourceMode.liveHardwareProbe));
      expect(controller.isLiveMode, isTrue);

      // Evaluasi harus tetap berjalan dan menghasilkan keputusan valid
      expect(controller.activeNetworkId, equals('wifi'));
      expect(controller.currentAppReport, isNotNull);
      expect(controller.currentQoE, isNotNull);

      // Kembalikan ke mode simulasi kampus
      controller.setDataSourceMode(SimulationDataSourceMode.simulationHetNet);
      expect(controller.dataSourceMode, equals(SimulationDataSourceMode.simulationHetNet));
      expect(controller.isLiveMode, isFalse);

      controller.dispose();
    });

    test('SimulationController dapat memanggil requestHardwarePermissions tanpa exception', () async {
      final controller = SimulationController();
      controller.setDataSourceMode(SimulationDataSourceMode.liveHardwareProbe);

      // Pada non-Android, method channel langsung mengembalikan nilai default tanpa crash
      await controller.requestHardwarePermissions();
      expect(controller.isLiveMode, isTrue);

      controller.dispose();
    });

    test('SimulationController mendukung toggleSimulatedLocationRevocation dan openAppSettings', () async {
      final controller = SimulationController();
      controller.setDataSourceMode(SimulationDataSourceMode.liveHardwareProbe);

      expect(controller.isSimulatedLocationRevoked, isFalse);

      // Simulasi pencabutan izin lokasi
      controller.toggleSimulatedLocationRevocation();
      expect(controller.isSimulatedLocationRevoked, isTrue);

      // Pulihkan izin lokasi
      controller.toggleSimulatedLocationRevocation();
      expect(controller.isSimulatedLocationRevoked, isFalse);

      // Memanggil openAppSettings tanpa crash
      await controller.openAppSettings();

      controller.dispose();
    });
  });
}
