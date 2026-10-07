import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/retarder_braking_service.dart';
import 'package:evehicle_logbook/core/widgets/retarder_braking_card.dart';

void main() {
  group('Loop 131: RetarderBrakingService & Card Tests', () {
    const service = RetarderBrakingService();

    test('Cool retarder fluid and full torque delivery reports nominal status', () {
      const telemetry = RetarderBrakingTelemetry(
        requestedRetarderTorqueNm: 2200.0,
        deliveredRetarderTorqueNm: 2180.0,
        retarderOilTemperatureCelsius: 98.0,
        transmissionCoolantInletTempCelsius: 88.0,
        rotorInternalFluidPressureKPa: 680.0,
        continuousBrakingDurationSeconds: 45.0,
      );

      final result = service.auditRetarder(
        vehicleId: 'MOUNTAIN-RIG-131-OK',
        telemetry: telemetry,
      );

      expect(result.status, RetarderBrakingStatus.retarderCoolNominal);
      expect(result.isRetarderEffective, isTrue);
      expect(result.isRetarderBoilingCritical, isFalse);
      expect(result.efficiencyPercent, closeTo(99.1, 0.5));
      expect(result.mountainSafetyAdvisory, contains('NOMINAL'));
    });

    test('High oil temperature (>130C) triggers thermal choke derate warning', () {
      const telemetry = RetarderBrakingTelemetry(
        requestedRetarderTorqueNm: 2500.0,
        deliveredRetarderTorqueNm: 1900.0,
        retarderOilTemperatureCelsius: 138.0,
        transmissionCoolantInletTempCelsius: 98.0,
        rotorInternalFluidPressureKPa: 520.0,
        continuousBrakingDurationSeconds: 180.0,
      );

      final result = service.auditRetarder(
        vehicleId: 'MOUNTAIN-RIG-131-WARN',
        telemetry: telemetry,
      );

      expect(result.status, RetarderBrakingStatus.thermalChokeDerateWarning);
      expect(result.isRetarderEffective, isFalse);
      expect(result.efficiencyPercent, 76.0);
      expect(result.mountainSafetyAdvisory, contains('WARNING: Retarder thermal absorption throttling'));
    });

    test('Boiling oil (>=155C) or rotor cavitation triggers critical brake fade hazard', () {
      const telemetry = RetarderBrakingTelemetry(
        requestedRetarderTorqueNm: 2800.0,
        deliveredRetarderTorqueNm: 900.0,
        retarderOilTemperatureCelsius: 160.0,
        transmissionCoolantInletTempCelsius: 112.0,
        rotorInternalFluidPressureKPa: 280.0,
        continuousBrakingDurationSeconds: 320.0,
      );

      final result = service.auditRetarder(
        vehicleId: 'MOUNTAIN-RIG-131-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, RetarderBrakingStatus.criticalRotorCavitationOilFireHazard);
      expect(result.isRetarderBoilingCritical, isTrue);
      expect(result.mountainSafetyAdvisory, contains('CRITICAL DOWNHILL BRAKE FADE'));
    });

    testWidgets('RetarderBrakingCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool downshiftClicked = false;
      const telemetry = RetarderBrakingTelemetry(
        requestedRetarderTorqueNm: 2400.0,
        deliveredRetarderTorqueNm: 1800.0,
        retarderOilTemperatureCelsius: 142.0,
        transmissionCoolantInletTempCelsius: 102.0,
        rotorInternalFluidPressureKPa: 500.0,
        continuousBrakingDurationSeconds: 210.0,
      );

      final result = service.auditRetarder(
        vehicleId: 'ALPS-HAULER-99',
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
                child: RetarderBrakingCard(
                  result: result,
                  onDownshiftEngineRpm: () {
                    downshiftClicked = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Driveline Retarder Sentry'), findsOneWidget);
      expect(find.textContaining('ALPS-HAULER-99'), findsOneWidget);
      expect(find.text('THERMAL CHOKE'), findsOneWidget);

      final downshiftBtn = find.text('Downshift Gear to Boost Water Flow');
      expect(downshiftBtn, findsOneWidget);
      await tester.tap(downshiftBtn);
      expect(downshiftClicked, isTrue);
    });
  });
}
