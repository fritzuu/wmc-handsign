import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_handsign/theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeController Tests', () {
    test('Inisialisasi awal controller memiliki default ThemeMode.system', () {
      final controller = ThemeController();
      expect(controller.themeMode, equals(ThemeMode.system));
    });

    test('setThemeMode mengubah mode tema dan memberitahu listeners', () async {
      final controller = ThemeController();
      var notificationCount = 0;
      controller.addListener(() => notificationCount++);

      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, equals(ThemeMode.dark));
      expect(notificationCount, equals(1));

      // Mengatur mode yang sama tidak perlu memicu notifikasi ganda
      await controller.setThemeMode(ThemeMode.dark);
      expect(notificationCount, equals(1));
    });

    test('loadThemeMode memuat preferensi tersimpan dari SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      final controller = ThemeController();

      await controller.loadThemeMode();
      expect(controller.themeMode, equals(ThemeMode.dark));

      SharedPreferences.setMockInitialValues({'app_theme_mode': 'light'});
      await controller.loadThemeMode();
      expect(controller.themeMode, equals(ThemeMode.light));
    });

    testWidgets('toggleTheme membalikkan status tema secara akurat', (tester) async {
      final controller = ThemeController(initialMode: ThemeMode.light);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: controller.themeMode,
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => controller.toggleTheme(context),
                child: const Text('Toggle'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(controller.themeMode, equals(ThemeMode.dark));
    });
  });
}
