import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/turbo_boost_diagnoser_service.dart';
import 'package:evehicle_logbook/core/widgets/turbo_boost_diagnoser_card.dart';

void main() {
  group('Loop 95: Turbocharger Boost & Air Intake Restriction Tests', () {
    const service = TurboBoostDiagnoserService();

    test('Nominal boost pressure and clean filter report healthy status', () {
      const telemetry = TurboIntakeTelemetry(
        ambientPressureBar: 1.0,
        manifoldAbsolutePressureBar: 2.65, // 1.65 Bar boost (> 1.2 target)
        airFilterDifferentialPressureMbar: 8.5, // Clean filter (< 25 mbar)
        massAirFlowGramsPerSec: 320.0,
        intakeAirTemperatureCelsius: 38.0,
      );

      final result = service.evaluateBoostPerformance(
        vehicleId: 'TRK-BOOST-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(IntakeHealthStatus.normal));
      expect(result.isSafe, isTrue);
      expect(result.gaugeBoostBar, equals(1.65));
      expect(result.volumetricEfficiencyPercent, greaterThanOrEqualTo(90.0));
    });

    test('Severe boost leak triggers critical underboost alarm', () {
      const telemetry = TurboIntakeTelemetry(
        ambientPressureBar: 1.0,
        manifoldAbsolutePressureBar: 1.45, // Only 0.45 Bar boost (boost leak)
        airFilterDifferentialPressureMbar: 10.0,
        massAirFlowGramsPerSec: 180.0,
        intakeAirTemperatureCelsius: 52.0,
      );

      final result = service.evaluateBoostPerformance(
        vehicleId: 'TRK-BOOST-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(IntakeHealthStatus.boostLeakOrUnderboostCritical));
      expect(result.isSafe, isFalse);
      expect(result.diagnosticAdvice, contains('UNDERBOOST CRITICAL'));
    });

    testWidgets('AQIL: TurboBoostDiagnoserCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = TurboIntakeTelemetry(
        manifoldAbsolutePressureBar: 2.5,
        airFilterDifferentialPressureMbar: 12.0,
        massAirFlowGramsPerSec: 300.0,
        intakeAirTemperatureCelsius: 40.0,
      );

      final result = service.evaluateBoostPerformance(
        vehicleId: 'TRK-BOOST-01',
        telemetry: telemetry,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TurboBoostDiagnoserCard(
                result: result,
                onPerformSmokeTest: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TurboBoostDiagnoserCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
