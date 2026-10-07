import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/ultrasonic_fuel_theft_guard_service.dart';
import 'package:evehicle_logbook/core/widgets/ultrasonic_fuel_theft_guard_card.dart';

void main() {
  group('Loop 99: Ultrasonic Fuel Level & Siphon Theft Guard Tests', () {
    const service = UltrasonicFuelTheftGuardService();

    test('Parked vehicle with sudden 40L drop triggers illicit siphon theft alarm', () {
      final now = DateTime(2026, 10, 6, 2, 0);
      final baseline = UltrasonicFuelSensorSample(
        timestamp: now,
        fuelLevelMillimeters: 500.0,
        computedVolumeLitres: 280.0,
        fuelTemperatureCelsius: 22.0,
        vehicleSpeedKmh: 0.0,
      );

      final current = UltrasonicFuelSensorSample(
        timestamp: now.add(const Duration(minutes: 15)),
        fuelLevelMillimeters: 420.0,
        computedVolumeLitres: 235.0, // 45L drop while stationary
        fuelTemperatureCelsius: 22.0,
        vehicleSpeedKmh: 0.0,
      );

      final result = service.analyzeFuelEvent(
        vehicleId: 'TRK-DIESEL-01',
        baselineSample: baseline,
        currentSample: current,
      );

      expect(result.classification, equals(FuelEventClassification.illicitSiphonTheft));
      expect(result.isTheftAlarmTriggered, isTrue);
      expect(result.volumeDeltaLitres, equals(-45.0));
      expect(result.alarmSummary, contains('CRITICAL ALARM: Sudden fuel drain'));
    });

    test('Legitimate refueling at fuel pump verifies without alarm', () {
      final now = DateTime(2026, 10, 6, 9, 0);
      final baseline = UltrasonicFuelSensorSample(
        timestamp: now,
        fuelLevelMillimeters: 150.0,
        computedVolumeLitres: 80.0,
        fuelTemperatureCelsius: 24.0,
        vehicleSpeedKmh: 0.0,
      );

      final current = UltrasonicFuelSensorSample(
        timestamp: now.add(const Duration(minutes: 10)),
        fuelLevelMillimeters: 520.0,
        computedVolumeLitres: 300.0, // +220L refuel
        fuelTemperatureCelsius: 23.0,
        vehicleSpeedKmh: 0.0,
      );

      final result = service.analyzeFuelEvent(
        vehicleId: 'TRK-DIESEL-01',
        baselineSample: baseline,
        currentSample: current,
      );

      expect(result.classification, equals(FuelEventClassification.legitimateRefueling));
      expect(result.isTheftAlarmTriggered, isFalse);
      expect(result.volumeDeltaLitres, equals(220.0));
    });

    testWidgets('AQIL: UltrasonicFuelTheftGuardCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime(2026, 10, 6, 9, 0);
      final baseline = UltrasonicFuelSensorSample(
        timestamp: now,
        fuelLevelMillimeters: 400.0,
        computedVolumeLitres: 220.0,
        fuelTemperatureCelsius: 22.0,
        vehicleSpeedKmh: 0.0,
      );
      final current = UltrasonicFuelSensorSample(
        timestamp: now.add(const Duration(minutes: 5)),
        fuelLevelMillimeters: 395.0,
        computedVolumeLitres: 218.0,
        fuelTemperatureCelsius: 22.0,
        vehicleSpeedKmh: 0.0,
      );

      final result = service.analyzeFuelEvent(
        vehicleId: 'TRK-DIESEL-01',
        baselineSample: baseline,
        currentSample: current,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: UltrasonicFuelTheftGuardCard(
                result: result,
                onDispatchSecurityAlert: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(UltrasonicFuelTheftGuardCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
