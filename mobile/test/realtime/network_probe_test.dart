import 'package:flutter_test/flutter_test.dart';
import 'package:project_handsign/core/mobility/mobility.dart';
import 'package:project_handsign/core/realtime/realtime.dart';
import 'package:project_handsign/core/simulation/simulation.dart';

void main() {
  group('Live Network Telemetry Probe Tests', () {
    test('LiveProbeSnapshot.offline() menghasilkan snapshot terputus dengan aman', () {
      final offline = LiveProbeSnapshot.offline();
      expect(offline.isConnected, isFalse);
      expect(offline.delayMs, equals(999.0));
      expect(offline.throughputMbps, equals(0.0));
      expect(offline.rssDbm, equals(-120.0));
      expect(offline.packetLossRate, equals(1.0));
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
  });
}
