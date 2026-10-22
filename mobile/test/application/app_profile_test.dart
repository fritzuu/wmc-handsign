import 'package:flutter_test/flutter_test.dart';
import 'package:project_handsign/core/application/application.dart';
import 'package:project_handsign/core/handover/models.dart';

void main() {
  group('AppProfile & AppCatalog Tests', () {
    test('Katalog default memuat 6 preset aplikasi valid', () {
      final profiles = AppCatalog.defaultProfiles;
      expect(profiles.length, equals(6));

      final ids = profiles.map((p) => p.id).toSet();
      expect(ids.contains('youtube'), isTrue);
      expect(ids.contains('mobile_legends'), isTrue);
      expect(ids.contains('whatsapp_call'), isTrue);
      expect(ids.contains('cloud_download'), isTrue);
      expect(ids.contains('social_media'), isTrue);
      expect(ids.contains('custom'), isTrue);
    });

    test('getById mengembalikan profil yang cocok atau fallback ke default', () {
      final youtube = AppCatalog.getById('youtube');
      expect(youtube.name, contains('YouTube'));
      expect(youtube.trafficClass, equals(TrafficClass.streaming));

      final gaming = AppCatalog.getById('mobile_legends');
      expect(gaming.name, contains('Mobile Legends'));
      expect(gaming.trafficClass, equals(TrafficClass.interactive));

      final unknown = AppCatalog.getById('non_existent_app');
      expect(unknown.id, equals(AppCatalog.defaultProfiles.first.id));
    });

    test('AppQosRequirement assert validation rejects invalid ranges', () {
      expect(
        () => AppQosRequirement(
          minDataRateMbps: 10.0,
          targetDataRateMbps: 5.0, // target < min should throw
          maxDelayMs: 100.0,
          targetDelayMs: 20.0,
          maxBer: 1e-4,
        ),
        throwsAssertionError,
      );

      expect(
        () => AppQosRequirement(
          minDataRateMbps: 1.0,
          targetDataRateMbps: 5.0,
          maxDelayMs: 50.0,
          targetDelayMs: 80.0, // target > max should throw
          maxBer: 1e-4,
        ),
        throwsAssertionError,
      );
    });

    test('copyWith memperbarui field profil dengan benar', () {
      final original = AppCatalog.getById('mobile_legends');
      final updated = original.copyWith(name: 'Custom Mobile Legends');

      expect(updated.name, equals('Custom Mobile Legends'));
      expect(updated.id, equals(original.id));
      expect(updated.trafficClass, equals(original.trafficClass));
    });
  });
}
