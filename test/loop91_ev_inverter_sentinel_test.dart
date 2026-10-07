import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/ev_inverter_motor_sentinel_service.dart';
import 'package:evehicle_logbook/core/widgets/ev_inverter_motor_sentinel_card.dart';

void main() {
  group('Loop 91: EV Inverter & Motor Thermal Sentinel Tests', () {
    const service = EvInverterMotorSentinelService();

    test('Nominal inverter and motor temperatures maintain 100% torque capability', () {
      const telemetry = EvInverterMotorTelemetry(
        motorType: EvMotorType.permanentMagnetSynchronous,
        statorWindingTempCelsius: 75.0,
        inverterIgbtTempCelsius: 65.0,
        rotorSpeedRpm: 3200.0,
        torqueDemandNm: 250.0,
        actualDeliveredTorqueNm: 250.0,
        dcBusVoltage: 400.0,
        phaseCurrentAmperes: 125.0,
      );

      final result = service.evaluateInverterHealth(
        vehicleId: 'EV-TRK-88',
        telemetry: telemetry,
      );

      expect(result.status, equals(EvInverterHealthStatus.nominal));
      expect(result.isSafe, isTrue);
      expect(result.allowableTorquePercentage, equals(100.0));
      expect(result.isCoolantPumpBoostRequired, isFalse);
    });

    test('Excessive IGBT temperature triggers thermal derating and coolant boost', () {
      const telemetry = EvInverterMotorTelemetry(
        motorType: EvMotorType.permanentMagnetSynchronous,
        statorWindingTempCelsius: 118.0,
        inverterIgbtTempCelsius: 98.0, // Over 95°C derate warning
        rotorSpeedRpm: 4500.0,
        torqueDemandNm: 350.0,
        actualDeliveredTorqueNm: 245.0,
        dcBusVoltage: 380.0,
        phaseCurrentAmperes: 180.0,
      );

      final result = service.evaluateInverterHealth(
        vehicleId: 'EV-TRK-88',
        telemetry: telemetry,
      );

      expect(result.status, equals(EvInverterHealthStatus.thermalDeratingActive));
      expect(result.isSafe, isFalse);
      expect(result.allowableTorquePercentage, equals(70.0));
      expect(result.isCoolantPumpBoostRequired, isTrue);
    });

    testWidgets('AQIL: EvInverterMotorSentinelCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = EvInverterMotorTelemetry(
        motorType: EvMotorType.permanentMagnetSynchronous,
        statorWindingTempCelsius: 75.0,
        inverterIgbtTempCelsius: 65.0,
        rotorSpeedRpm: 3200.0,
        torqueDemandNm: 250.0,
        actualDeliveredTorqueNm: 250.0,
        dcBusVoltage: 400.0,
        phaseCurrentAmperes: 125.0,
      );

      final result = service.evaluateInverterHealth(
        vehicleId: 'EV-TRK-88',
        telemetry: telemetry,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EvInverterMotorSentinelCard(
                result: result,
                onActivateCoolantBoost: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(EvInverterMotorSentinelCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
