import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/charging_inlet_sentinel_service.dart';
import 'package:evehicle_logbook/core/widgets/charging_inlet_sentinel_card.dart';

void main() {
  group('Loop 97: EV DC Fast Charging Port Inlet Thermal Sentinel Tests', () {
    const service = ChargingInletSentinelService();

    test('Locked inlet and cool terminal pins allow full charge current', () {
      const telemetry = ChargingInletTelemetry(
        plugStandard: EvPlugStandard.ccsCombo2,
        dcPinPositiveTempCelsius: 48.0,
        dcPinNegativeTempCelsius: 46.0,
        controlPilotDutyCyclePercent: 50.0,
        isMotorizedLockPinEngaged: true,
        currentAmperes: 350.0,
        chargingPowerKw: 150.0,
      );

      final result = service.evaluateInletSafety(
        vehicleId: 'EV-BUS-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(EvInletSafetyStatus.normal));
      expect(result.isSafe, isTrue);
      expect(result.allowableChargeCurrentAmperes, equals(350.0));
      expect(result.isImmediateEStopTriggered, isFalse);
    });

    test('Overheated terminal pin triggers emergency trip stop', () {
      const telemetry = ChargingInletTelemetry(
        plugStandard: EvPlugStandard.ccsCombo2,
        dcPinPositiveTempCelsius: 92.0, // Above 90°C thermal trip threshold
        dcPinNegativeTempCelsius: 85.0,
        controlPilotDutyCyclePercent: 50.0,
        isMotorizedLockPinEngaged: true,
        currentAmperes: 350.0,
        chargingPowerKw: 150.0,
      );

      final result = service.evaluateInletSafety(
        vehicleId: 'EV-BUS-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(EvInletSafetyStatus.emergencyTripStop));
      expect(result.isSafe, isFalse);
      expect(result.allowableChargeCurrentAmperes, equals(0.0));
      expect(result.isImmediateEStopTriggered, isTrue);
      expect(result.safetyAdvisory, contains('THERMAL OVERHEAT TRIP'));
    });

    testWidgets('AQIL: ChargingInletSentinelCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = ChargingInletTelemetry(
        plugStandard: EvPlugStandard.ccsCombo2,
        dcPinPositiveTempCelsius: 48.0,
        dcPinNegativeTempCelsius: 46.0,
        controlPilotDutyCyclePercent: 50.0,
        isMotorizedLockPinEngaged: true,
        currentAmperes: 350.0,
        chargingPowerKw: 150.0,
      );

      final result = service.evaluateInletSafety(
        vehicleId: 'EV-BUS-01',
        telemetry: telemetry,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChargingInletSentinelCard(
                result: result,
                onResetChargeSession: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ChargingInletSentinelCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
