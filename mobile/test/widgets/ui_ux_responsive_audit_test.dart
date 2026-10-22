import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:project_handsign/core/application/application.dart';
import 'package:project_handsign/core/simulation/simulation.dart';
import 'package:project_handsign/widgets/active_network_selector_card.dart';
import 'package:project_handsign/widgets/algorithm_vs_baseline_card.dart';
import 'package:project_handsign/widgets/app_recommendation_card.dart';
import 'package:project_handsign/widgets/app_selector_sheet.dart';
import 'package:project_handsign/widgets/app_sla_detail_dialog.dart';
import 'package:project_handsign/widgets/circular_percentage_indicator.dart';

void main() {
  group('UI/UX Responsive Redesign & Text Overflow Audits', () {
    testWidgets('CircularPercentageIndicator renders symmetrically without exceptions across percentage ranges',
        (tester) async {
      for (final pct in [0.0, 15.0, 50.0, 85.0, 96.0, 100.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularPercentageIndicator(
                  percentage: pct,
                  size: 46,
                  strokeWidth: 4.5,
                  progressColor: Colors.green,
                  subtitle: 'QoE',
                ),
              ),
            ),
          ),
        );

        expect(find.text('${pct.toStringAsFixed(0)}%'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('AlgorithmVsBaselineCard renders cleanly without RenderFlex overflow on narrow 320px screen',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = SimulationController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<SimulationController>.value(
              value: controller,
              child: const SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: AlgorithmVsBaselineCard(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Komparasi Real-Time: RSS-Only vs Smart VHO'), findsOneWidget);
      expect(find.text('Jaringan Dipilih'), findsOneWidget);
      expect(find.text('Jaringan Aktif'), findsOneWidget);
      expect(find.text('Skor QoE Real-Time'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppRecommendationCard displays Pilih Aplikasi Spesifik button and telemetry cleanly', (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = SimulationController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<SimulationController>.value(
              value: controller,
              child: const SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: AppRecommendationCard(),
                ),
              ),
            ),
          ),
        ),
      );

      // Verify "Pilih Aplikasi Spesifik" button is present and prominent
      expect(find.text('Pilih Aplikasi Spesifik'), findsOneWidget);

      // Verify active app name is displayed
      expect(find.text(controller.activeAppProfile.name), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('AppSelectorSheet renders clean tiles and Detail dialog displays telecommunication standards',
        (tester) async {
      final controller = SimulationController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<SimulationController>.value(
              value: controller,
              child: const AppSelectorSheet(),
            ),
          ),
        ),
      );

      expect(find.text('Pilih Aplikasi Spesifik'), findsOneWidget);
      expect(find.text('Detail'), findsWidgets);
      expect(tester.takeException(), isNull);

      // Tap the first "Detail" button
      await tester.tap(find.text('Detail').first);
      await tester.pumpAndSettle();

      // Verify SLA standards dialog opens
      expect(find.text('Standar Telekomunikasi Acuan:'), findsOneWidget);
      expect(find.text('Mengapa Kebutuhan Aplikasi Ini Berbeda?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ActiveNetworkSelectorCard allows selecting connected network and renders on narrow screen',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = SimulationController(initialActiveNetworkId: '4g_lte');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<SimulationController>.value(
              value: controller,
              child: const SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: ActiveNetworkSelectorCard(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Pilih Jaringan yang Sedang Kamu Pakai'), findsOneWidget);
      expect(find.text('TERHUBUNG'), findsOneWidget);
      expect(find.text('4G'), findsOneWidget);
      expect(find.text('5G'), findsOneWidget);
      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
