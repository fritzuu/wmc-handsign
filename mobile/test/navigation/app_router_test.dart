import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_handsign/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App navigation shell boots, switches tabs cleanly, and toggles dark mode', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // 1. Verifikasi berada di Beranda (HomeScreen)
    expect(find.text('WMC Simulator'), findsOneWidget);
    expect(find.text('Alur Simulator Vertical Handover'), findsOneWidget);
    expect(find.text('Menu Utama'), findsOneWidget);

    // Verifikasi tombol toggle tema cepat di AppBar
    final themeToggleFinder = find.byTooltip('Beralih ke mode gelap');
    expect(themeToggleFinder, findsOneWidget);
    await tester.tap(themeToggleFinder);
    await tester.pumpAndSettle();

    // Sekarang tooltip berubah ke 'Beralih ke mode terang'
    expect(find.byTooltip('Beralih ke mode terang'), findsOneWidget);

    // 2. Navigasi ke Tab Simulasi (MonitorScreen)
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Simulasi'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Posisi & Mobilitas Pengguna'), findsOneWidget);
    expect(find.text('KEPUTUSAN SAAT INI (ADVISORY)'), findsOneWidget);

    // 3. Navigasi ke Tab Realtime (RealtimeScreen)
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Realtime'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Mencoba Terhubung...'), findsOneWidget);
    expect(find.text('Telemetri Sensor Perangkat Fisik'), findsOneWidget);

    // 4. Navigasi ke Tab Hasil (ResultsScreen)
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Hasil'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan Metrik Simulasi'), findsOneWidget);
    expect(find.text('Perbandingan Metode (Fuzzy-TOPSIS vs Baseline)'), findsOneWidget);

    // 5. Navigasi ke Tab Pengaturan (SettingsScreen)
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Pengaturan'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tema Tampilan Aplikasi'), findsOneWidget);
    expect(find.text('Kelas Aplikasi Aktif (User Preference)'), findsOneWidget);
    expect(find.text('Parameter Lingkungan Simulasi'), findsOneWidget);

    // Uji selector tema di Settings
    await tester.tap(find.text('Terang'));
    await tester.pumpAndSettle();

    // 6. Kembali ke Beranda
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Beranda'),
    ));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Alur Simulator Vertical Handover'), findsOneWidget);
  });
}
