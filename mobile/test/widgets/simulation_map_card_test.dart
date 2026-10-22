import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:project_handsign/core/mobility/mobility_models.dart';
import 'package:project_handsign/core/simulation/simulation.dart';
import 'package:project_handsign/widgets/simulation_map_card.dart';

void main() {
  testWidgets('SimulationMapCard renders without throwing exceptions in normal and narrow sizes', (tester) async {
    final controller = SimulationController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<SimulationController>.value(
            value: controller,
            child: const SingleChildScrollView(
              child: SimulationMapCard(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Posisi & Mobilitas Pengguna'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Test stepping
    controller.step(1.0);
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Test fast-forward
    controller.fastForward(50);
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Test toggling pattern
    controller.setMobilityPattern(MobilityPattern.uniformRandom);
    await tester.pump();
    expect(tester.takeException(), isNull);

    controller.setMobilityPattern(MobilityPattern.naturalCircuit);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('SimulationMapCard on narrow 320px screen does not overflow', (tester) async {
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
              child: SimulationMapCard(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('SimulationMapCard 1000 steps stress test does not produce NaN or errors', (tester) async {
    final controller = SimulationController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<SimulationController>.value(
            value: controller,
            child: const SingleChildScrollView(
              child: SimulationMapCard(),
            ),
          ),
        ),
      ),
    );

    for (int i = 0; i < 500; i++) {
      controller.step(1.0);
      expect(controller.userPosition.x.isNaN, isFalse);
      expect(controller.userPosition.y.isNaN, isFalse);
      expect(controller.velocityMps.isNaN, isFalse);
      if (i % 50 == 0) {
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    }
  });
}
