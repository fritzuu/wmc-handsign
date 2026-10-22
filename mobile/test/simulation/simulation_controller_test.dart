import 'package:flutter_test/flutter_test.dart';
import 'package:project_handsign/core/application/application.dart';
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

      final nearWifi = nearSnapshots.firstWhere(
        (s) => s.technology == NetworkTechnology.wlan,
      );
      final farWifi = farSnapshots.firstWhere(
        (s) => s.technology == NetworkTechnology.wlan,
      );

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

      final wifi = snapshots.firstWhere(
        (s) => s.technology == NetworkTechnology.wlan,
      );
      expect(wifi.available, isFalse);

      // 4G Macro di (250, 250) dengan radius 1000m -> tetap IN RANGE
      final lte = snapshots.firstWhere(
        (s) => s.technology == NetworkTechnology.lte,
      );
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
    test('selectAppProfile() mengubah profil aplikasi dan menyinkronkan laporan kesesuaian', () {
      final controller = SimulationController();
      expect(controller.activeAppProfile.id, equals('youtube'));
      expect(controller.trafficClass, equals(TrafficClass.streaming));
      expect(controller.currentAppReport, isNotNull);

      final gamingProfile = AppCatalog.getById('mobile_legends');
      controller.selectAppProfile(gamingProfile);

      expect(controller.activeAppProfile.id, equals('mobile_legends'));
      expect(controller.trafficClass, equals(TrafficClass.interactive));
      expect(controller.currentAppReport!.appProfile.id, equals('mobile_legends'));
    });

    test('Link failure: Jaringan aktif di luar jangkauan memicu rekomendasi fallback darurat', () {
      final controller = SimulationController(
        initialActiveNetworkId: 'wifi', // Wi-Fi di (120,120) coverage 100m, user di (250,250) distance ~184m
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
      ).firstWhere((s) => s.technology == NetworkTechnology.wlan);

      // Jarak 400m dari Wi-Fi AP
      final sFarOut = env.getSnapshots(
        userPosition: const MobilityPoint(520.0, 120.0), // distance = 400m
        elapsedSeconds: 2.0,
      ).firstWhere((s) => s.technology == NetworkTechnology.wlan);

      expect(sNearOut.available, isFalse);
      expect(sFarOut.available, isFalse);
      // Sinyal lebih jauh harus lebih lemah (RSS lebih kecil/negatif)
      expect(sFarOut.rssDbm, lessThan(sNearOut.rssDbm));
    });

    test('Preset Skenario: Wi-Fi Terbaik memposisikan user di dalam jangkauan AP', () {
      final controller = SimulationController();
      controller.applyPresetScenario(SimulationPresetScenario.wifiOptimal);

      expect(controller.activePresetScenario, equals(SimulationPresetScenario.wifiOptimal));
      expect(controller.userPosition.distanceTo(const MobilityPoint(120.0, 120.0)), lessThanOrEqualTo(5.0));
      expect(controller.isUserInObstacleZone, isFalse);

      final wifiSnap = controller.snapshots.firstWhere((s) => s.technology == NetworkTechnology.wlan);
      expect(wifiSnap.available, isTrue);
      expect(wifiSnap.rssDbm, greaterThan(-60.0));

      // Verifikasi bahwa user tetap tinggal (dwell) di dalam area Wi-Fi selama puluhan langkah
      for (int step = 0; step < 30; step++) {
        controller.step(1.0);
        final dist = controller.userPosition.distanceTo(const MobilityPoint(120.0, 120.0));
        expect(dist, lessThanOrEqualTo(55.0), reason: 'User harus tetap di Coworking Cafe Hub');
        final currentWifi = controller.snapshots.firstWhere((s) => s.technology == NetworkTechnology.wlan);
        expect(currentWifi.available, isTrue);
      }
    });

    test('Preset Skenario: Wi-Fi Kongesti membuktikan kelemahan fatal RSS-Only yang buta kapasitas', () {
      final controller = SimulationController();
      controller.applyPresetScenario(SimulationPresetScenario.wifiCongested);

      expect(controller.activePresetScenario, equals(SimulationPresetScenario.wifiCongested));
      expect(controller.activeNetworkId, equals('wifi'));

      final wifiSnap = controller.snapshots.firstWhere((s) => s.technology == NetworkTechnology.wlan);
      final nrSnap = controller.snapshots.firstWhere((s) => s.technology == NetworkTechnology.nr);

      // RSS Wi-Fi sangat kuat (-30 s.d. -45 dBm) karena user persis di depan AP
      expect(wifiSnap.rssDbm, greaterThan(-45.0));
      // Namun karena kongesti kanal 92%, throughput Wi-Fi ambruk dan delay membengkak
      expect(wifiSnap.loadFactor, greaterThanOrEqualTo(0.85));
      expect(wifiSnap.dataRateMbps, lessThan(35.0));
      expect(wifiSnap.delayMs, greaterThan(30.0));

      // 5G memiliki kapasitas yang jauh lebih superior dibanding Wi-Fi yang congested
      expect(nrSnap.dataRateMbps, greaterThan(wifiSnap.dataRateMbps));

      // RSS-Only secara naif tetap memilih Wi-Fi karena RSS-nya paling kuat (-35 dBm)
      expect(controller.baselineRssNetworkId, equals('wifi'));

      // Smart VHO Multi-Criteria Evaluator (AHP-TOPSIS) mendeteksi Wi-Fi terdegradasi dan memilih 5G
      expect(controller.currentAppReport?.bestCandidate?.candidate.id, equals('5g_nr'));
      final nrScore = controller.currentAppReport!.rankings
          .firstWhere((r) => r.candidate.id == '5g_nr')
          .suitabilityScore;
      final wifiScore = controller.currentAppReport!.rankings
          .firstWhere((r) => r.candidate.id == 'wifi')
          .suitabilityScore;
      expect(nrScore, greaterThan(wifiScore));

      // Kandidat 5G memenuhi SLA aplikasi, sedangkan Wi-Fi menderita akibat kongesti
      final wifiSuitability = controller.currentAppReport!.rankings
          .firstWhere((r) => r.candidate.id == 'wifi');
      expect(wifiSuitability.suitabilityScore, lessThan(nrScore));
    });

    test('Preset Skenario: 5G Terbaik (LoS) memposisikan user di area terbuka dengan throughput puncak', () {
      final controller = SimulationController();
      controller.applyPresetScenario(SimulationPresetScenario.fiveGLineOfSight);

      expect(controller.activePresetScenario, equals(SimulationPresetScenario.fiveGLineOfSight));
      expect(controller.isUserInObstacleZone, isFalse);

      final nrSnap = controller.snapshots.firstWhere((s) => s.technology == NetworkTechnology.nr);
      expect(nrSnap.available, isTrue);
      // Di ruang terbuka (LoS) dekat tower, 5G throughput sangat tinggi (> 300 Mbps)
      expect(nrSnap.dataRateMbps, greaterThan(300.0));
      expect(nrSnap.delayMs, lessThan(15.0));
    });

    test('Preset Skenario: 4G Terbaik (Obstacle) menempatkan user di gedung beton NLoS (5G teredam masif)', () {
      final controller = SimulationController();
      controller.applyPresetScenario(SimulationPresetScenario.fourGObstacle);

      expect(controller.activePresetScenario, equals(SimulationPresetScenario.fourGObstacle));
      expect(controller.isUserInObstacleZone, isTrue);

      final nrSnap = controller.snapshots.firstWhere((s) => s.technology == NetworkTechnology.nr);
      final lteSnap = controller.snapshots.firstWhere((s) => s.technology == NetworkTechnology.lte);

      expect(nrSnap.available, isTrue);
      expect(lteSnap.available, isTrue);
      // 5G teredam parah oleh gedung beton: throughput anjlok, delay membengkak
      expect(nrSnap.dataRateMbps, lessThan(10.0));
      expect(nrSnap.delayMs, greaterThan(60.0));
      // 4G memiliki penetrasi sub-2GHz superior di dalam gedung beton
      expect(lteSnap.dataRateMbps, greaterThan(nrSnap.dataRateMbps));
      expect(lteSnap.delayMs, lessThan(nrSnap.delayMs));
      expect(lteSnap.rssDbm, greaterThan(nrSnap.rssDbm));
    });

    test('Audit Logika: Penggantian profil aplikasi dan slider tidak menambah phantom data seluler atau duplikat step history', () {
      final controller = SimulationController(initialActiveNetworkId: 'wifi');
      expect(controller.stepIndex, equals(0));
      expect(controller.history.length, equals(1));
      final initialSavedMb = controller.cellularDataSavedMb;

      // Ubah profil berkali-kali tanpa step
      controller.selectAppProfile(AppCatalog.getById('mobile_legends'));
      controller.selectAppProfile(AppCatalog.getById('whatsapp_call'));
      controller.selectAppProfile(AppCatalog.getById('cloud_download'));
      controller.setTrafficClass(TrafficClass.conversational);

      // Riwayat dan kuota hemat TIDAK boleh bertambah karena waktu simulasi tidak maju
      expect(controller.stepIndex, equals(0));
      expect(controller.history.length, equals(1));
      expect(controller.cellularDataSavedMb, equals(initialSavedMb));

      // Saat step dieksekusi, baru kuota dan riwayat bertambah secara sah
      controller.step(1.0);
      expect(controller.stepIndex, equals(1));
      expect(controller.history.length, equals(2));
      expect(controller.cellularDataSavedMb, greaterThan(initialSavedMb));
    });

    test('Audit Logika: fallbackTargetId hanya mengembalikan jaringan yang saat ini available', () {
      final env = SyntheticNetworkEnvironment.seeded(42);
      // Tempatkan pengguna di luar jangkauan Wi-Fi (400, 400)
      final rwp = RandomWaypointGenerator(
        config: const RandomWaypointConfig(
          initialPosition: MobilityPoint(400.0, 400.0),
          minSpeed: 0.0,
          maxSpeed: 0.0,
        ),
      );

      final controller = SimulationController(
        networkProvider: env,
        rwpGenerator: rwp,
        initialActiveNetworkId: 'wifi',
      );

      expect(controller.isActiveNetworkUnavailable, isTrue);
      final fallback = controller.fallbackTargetId;
      expect(fallback, isNotNull);
      // Target fallback harus merupakan jaringan yang available
      final targetSnap = controller.snapshots.firstWhere((s) => s.id == fallback);
      expect(targetSnap.available, isTrue);
      expect(targetSnap.id, isNot(equals('wifi')));

      // Eksekusi acceptHandover harus aman dan berhasil memindahkan jaringan
      controller.acceptHandover();
      expect(controller.activeNetworkId, equals(fallback));
      expect(controller.isActiveNetworkUnavailable, isFalse);
    });

    test('Audit Fisika RF: ObstacleZone blocksLine mendeteksi ray blocking dan tembus gedung', () {
      const obstacle = ObstacleZone(
        id: 'test_bld',
        name: 'Gedung Uji',
        x: 100.0,
        y: 100.0,
        width: 50.0,
        height: 50.0,
      );

      // Titik di dalam rintangan
      expect(obstacle.blocksLine(const MobilityPoint(120, 120), const MobilityPoint(200, 200)), isTrue);
      // Ray melintasi rintangan dari kiri ke kanan (50, 125) -> (200, 125)
      expect(obstacle.blocksLine(const MobilityPoint(50, 125), const MobilityPoint(200, 125)), isTrue);
      // Ray diagonal melintasi rintangan (50, 50) -> (200, 200)
      expect(obstacle.blocksLine(const MobilityPoint(50, 50), const MobilityPoint(200, 200)), isTrue);
      // Ray di luar rintangan, tidak melintas (10, 10) -> (80, 80)
      expect(obstacle.blocksLine(const MobilityPoint(10, 10), const MobilityPoint(80, 80)), isFalse);
      // Ray paralel di atas rintangan (50, 80) -> (200, 80)
      expect(obstacle.blocksLine(const MobilityPoint(50, 80), const MobilityPoint(200, 80)), isFalse);
    });

    test('Audit Fisika RF: 5G teredam drastis saat terhalang gedung beton, tidak di-clamp ke batas outdoor', () {
      final env = SyntheticNetworkEnvironment.seeded(12345);
      // User di dalam gedung beton (385, 365)
      final snapshotsInBuilding = env.getSnapshots(
        userPosition: const MobilityPoint(385.0, 365.0),
        elapsedSeconds: 0.0,
      );

      final nrIn = snapshotsInBuilding.firstWhere((s) => s.technology == NetworkTechnology.nr);
      final lteIn = snapshotsInBuilding.firstWhere((s) => s.technology == NetworkTechnology.lte);

      // 5G di dalam gedung beton harus anjlok di bawah 10 Mbps dan delay > 65 ms
      expect(nrIn.dataRateMbps, lessThan(10.0));
      expect(nrIn.delayMs, greaterThan(65.0));
      expect(nrIn.ber, greaterThan(1e-4));

      // 4G menembus beton lebih baik: throughput jauh di atas 5G, delay jauh di bawah 5G
      expect(lteIn.dataRateMbps, greaterThan(nrIn.dataRateMbps));
      expect(lteIn.delayMs, lessThan(nrIn.delayMs));
      expect(lteIn.rssDbm, greaterThan(nrIn.rssDbm));

      // User di luar gedung beton (Line of Sight 5G di 220, 200)
      final snapshotsOutdoor = env.getSnapshots(
        userPosition: const MobilityPoint(220.0, 200.0),
        elapsedSeconds: 0.0,
      );
      final nrOutdoor = snapshotsOutdoor.firstWhere((s) => s.technology == NetworkTechnology.nr);

      // 5G di outdoor Line-of-Sight harus optimal (> 50 Mbps, < 25 ms delay)
      expect(nrOutdoor.dataRateMbps, greaterThan(100.0));
      expect(nrOutdoor.delayMs, lessThan(25.0));
    });

    test('Content & Quota-Aware Offload: YouTube streaming merekomendasikan offload ke Wi-Fi saat terjangkau', () {
      final env = SyntheticNetworkEnvironment.seeded(42);
      // Posisikan user di dekat Wi-Fi AP (120, 120)
      final rwp = RandomWaypointGenerator(
        config: const RandomWaypointConfig(
          initialPosition: MobilityPoint(120.0, 120.0),
          minSpeed: 0.0,
          maxSpeed: 0.0,
        ),
      );

      final controller = SimulationController(
        rwpGenerator: rwp,
        networkProvider: env,
        initialActiveNetworkId: '4g_lte', // Pengguna sedang pakai seluler
        initialAppProfile: AppCatalog.getById('youtube'), // Aplikasi boros kuota
      );

      // Karena Wi-Fi AP terjangkau dan optimal, controller harus merekomendasikan Wi-Fi
      expect(controller.isHandoverRecommended, isTrue);
      expect(controller.recommendedTargetId, equals('wifi'));
    });
  });
}
