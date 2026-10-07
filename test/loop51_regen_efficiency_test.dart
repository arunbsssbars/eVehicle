import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/regen_efficiency_service.dart';
import 'package:evehicle_logbook/core/widgets/regen_efficiency_card.dart';

void main() {
  group('Loop 51 - Regenerative Braking KERS Tests', () {
    const service = RegenEfficiencyService();

    test('evaluateDeceleration returns baseline for stationary or non-braking state', () {
      const event = DecelerationBrakeEvent(
        initialSpeedKmh: 60.0,
        finalSpeedKmh: 60.0,
        durationSeconds: 0.0,
        vehicleMassKg: 2800.0,
        energyRecapturedKwh: 0.0,
      );

      final audit = service.evaluateDeceleration(event);
      expect(audit.grade, RegenEfficiencyGrade.excellentOnePedal);
      expect(audit.totalKineticEnergyKwh, 0.0);
      expect(audit.recapturedEnergyKwh, 0.0);
    });

    test('evaluateDeceleration identifies excellent one-pedal kinetic recapture', () {
      // 80 km/h to 20 km/h deceleration in 8 seconds for a 2500 kg delivery EV
      const event = DecelerationBrakeEvent(
        initialSpeedKmh: 80.0,
        finalSpeedKmh: 20.0,
        durationSeconds: 8.0,
        vehicleMassKg: 2500.0,
        energyRecapturedKwh: 0.145, // High recovery
      );

      final audit = service.evaluateDeceleration(event);
      expect(audit.grade, RegenEfficiencyGrade.excellentOnePedal);
      expect(audit.captureEfficiencyPercent, greaterThan(80.0));
      expect(audit.addedRangeMeters, greaterThan(500.0));
    });

    test('evaluateDeceleration flags friction heavy waste on hard panic braking', () {
      const event = DecelerationBrakeEvent(
        initialSpeedKmh: 100.0,
        finalSpeedKmh: 0.0,
        durationSeconds: 3.0, // Hard abrupt brake
        vehicleMassKg: 3000.0,
        energyRecapturedKwh: 0.04, // Calipers absorbed most energy
      );

      final audit = service.evaluateDeceleration(event);
      expect(audit.grade, RegenEfficiencyGrade.criticalWastedHeat);
      expect(audit.frictionLostEnergyKwh, greaterThan(audit.recapturedEnergyKwh));
    });

    testWidgets('RegenEfficiencyCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = RegenEfficiencyAudit(
        totalKineticEnergyKwh: 0.165,
        recapturedEnergyKwh: 0.142,
        frictionLostEnergyKwh: 0.023,
        captureEfficiencyPercent: 86.1,
        addedRangeMeters: 788.0,
        grade: RegenEfficiencyGrade.excellentOnePedal,
        coachingTip: 'EXCELLENT RECOVERY: Smooth one-pedal modulation maximized kinetic recapture.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegenEfficiencyCard(
              audit: audit,
              onAdjustRegenProfile: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Regenerative KERS Efficiency'), findsOneWidget);
      expect(find.text('EXCELLENT'), findsOneWidget);
      expect(find.text('Adjust Regenerative Braking Profile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RegenEfficiencyCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = RegenEfficiencyAudit(
        totalKineticEnergyKwh: 0.220,
        recapturedEnergyKwh: 0.060,
        frictionLostEnergyKwh: 0.160,
        captureEfficiencyPercent: 27.3,
        addedRangeMeters: 333.0,
        grade: RegenEfficiencyGrade.criticalWastedHeat,
        coachingTip: 'EMERGENCY / ABRUPT STOP: Over 60% of kinetic energy wasted into brake pads.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: RegenEfficiencyCard(audit: audit),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WASTED HEAT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
