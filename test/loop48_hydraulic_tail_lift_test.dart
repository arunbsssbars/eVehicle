import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/hydraulic_tail_lift_service.dart';
import 'package:evehicle_logbook/core/widgets/hydraulic_tail_lift_card.dart';

void main() {
  group('Loop 48 - Hydraulic Tail-Lift & Crane Wear Tests', () {
    const service = HydraulicTailLiftService();

    test('evaluateHealth reports normal operational status for low duty cycle', () {
      const sample = HydraulicTelemetrySample(
        cumulativeCycles: 3500,
        cumulativeLiftedTons: 1200.0,
        hydraulicFluidTempCelsius: 48.0,
        peakOperatingPressureBar: 205.0,
        pressureDropRateBarPerSec: 0.2,
        fluidOperatingHours: 250,
      );

      final audit = service.evaluateHealth(sample);
      expect(audit.status, HydraulicWearStatus.normalOperational);
      expect(audit.fluidFlushRequired, isFalse);
      expect(audit.safetyLockoutRequired, isFalse);
      expect(audit.sealWearPercentage, lessThan(20.0));
    });

    test('evaluateHealth triggers mandatory lockout on severe cylinder bypass leak', () {
      const sample = HydraulicTelemetrySample(
        cumulativeCycles: 15000,
        cumulativeLiftedTons: 6000.0,
        hydraulicFluidTempCelsius: 65.0,
        peakOperatingPressureBar: 180.0,
        pressureDropRateBarPerSec: 4.5, // Dangerous bypass leak
        fluidOperatingHours: 600,
      );

      final audit = service.evaluateHealth(sample);
      expect(audit.status, HydraulicWearStatus.sealOverhaulMandatory);
      expect(audit.safetyLockoutRequired, isTrue);
    });

    test('evaluateHealth detects fluid thermal breakdown above 82C or 1000 hrs', () {
      const sample = HydraulicTelemetrySample(
        cumulativeCycles: 12000,
        cumulativeLiftedTons: 4000.0,
        hydraulicFluidTempCelsius: 88.0, // Overheated oil
        peakOperatingPressureBar: 200.0,
        pressureDropRateBarPerSec: 0.5,
        fluidOperatingHours: 1100,
      );

      final audit = service.evaluateHealth(sample);
      expect(audit.status, HydraulicWearStatus.fluidDegraded);
      expect(audit.fluidFlushRequired, isTrue);
    });

    testWidgets('HydraulicTailLiftCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = HydraulicHealthAudit(
        sealWearPercentage: 88.5,
        remainingCyclesToOverhaul: 1200,
        status: HydraulicWearStatus.sealOverhaulMandatory,
        statusSummary: 'CRITICAL HYDRAULIC LEAK: Severe cylinder bypass.',
        fluidFlushRequired: false,
        safetyLockoutRequired: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HydraulicTailLiftCard(
              audit: audit,
              currentCycles: 28800,
              onScheduleService: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hydraulic Tail-Lift Duty Wear'), findsOneWidget);
      expect(find.text('LOCKOUT HAZARD'), findsOneWidget);
      expect(find.text('Schedule Emergency Hydraulic Service'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HydraulicTailLiftCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = HydraulicHealthAudit(
        sealWearPercentage: 15.0,
        remainingCyclesToOverhaul: 25000,
        status: HydraulicWearStatus.normalOperational,
        statusSummary: 'HYDRAULIC INTEGRITY HEALTHY: Pressure holding stable.',
        fluidFlushRequired: false,
        safetyLockoutRequired: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: HydraulicTailLiftCard(
                audit: audit,
                currentCycles: 5000,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HEALTHY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
