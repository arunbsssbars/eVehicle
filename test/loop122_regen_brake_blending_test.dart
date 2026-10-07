import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/regen_brake_blending_service.dart';
import 'package:evehicle_logbook/core/widgets/regen_brake_blending_card.dart';

void main() {
  group('Loop 122: RegenBrakeBlendingService & Card Tests', () {
    const service = RegenBrakeBlendingService();

    test('Optimal regen recovery with warm battery reports normal blend status', () {
      const telemetry = RegenBrakeBlendingTelemetry(
        requestedBrakingDecelerationMPerS2: 1.8,
        electricMotorRegenTorqueNm: -650.0,
        foundationAirFrictionTorqueNm: -250.0,
        batteryStateOfChargePercent: 65.0,
        batteryPackTemperatureCelsius: 28.0,
        regenInverterBackEmfVolts: 720.0,
        maxPermissibleBatteryChargeCurrentAmps: 220.0,
      );

      final result = service.auditBlending(
        vehicleId: 'EV-REGEN-122-OK',
        telemetry: telemetry,
      );

      expect(result.status, RegenBrakeBlendingStatus.regenBlendOptimal);
      expect(result.isRegenOptimal, isTrue);
      expect(result.isOvervoltageCritical, isFalse);
      expect(result.regenRatioPercent, closeTo(72.2, 0.5));
      expect(result.blendAdvisory, contains('NOMINAL'));
    });

    test('Cold battery or high SOC triggers regen taper warning', () {
      const telemetry = RegenBrakeBlendingTelemetry(
        requestedBrakingDecelerationMPerS2: 2.2,
        electricMotorRegenTorqueNm: -150.0,
        foundationAirFrictionTorqueNm: -750.0,
        batteryStateOfChargePercent: 94.0,
        batteryPackTemperatureCelsius: 1.5,
        regenInverterBackEmfVolts: 790.0,
        maxPermissibleBatteryChargeCurrentAmps: 40.0,
      );

      final result = service.auditBlending(
        vehicleId: 'EV-REGEN-122-WARN',
        telemetry: telemetry,
      );

      expect(result.status, RegenBrakeBlendingStatus.regenTorqueTaperColdBatteryWarning);
      expect(result.isRegenOptimal, isFalse);
      expect(result.blendAdvisory, contains('WARNING: Battery charge acceptance restricted'));
    });

    test('Inverter back-EMF spike (>840V) triggers critical handoff fault', () {
      const telemetry = RegenBrakeBlendingTelemetry(
        requestedBrakingDecelerationMPerS2: 3.0,
        electricMotorRegenTorqueNm: -900.0,
        foundationAirFrictionTorqueNm: -400.0,
        batteryStateOfChargePercent: 88.0,
        batteryPackTemperatureCelsius: 30.0,
        regenInverterBackEmfVolts: 865.0,
        maxPermissibleBatteryChargeCurrentAmps: 180.0,
      );

      final result = service.auditBlending(
        vehicleId: 'EV-REGEN-122-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, RegenBrakeBlendingStatus.criticalBackEmfOvervoltageFrictionBrakeLoss);
      expect(result.isOvervoltageCritical, isTrue);
      expect(result.blendAdvisory, contains('CRITICAL HAZARD: Inverter DC-bus back-EMF spike'));
    });

    testWidgets('RegenBrakeBlendingCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool preCharged = false;
      const telemetry = RegenBrakeBlendingTelemetry(
        requestedBrakingDecelerationMPerS2: 2.8,
        electricMotorRegenTorqueNm: -800.0,
        foundationAirFrictionTorqueNm: -300.0,
        batteryStateOfChargePercent: 85.0,
        batteryPackTemperatureCelsius: 26.0,
        regenInverterBackEmfVolts: 850.0,
        maxPermissibleBatteryChargeCurrentAmps: 160.0,
      );

      final result = service.auditBlending(
        vehicleId: 'E-FREIGHT-10',
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
                child: RegenBrakeBlendingCard(
                  result: result,
                  onPreChargeFoundationBrakes: () {
                    preCharged = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Regen Brake Blend Sentry'), findsOneWidget);
      expect(find.textContaining('E-FREIGHT-10'), findsOneWidget);
      expect(find.text('HANDOFF FAULT'), findsOneWidget);

      final preChargeBtn = find.text('Pre-Charge Foundation Friction Brakes');
      expect(preChargeBtn, findsOneWidget);
      await tester.tap(preChargeBtn);
      expect(preCharged, isTrue);
    });
  });
}
