import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/steering_hydraulic_assist_service.dart';
import 'package:evehicle_logbook/core/widgets/steering_assist_guard_card.dart';

void main() {
  group('Loop 110: Commercial Power Steering Hydraulic Assist Sentinel Tests', () {
    const service = SteeringHydraulicAssistService();

    test('Healthy steering assist pressure and low steering effort passes inspection', () {
      const telemetry = SteeringHydraulicTelemetry(
        pumpDischargePressurePsi: 1200.0,
        returnFluidTemperatureCelsius: 72.0,
        steeringWheelTorqueNm: 4.5,
        fluidLevelPercent: 90.0,
        pumpDriveBeltSlipPercent: 2.0,
      );

      final result = service.auditSteeringAssist(
        vehicleId: 'STR-TRK-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(SteeringHydraulicStatus.normalAssistPressure));
      expect(result.isSafeToDrive, isTrue);
      expect(result.isLossOfSteeringAssist, isFalse);
      expect(result.safetyAdvisory, contains('NOMINAL'));
    });

    test('Loss of pump discharge pressure with high driver effort flags critical assist failure', () {
      const telemetry = SteeringHydraulicTelemetry(
        pumpDischargePressurePsi: 220.0, // Loss of hydraulic boost
        returnFluidTemperatureCelsius: 118.0,
        steeringWheelTorqueNm: 22.0, // Manual wrestling steering wheel
        fluidLevelPercent: 10.0, // Fluid lost
        pumpDriveBeltSlipPercent: 35.0,
      );

      final result = service.auditSteeringAssist(
        vehicleId: 'STR-TRK-02',
        telemetry: telemetry,
      );

      expect(result.status, equals(SteeringHydraulicStatus.criticalLossOfAssistOrBeltSlip));
      expect(result.isSafeToDrive, isFalse);
      expect(result.isLossOfSteeringAssist, isTrue);
      expect(result.safetyAdvisory, contains('CRITICAL'));
    });

    testWidgets('AQIL: SteeringAssistGuardCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = SteeringHydraulicTelemetry(
        pumpDischargePressurePsi: 1150.0,
        returnFluidTemperatureCelsius: 70.0,
        steeringWheelTorqueNm: 5.0,
        fluidLevelPercent: 88.0,
        pumpDriveBeltSlipPercent: 3.0,
      );
      final result = service.auditSteeringAssist(vehicleId: 'STR-320', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SteeringAssistGuardCard(result: result),
            ),
          ),
        ),
      );

      expect(find.text('Power Steering Hydraulic Sentry'), findsOneWidget);
      expect(find.text('ASSIST HEALTHY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AQIL: SteeringAssistGuardCard scales gracefully under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = SteeringHydraulicTelemetry(
        pumpDischargePressurePsi: 200.0,
        returnFluidTemperatureCelsius: 120.0,
        steeringWheelTorqueNm: 25.0,
        fluidLevelPercent: 8.0,
        pumpDriveBeltSlipPercent: 40.0,
      );
      final result = service.auditSteeringAssist(vehicleId: 'STR-FONT', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: SteeringAssistGuardCard(result: result),
              ),
            ),
          ),
        ),
      );

      expect(find.text('LOSS OF ASSIST'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
