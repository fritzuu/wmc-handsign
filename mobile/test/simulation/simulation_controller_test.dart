import 'package:flutter_test/flutter_test.dart';
import 'package:project_handsign/core/mobility/mobility.dart';
import 'package:project_handsign/core/simulation/simulation.dart';

void main() {
  group('SyntheticNetworkEnvironment Tests', () {
    test('Menghasilkan 3 snapshot teknologi heterogen (4G, 5G, WLAN)', () {
      final env = SyntheticNetworkEnvironment.seeded(42);
      final snapshots = env.getSnapshots(
        userPosition: const MobilityPoint(120.0, 120.0),
        elapsedSeconds: 0.0,
      );

      expect(snapshots.length, equals(3));
      final techNames = snapshots.map((s) => s.technology).toSet();
      expect(
        techNames,
        containsAll([
          NetworkTechnology.lte,
          NetworkTechnology.nr,
          NetworkTechnology.wlan,
        ]),
      );
    });

    test('Jarak mempengaruhi daya sinyal (Log-Distance Path Loss)', () {
      final env = SyntheticNetworkEnvironment.seeded(42, shadowFadingStd: 0.0);
      final nearSnapshots = env.getSnapshots(
        userPosition: const MobilityPoint(120.0, 120.0), // Tepat di AP Wi-Fi
        elapsedSeconds: 0.0,
      );
      final farSnapshots = env.getSnapshots(
        userPosition: const MobilityPoint(200.0, 120.0), // Jarak 80m dari AP
        elapsedSeconds: 1.0,
      );

      final nearWifi = nearSnapshots.firstWhere((s) => s.id == 'wifi_ap');
      final farWifi = farSnapshots.firstWhere((s) => s.id == 'wifi_ap');

      expect(nearWifi.available, isTrue);
      expect(farWifi.available, isTrue);
      // Di dekat AP, sinyal harus lebih kuat daripada saat menjauh
      expect(nearWifi.rssDbm, greaterThan(farWifi.rssDbm));
      expect(nearWifi.dataRateMbps, greaterThan(farWifi.dataRateMbps));
      expect(nearWifi.delayMs, lessThan(farWifi.delayMs));
      expect(nearWifi.ber, lessThan(farWifi.ber));
    });

    test('Menandai available: false saat pengguna berada di luar coverage radius', () {
      final env = SyntheticNetworkEnvironment.seeded(42);
      // Wi-Fi AP di (120, 120) dengan radius 100m.
      // Posisi (400, 400) berjarak ~396m -> harus OUT OF RANGE
      final snapshots = env.getSnapshots(
        userPosition: const MobilityPoint(400.0, 400.0),
        elapsedSeconds: 0.0,
      );

      final wifi = snapshots.firstWhere((s) => s.id == 'wifi_ap');
      expect(wifi.available, isFalse);

      // 4G Macro di (250, 250) dengan radius 1000m -> tetap IN RANGE
      final lte = snapshots.firstWhere((s) => s.id == 'lte_macro');
      expect(lte.available, isTrue);
    });

    test('Seed identik menghasilkan parameter snapshot identik (reproducible)', () {
      final env1 = SyntheticNetworkEnvironment.seeded(12345);
      final env2 = SyntheticNetworkEnvironment.seeded(12345);

      final s1 = env1.getSnapshots(
        userPosition: const MobilityPoint(200.0, 200.0),
        elapsedSeconds: 5.0,
      );
      final s2 = env2.getSnapshots(
        userPosition: const MobilityPoint(200.0, 200.0),
        elapsedSeconds: 5.0,
      );

      for (var i = 0; i < s1.length; i++) {
        expect(s1[i].rssDbm, equals(s2[i].rssDbm));
        expect(s1[i].dataRateMbps, equals(s2[i].dataRateMbps));
        expect(s1[i].delayMs, equals(s2[i].delayMs));
        expect(s1[i].ber, equals(s2[i].ber));
      }
    });
  });

  group('SimulationController Tests', () {
    test('Inisialisasi awal controller memiliki state default yang valid', () {
      final controller = SimulationController(
        initialActiveNetworkId: 'wifi_ap',
        initialTrafficClass: TrafficClass.streaming,
      );

      expect(controller.stepIndex, equals(0));
      expect(controller.elapsedSeconds, equals(0.0));
      expect(controller.isRunning, isFalse);
      expect(controller.activeNetworkId, equals('wifi_ap'));
      expect(controller.trafficClass, equals(TrafficClass.streaming));
      expect(controller.snapshots.length, equals(3));
      expect(controller.latestDecision, isNotNull);
      expect(controller.history.length, equals(1));
    });

    test('Step maju memperbarui waktu, posisi mobilitas, dan snapshot', () {
      final controller = SimulationController(
        rwpGenerator: RandomWaypointGenerator(
          config: const RandomWaypointConfig(
            minSpeed: 5.0,
            maxSpeed: 5.0,
            minPauseTime: 0.0,
            maxPauseTime: 0.0,
            seed: 42,
          ),
        ),
      );

      final initialPos = controller.userPosition;
      controller.step(1.0);

      expect(controller.stepIndex, equals(1));
      expect(controller.elapsedSeconds, equals(1.0));
      expect(controller.userPosition, isNot(equals(initialPos)));
      expect(controller.history.length, equals(2));
      expect(controller.metrics.totalSteps, equals(1));
    });

    test('Mode Advisory: Rekomendasi handover tidak mengganti jaringan aktif secara otomatis', () {
      // Simulasikan pengguna berpindah ke posisi yang membuat Wi-Fi di luar jangkauan
      final env = SyntheticNetworkEnvironment.seeded(42);
      final controller = SimulationController(
        networkProvider: env,
        initialActiveNetworkId: 'wifi_ap',
        initialTrafficClass: TrafficClass.streaming,
      );

      // Gerakkan pengguna menjauh beberapa langkah
      for (var i = 0; i < 10; i++) {
        controller.step(1.0);
      }

      // Jaringan aktif tetap wifi_ap (tidak dipaksa berpindah oleh sistem secara otomatis)
      expect(controller.activeNetworkId, equals('wifi_ap'));
    });

    test('acceptHandover() mengganti jaringan aktif ke target yang direkomendasikan', () {
      // Siapkan controller di mana pengguna berada jauh dari wifi_ap
      final rwp = RandomWaypointGenerator(
        config: const RandomWaypointConfig(
          initialPosition: MobilityPoint(400.0, 400.0), // Jauh dari Wi-Fi (120, 120)
          minSpeed: 0.0,
          maxSpeed: 0.0,
        ),
      );

      final controller = SimulationController(
        rwpGenerator: rwp,
        initialActiveNetworkId: 'wifi_ap',
        initialTrafficClass: TrafficClass.streaming,
      );

      // Saat Wi-Fi unavailable, engine akan menghasilkan rekomendasi / insufficientData
      // Uji apakah fungsi acceptHandover aman dipanggil
      final initialNetwork = controller.activeNetworkId;
      if (controller.isHandoverRecommended) {
        final target = controller.recommendedTargetId!;
        controller.acceptHandover();
        expect(controller.activeNetworkId, equals(target));
        expect(controller.metrics.executedHandoverCount, equals(1));
      } else {
        expect(controller.activeNetworkId, equals(initialNetwork));
      }
    });

    test('switchActiveNetwork() mendeteksi perpindahan bolak-balik (ping-pong)', () {
      final controller = SimulationController(
        initialActiveNetworkId: 'lte_macro',
      );

      // Pindah dari 4G ke 5G
      controller.step(1.0);
      controller.switchActiveNetwork('nr_smallcell');

      // Pindah kembali dari 5G ke 4G dalam waktu < 5 detik
      controller.step(1.0);
      controller.switchActiveNetwork('lte_macro');

      expect(controller.metrics.pingPongCount, equals(1));
    });

    test('Bounded Buffer membatasi panjang riwayat pada maxHistoryCapacity', () {
      final controller = SimulationController(
        maxHistoryCapacity: 5,
      );

      // Eksekusi 10 langkah (melebihi kapasitas 5)
      for (var i = 0; i < 10; i++) {
        controller.step(1.0);
      }

      expect(controller.history.length, equals(5));
    });

    test('setTrafficClass() mengubah kelas dan memicu evaluasi ulang', () {
      final controller = SimulationController(
        initialTrafficClass: TrafficClass.conversational,
      );

      expect(controller.trafficClass, equals(TrafficClass.conversational));
      controller.setTrafficClass(TrafficClass.background);

      expect(controller.trafficClass, equals(TrafficClass.background));
      expect(controller.latestDecision?.trafficClass, equals(TrafficClass.background));
    });

    test('reset() mengembalikan seluruh state simulasi ke nilai awal', () {
      final controller = SimulationController(
        initialActiveNetworkId: 'wifi_ap',
      );

      controller.step(1.0);
      controller.step(1.0);
      expect(controller.stepIndex, equals(2));
      expect(controller.history.length, equals(3));

      controller.reset();

      expect(controller.stepIndex, equals(0));
      expect(controller.elapsedSeconds, equals(0.0));
      expect(controller.history.length, equals(1));
      expect(controller.metrics.totalSteps, equals(0));
      expect(controller.metrics.totalEvaluations, equals(1)); // evaluasi t=0s
    });
    test('Link failure: Jaringan aktif di luar jangkauan memicu rekomendasi fallback darurat', () {
      final controller = SimulationController(
        initialActiveNetworkId: 'wifi_ap', // Wi-Fi di (120,120) coverage 100m, user di (250,250) distance ~184m
      );

      // Jaringan aktif berada di luar jangkauan
      expect(controller.isActiveNetworkUnavailable, isTrue);
      expect(controller.fallbackTargetId, isNotNull);
      // Sistem merekomendasikan perpindahan ke jaringan fallback yang tersedia
      expect(controller.isHandoverRecommended, isTrue);
      expect(controller.recommendedTargetId, equals(controller.fallbackTargetId));

      // Saat menerima handover, sistem berpindah ke jaringan yang tersedia
      final target = controller.recommendedTargetId!;
      controller.acceptHandover();
      expect(controller.activeNetworkId, equals(target));
      expect(controller.isActiveNetworkUnavailable, isFalse);
    });

    test('Node di luar jangkauan melemahkan sinyal secara dinamis terhadap jarak berlebih', () {
      final env = SyntheticNetworkEnvironment.seeded(42);
      // Jarak 200m dari Wi-Fi AP (coverage 100m)
      final sNearOut = env.getSnapshots(
        userPosition: const MobilityPoint(320.0, 120.0), // distance = 200m
        elapsedSeconds: 1.0,
      ).firstWhere((s) => s.id == 'wifi_ap');

      // Jarak 400m dari Wi-Fi AP
      final sFarOut = env.getSnapshots(
        userPosition: const MobilityPoint(520.0, 120.0), // distance = 400m
        elapsedSeconds: 2.0,
      ).firstWhere((s) => s.id == 'wifi_ap');

      expect(sNearOut.available, isFalse);
      expect(sFarOut.available, isFalse);
      // Sinyal lebih jauh harus lebih lemah (RSS lebih kecil/negatif)
      expect(sFarOut.rssDbm, lessThan(sNearOut.rssDbm));
    });
  });
}
