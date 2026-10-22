import 'package:flutter_test/flutter_test.dart';
import 'package:project_handsign/core/application/application.dart';
import 'package:project_handsign/core/handover/models.dart';

void main() {
  group('AppNetworkEvaluator Tests', () {
    late AppNetworkEvaluator evaluator;

    setUp(() {
      evaluator = AppNetworkEvaluator();
    });

    test('Evaluasi gaming memprioritaskan jaringan latensi rendah (5G over Wi-Fi)', () {
      final gamingProfile = AppCatalog.getById('mobile_legends');

      final candidates = [
        NetworkSnapshot(
          id: 'wlan_laggy',
          technology: NetworkTechnology.wlan,
          rssDbm: -60.0,
          dataRateMbps: 50.0,
          delayMs: 120.0, // Melanggar SLA gaming (> 60ms)
          ber: 1e-4,
        ),
        NetworkSnapshot(
          id: 'nr_gaming',
          technology: NetworkTechnology.nr,
          rssDbm: -65.0,
          dataRateMbps: 150.0,
          delayMs: 12.0, // Sangat ideal untuk gaming (<= 20ms)
          ber: 1e-7,
        ),
        NetworkSnapshot(
          id: 'lte_stable',
          technology: NetworkTechnology.lte,
          rssDbm: -70.0,
          dataRateMbps: 25.0,
          delayMs: 45.0, // Cukup memadai
          ber: 1e-6,
        ),
      ];

      final report = evaluator.evaluate(
        appProfile: gamingProfile,
        candidates: candidates,
      );

      expect(report.bestCandidate, isNotNull);
      expect(report.bestCandidate!.candidate.id, equals('nr_gaming'));
      expect(report.bestCandidate!.level, equals(SuitabilityLevel.optimal));
      expect(report.bestCandidate!.suitabilityScore, greaterThan(80.0));

      final wlanEval = report.rankings.firstWhere((r) => r.candidate.id == 'wlan_laggy');
      expect(wlanEval.isSlaViolated, isTrue);
      expect(wlanEval.level, equals(SuitabilityLevel.violated));
      expect(wlanEval.violations, isNotEmpty);
    });

    test('Evaluasi video streaming memprioritaskan jaringan bandwidth tinggi', () {
      final videoProfile = AppCatalog.getById('youtube');

      final candidates = [
        NetworkSnapshot(
          id: 'lte_slow',
          technology: NetworkTechnology.lte,
          rssDbm: -70.0,
          dataRateMbps: 2.0, // Di bawah min throughput 5 Mbps untuk video HD
          delayMs: 30.0,
          ber: 1e-5,
        ),
        NetworkSnapshot(
          id: 'wlan_fast',
          technology: NetworkTechnology.wlan,
          rssDbm: -55.0,
          dataRateMbps: 300.0, // Throughput tinggi melebihi target 25 Mbps
          delayMs: 80.0, // Delay 80ms aman untuk video streaming
          ber: 1e-6,
        ),
      ];

      final report = evaluator.evaluate(
        appProfile: videoProfile,
        candidates: candidates,
      );

      expect(report.bestCandidate!.candidate.id, equals('wlan_fast'));
      expect(report.bestCandidate!.level, equals(SuitabilityLevel.optimal));

      final slowEval = report.rankings.firstWhere((r) => r.candidate.id == 'lte_slow');
      expect(slowEval.isSlaViolated, isTrue);
      expect(slowEval.violations.any((v) => v.contains('Throughput')), isTrue);
    });

    test('Menangani daftar kandidat kosong atau tidak ada kandidat tersedia', () {
      final report = evaluator.evaluate(
        appProfile: AppCatalog.getById('youtube'),
        candidates: [
          NetworkSnapshot(
            id: 'dead_network',
            technology: NetworkTechnology.lte,
            rssDbm: -110.0,
            dataRateMbps: 0.1,
            delayMs: 500.0,
            ber: 0.1,
            available: false, // Tidak tersedia
          ),
        ],
      );

      expect(report.bestCandidate, isNull);
      expect(report.rankings, isEmpty);
      expect(report.summary, contains('Tidak ada kandidat jaringan'));
    });
  });
}
