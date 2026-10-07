import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/egr_flow_carbon_diagnostic_service.dart';
import 'package:evehicle_logbook/core/widgets/egr_carbon_diagnostic_card.dart';

void main() {
  group('Loop 102: Diesel EGR Valve Carbon Fouling & Cooler Sentinel Tests', () {
    const service = EgrFlowCarbonDiagnosticService();

    test('Clean EGR valve and nominal gas temperatures report healthy status', () {
      const telemetry = EgrTelemetry(
        commandedEgrPositionPercent: 40.0,
        actualEgrPositionPercent: 41.2,
        egrGasTemperatureCelsius: 180.0,
        intakeManifoldDifferentialPressureKpa: 12.0,
        engineLoadPercent: 45.0,
      );

      final result = service.diagnoseEgrSystem(
        vehicleId: 'DSL-EGR-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(EgrHealthStatus.normalRecirculation));
      expect(result.isHealthy, isTrue);
      expect(result.isCoolerThermalEfficiencyDegraded, isFalse);
      expect(result.diagnosticAction, contains('NOMINAL'));
    });

    test('Severe position tracking error and overheated gas flags critical valve stuck', () {
      const telemetry = EgrTelemetry(
        commandedEgrPositionPercent: 60.0,
        actualEgrPositionPercent: 35.0, // 25% tracking error
        egrGasTemperatureCelsius: 380.0, // Overheated cooler
        intakeManifoldDifferentialPressureKpa: 2.5,
        engineLoadPercent: 70.0,
      );

      final result = service.diagnoseEgrSystem(
        vehicleId: 'DSL-EGR-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(EgrHealthStatus.criticalValveStuckOrCoolerClogged));
      expect(result.isHealthy, isFalse);
      expect(result.isCoolerThermalEfficiencyDegraded, isTrue);
      expect(result.diagnosticAction, contains('CRITICAL'));
    });

    testWidgets('AQIL: EgrCarbonDiagnosticCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = EgrTelemetry(
        commandedEgrPositionPercent: 40.0,
        actualEgrPositionPercent: 41.0,
        egrGasTemperatureCelsius: 190.0,
        intakeManifoldDifferentialPressureKpa: 10.0,
        engineLoadPercent: 40.0,
      );
      final result = service.diagnoseEgrSystem(vehicleId: 'DSL-320', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EgrCarbonDiagnosticCard(result: result),
            ),
          ),
        ),
      );

      expect(find.text('EGR Valve & Cooler Sentinel'), findsOneWidget);
      expect(find.text('CLEAN FLOW'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AQIL: EgrCarbonDiagnosticCard scales gracefully under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = EgrTelemetry(
        commandedEgrPositionPercent: 55.0,
        actualEgrPositionPercent: 45.0,
        egrGasTemperatureCelsius: 360.0,
        intakeManifoldDifferentialPressureKpa: 3.0,
        engineLoadPercent: 65.0,
      );
      final result = service.diagnoseEgrSystem(vehicleId: 'DSL-FONT', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: EgrCarbonDiagnosticCard(result: result),
              ),
            ),
          ),
        ),
      );

      expect(find.text('VALVE STUCK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
