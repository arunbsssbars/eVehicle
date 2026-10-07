import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/brake_friction_wear_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/brake_friction_wear_card.dart';

void main() {
  group('Loop 112: BrakeFrictionWearAuditorService & Card Tests', () {
    const service = BrakeFrictionWearAuditorService();

    test('Audit reports adequate lining when pad is thick and rotor is standard', () {
      const telemetry = BrakeLiningWearTelemetry(
        innerPadThicknessMm: 12.0,
        outerPadThicknessMm: 11.5,
        discRotorThicknessMm: 34.0,
        rotorDiscardLimitMm: 28.0,
        brakeApplicationsCount: 1540,
        peakBrakeRotorTemperatureCelsius: 180.0,
      );

      final result = service.auditBrakeFriction(
        vehicleId: 'VH-112-OK',
        telemetry: telemetry,
      );

      expect(result.status, BrakeFrictionWearStatus.adequateLiningThickness);
      expect(result.isSafeForRoad, isTrue);
      expect(result.isDangerousMetalContact, isFalse);
      expect(result.minPadMm, 11.5);
      expect(result.taperDeltaMm, closeTo(0.5, 0.01));
      expect(result.remainingLiningLifePercent, greaterThan(70.0));
    });

    test('Audit detects scheduled wear and caliper pin taper delta warning', () {
      const telemetry = BrakeLiningWearTelemetry(
        innerPadThicknessMm: 4.8,
        outerPadThicknessMm: 7.5,
        discRotorThicknessMm: 30.0,
        rotorDiscardLimitMm: 28.0,
        brakeApplicationsCount: 9200,
        peakBrakeRotorTemperatureCelsius: 290.0,
      );

      final result = service.auditBrakeFriction(
        vehicleId: 'VH-112-WARN',
        telemetry: telemetry,
      );

      expect(result.status, BrakeFrictionWearStatus.scheduledServiceThreshold);
      expect(result.isSafeForRoad, isFalse);
      expect(result.taperDeltaMm, closeTo(2.7, 0.01));
      expect(result.serviceAdvisory, contains('WARNING: Brake pad lining at 20% life'));
    });

    test('Audit flags critical metal backing plate contact when pad <= 3.2mm or rotor below discard', () {
      const telemetry = BrakeLiningWearTelemetry(
        innerPadThicknessMm: 2.9,
        outerPadThicknessMm: 3.1,
        discRotorThicknessMm: 26.5,
        rotorDiscardLimitMm: 28.0,
        brakeApplicationsCount: 16500,
        peakBrakeRotorTemperatureCelsius: 420.0,
      );

      final result = service.auditBrakeFriction(
        vehicleId: 'VH-112-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, BrakeFrictionWearStatus.criticalMetalOnMetalBackingPlateRisk);
      expect(result.isDangerousMetalContact, isTrue);
      expect(result.remainingLiningLifePercent, 0.0);
      expect(result.serviceAdvisory, contains('CRITICAL'));
    });

    testWidgets('BrakeFrictionWearCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool buttonClicked = false;
      const telemetry = BrakeLiningWearTelemetry(
        innerPadThicknessMm: 3.0,
        outerPadThicknessMm: 3.2,
        discRotorThicknessMm: 27.5,
        rotorDiscardLimitMm: 28.0,
        brakeApplicationsCount: 14000,
        peakBrakeRotorTemperatureCelsius: 380.0,
      );

      final result = service.auditBrakeFriction(
        vehicleId: 'TRUCK-BRAKE-009',
        telemetry: telemetry,
      );

      // Verify Compact 320px viewport with fontScale 1.5
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: BrakeFrictionWearCard(
                  result: result,
                  onSchedulePadReplacement: () {
                    buttonClicked = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Brake Pad Lining Sentry'), findsOneWidget);
      expect(find.textContaining('TRUCK-BRAKE-009'), findsOneWidget);
      expect(find.text('METAL CONTACT'), findsOneWidget);

      final scheduleBtn = find.text('Book Brake Pad & Rotor Service');
      expect(scheduleBtn, findsOneWidget);
      await tester.tap(scheduleBtn);
      expect(buttonClicked, isTrue);
    });
  });
}
