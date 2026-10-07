import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/differential_vibration_diagnoser_service.dart';
import 'package:evehicle_logbook/core/widgets/differential_vibration_diagnoser_card.dart';

void main() {
  group('Loop 96: Differential Crown-Wheel & Pinion Backlash Diagnoser Tests', () {
    const service = DifferentialVibrationDiagnoserService();

    test('Healthy hypoid gearset with low vibration reports normal', () {
      const telemetry = DifferentialVibrationTelemetry(
        diffType: DifferentialType.singleReductionHypoid,
        oilSumpTemperatureCelsius: 75.0,
        crownWheelPinionVibrationMmSec: 2.1,
        magneticDrainPlugMetalFinesGrams: 0.5,
        gearToothMeshingFrequencyHz: 450.0,
        drivelineBacklashDegrees: 1.2,
        accumulatedKilometers: 50000.0,
      );

      final result = service.evaluateDifferential(
        vehicleId: 'TRK-DIFF-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(DifferentialHealthStatus.normal));
      expect(result.isSafe, isTrue);
      expect(result.isOverhaulMandatory, isFalse);
      expect(result.gearMeshingVibrationMmSec, equals(2.1));
    });

    test('Severe gear tooth chipping and ferrous spalling triggers overhaul', () {
      const telemetry = DifferentialVibrationTelemetry(
        diffType: DifferentialType.singleReductionHypoid,
        oilSumpTemperatureCelsius: 98.0,
        crownWheelPinionVibrationMmSec: 8.8, // Above 7.5 critical limit
        magneticDrainPlugMetalFinesGrams: 5.5, // High metal debris
        gearToothMeshingFrequencyHz: 480.0,
        drivelineBacklashDegrees: 4.2,
        accumulatedKilometers: 180000.0,
      );

      final result = service.evaluateDifferential(
        vehicleId: 'TRK-DIFF-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(DifferentialHealthStatus.gearToothChippingCritical));
      expect(result.isSafe, isFalse);
      expect(result.isOverhaulMandatory, isTrue);
      expect(result.diagnosticFinding, contains('CRITICAL: Severe hypoid gear tooth chipping'));
    });

    testWidgets('AQIL: DifferentialVibrationDiagnoserCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = DifferentialVibrationTelemetry(
        diffType: DifferentialType.singleReductionHypoid,
        oilSumpTemperatureCelsius: 75.0,
        crownWheelPinionVibrationMmSec: 2.1,
        magneticDrainPlugMetalFinesGrams: 0.5,
        gearToothMeshingFrequencyHz: 450.0,
        drivelineBacklashDegrees: 1.2,
        accumulatedKilometers: 50000.0,
      );

      final result = service.evaluateDifferential(
        vehicleId: 'TRK-DIFF-01',
        telemetry: telemetry,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DifferentialVibrationDiagnoserCard(
                result: result,
                onScheduleCarrierOverhaul: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DifferentialVibrationDiagnoserCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
