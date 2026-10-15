import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_handsign/main.dart';

void main() {
  testWidgets('App navigation shell boots and switches tabs cleanly', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // 1. Verifikasi berada di Beranda (HomeScreen)
    expect(find.text('WMC Simulator'), findsOneWidget);
    expect(find.text('Alur Simulator Vertical Handover'), findsOneWidget);
    expect(find.text('Menu Utama'), findsOneWidget);

    // 2. Navigasi ke Tab Simulasi (MonitorScreen)
    await tester.tap(find.byIcon(Icons.sensors_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Posisi & Mobilitas Pengguna'), findsOneWidget);
    expect(find.text('KEPUTUSAN SAAT INI (ADVISORY)'), findsOneWidget);

    // 3. Navigasi ke Tab Hasil (ResultsScreen)
    await tester.tap(find.byIcon(Icons.analytics_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan Metrik Simulasi'), findsOneWidget);
    expect(find.text('Perbandingan Metode (Fuzzy-TOPSIS vs Baseline)'), findsOneWidget);

    // 4. Navigasi ke Tab Pengaturan (SettingsScreen)
    await tester.tap(find.byIcon(Icons.tune_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Kelas Aplikasi Aktif (User Preference)'), findsOneWidget);
    expect(find.text('Parameter Lingkungan Simulasi'), findsOneWidget);

    // 5. Kembali ke Beranda
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Alur Simulator Vertical Handover'), findsOneWidget);
  });
}
