import 'package:flutter_test/flutter_test.dart';
import 'package:project_handsign/core/mobility/mobility.dart';

void main() {
  group('Random Waypoint Model Tests', () {
    test('1. Initial position berada di dalam area', () {
      const config = RandomWaypointConfig(
        areaWidth: 400.0,
        areaHeight: 300.0,
      );
      final gen = RandomWaypointGenerator(config: config);

      expect(gen.currentState.position.x, equals(200.0));
      expect(gen.currentState.position.y, equals(150.0));
      expect(config.contains(gen.currentState.position), isTrue);

      const customConfig = RandomWaypointConfig(
        areaWidth: 500.0,
        areaHeight: 500.0,
        initialPosition: MobilityPoint(75.0, 80.0),
      );
      final customGen = RandomWaypointGenerator(config: customConfig);
      expect(customGen.currentState.position.x, equals(75.0));
      expect(customGen.currentState.position.y, equals(80.0));
    });

    test('2. Waypoint selalu berada di dalam boundary', () {
      const config = RandomWaypointConfig(
        areaWidth: 300.0,
        areaHeight: 200.0,
        seed: 42,
      );
      final gen = RandomWaypointGenerator(config: config);

      for (int i = 0; i < 50; i++) {
        gen.step(1.0);
        final wp = gen.currentState.currentWaypoint;
        expect(wp.x, greaterThanOrEqualTo(0.0));
        expect(wp.x, lessThanOrEqualTo(300.0));
        expect(wp.y, greaterThanOrEqualTo(0.0));
        expect(wp.y, lessThanOrEqualTo(200.0));
      }
    });

    test('3. Speed berada dalam rentang min-max speed', () {
      const config = RandomWaypointConfig(
        minSpeed: 1.5,
        maxSpeed: 4.5,
        seed: 123,
      );
      final gen = RandomWaypointGenerator(config: config);

      for (int i = 0; i < 60; i++) {
        gen.step(1.0);
        final state = gen.currentState;
        if (state.status == MobilityMovementStatus.moving) {
          expect(state.currentSpeed, greaterThanOrEqualTo(1.499));
          expect(state.currentSpeed, lessThanOrEqualTo(4.501));
        } else {
          expect(state.currentSpeed, equals(0.0));
        }
      }
    });

    test('4. Posisi berubah ketika state moving', () {
      const config = RandomWaypointConfig(
        areaWidth: 1000.0,
        areaHeight: 1000.0,
        initialPosition: MobilityPoint(0.0, 0.0),
        minSpeed: 5.0,
        maxSpeed: 5.0,
        seed: 99,
      );
      final gen = RandomWaypointGenerator(config: config);

      final initialPos = gen.currentState.position;
      final nextState = gen.step(1.0);

      expect(nextState.status, equals(MobilityMovementStatus.moving));
      expect(initialPos.distanceTo(nextState.position), greaterThan(0.1));
    });

    test('5. Posisi tidak berubah ketika state paused', () {
      const config = RandomWaypointConfig(
        areaWidth: 100.0,
        areaHeight: 100.0,
        initialPosition: MobilityPoint(50.0, 50.0),
        minSpeed: 100.0,
        maxSpeed: 100.0,
        minPauseTime: 5.0,
        maxPauseTime: 5.0,
        seed: 1,
      );
      final gen = RandomWaypointGenerator(config: config);

      final reachedState = gen.step(1.0);
      expect(reachedState.status, equals(MobilityMovementStatus.paused));

      final pausedPosition = reachedState.position;
      final secondPausedState = gen.step(1.0);

      expect(secondPausedState.status, equals(MobilityMovementStatus.paused));
      expect(secondPausedState.position, equals(pausedPosition));
      expect(secondPausedState.currentSpeed, equals(0.0));
    });

    test('6. Pengguna mencapai waypoint sebelum memilih waypoint baru', () {
      const config = RandomWaypointConfig(
        areaWidth: 500.0,
        areaHeight: 500.0,
        initialPosition: MobilityPoint(0.0, 0.0),
        minSpeed: 10.0,
        maxSpeed: 10.0,
        minPauseTime: 2.0,
        maxPauseTime: 2.0,
        seed: 77,
      );
      final gen = RandomWaypointGenerator(config: config);
      final targetWaypoint = gen.currentState.currentWaypoint;

      bool reached = false;
      for (int step = 0; step < 100; step++) {
        final state = gen.step(1.0);
        if (state.status == MobilityMovementStatus.paused) {
          if (state.position.distanceTo(targetWaypoint) < 1e-4) {
            reached = true;
            break;
          }
        }
      }
      expect(reached, isTrue);
    });

    test('7. Pengguna tidak keluar dari area simulasi', () {
      const config = RandomWaypointConfig(
        areaWidth: 100.0,
        areaHeight: 100.0,
        minSpeed: 25.0,
        maxSpeed: 30.0,
        seed: 33,
      );
      final gen = RandomWaypointGenerator(config: config);

      for (int i = 0; i < 200; i++) {
        final state = gen.step(0.5);
        expect(state.position.x, inInclusiveRange(0.0, 100.0));
        expect(state.position.y, inInclusiveRange(0.0, 100.0));
      }
    });

    test('8. Delta time menghasilkan perpindahan yang sesuai', () {
      const config = RandomWaypointConfig(
        areaWidth: 10000.0,
        areaHeight: 10000.0,
        initialPosition: MobilityPoint(0.0, 0.0),
        minSpeed: 4.0,
        maxSpeed: 4.0,
        seed: 10,
      );
      final gen = RandomWaypointGenerator(config: config);
      final p0 = gen.currentState.position;
      const dt = 2.5;

      final p1 = gen.step(dt).position;
      final displacement = p0.distanceTo(p1);

      expect(displacement, closeTo(4.0 * dt, 1e-4));
    });

    test('9. Random seed menghasilkan trajectory yang reproducible', () {
      const config = RandomWaypointConfig(seed: 2026);
      final genA = RandomWaypointGenerator(config: config);
      final genB = RandomWaypointGenerator(config: config);

      for (int i = 0; i < 25; i++) {
        final stateA = genA.step(1.0);
        final stateB = genB.step(1.0);

        expect(stateA.position.x, closeTo(stateB.position.x, 1e-6));
        expect(stateA.position.y, closeTo(stateB.position.y, 1e-6));
        expect(stateA.currentSpeed, closeTo(stateB.currentSpeed, 1e-6));
        expect(stateA.status, equals(stateB.status));
      }
    });

    test('10. Modul dapat dihentikan dan di-reset dengan benar', () {
      const config = RandomWaypointConfig(
        areaWidth: 500.0,
        areaHeight: 500.0,
        initialPosition: MobilityPoint(100.0, 100.0),
        seed: 55,
      );
      final controller = MobilityController(
        rwpConfig: config,
        initialMode: MobilitySpeedMode.randomWaypoint,
      );

      controller.stepSimulation(1.0);
      controller.stepSimulation(1.0);
      expect(controller.mobilityState.elapsedSeconds, equals(2.0));

      controller.resetSimulation();
      expect(controller.mobilityState.elapsedSeconds, equals(0.0));
      expect(controller.mobilityState.position.x, equals(100.0));
      expect(controller.mobilityState.position.y, equals(100.0));
      expect(controller.isRunning, isFalse);
    });

    test('11. wifiDwell menjaga waypoint tetap berada di dalam Coworking Cafe Hub', () {
      final gen = RandomWaypointGenerator();
      gen.setPattern(MobilityPattern.wifiDwell);

      for (int i = 0; i < 50; i++) {
        final state = gen.step(2.0);
        final distToWifi = state.currentWaypoint.distanceTo(const MobilityPoint(120.0, 120.0));
        // Waypoint selalu di dalam radius 45m dari AP (120, 120)
        expect(distToWifi, lessThanOrEqualTo(45.0));
        expect(distToWifi, greaterThanOrEqualTo(5.0));
      }
    });

    test('12. fiveGOpenPlaza dan fourGObstacleShelter menghasilkan waypoint sesuai zona', () {
      final gen = RandomWaypointGenerator();

      gen.setPattern(MobilityPattern.fiveGOpenPlaza);
      final p5g = gen.step(1.0).currentWaypoint;
      expect(p5g.x, inInclusiveRange(200.0, 280.0));
      expect(p5g.y, inInclusiveRange(190.0, 260.0));

      gen.setPattern(MobilityPattern.fourGObstacleShelter);
      final p4g = gen.step(1.0).currentWaypoint;
      expect(p4g.x, inInclusiveRange(355.0, 415.0));
      expect(p4g.y, inInclusiveRange(335.0, 395.0));
    });
  });
}
