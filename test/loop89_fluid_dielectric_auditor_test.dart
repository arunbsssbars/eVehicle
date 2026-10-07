import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/fluid_dielectric_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/fluid_dielectric_auditor_card.dart';

void main() {
  group('Loop 89: Fluid Dielectric & Engine Oil Contamination Auditor Tests', () {
    const service = FluidDielectricAuditorService();

    test('Fresh engine oil with minimal dielectric shift reports pristine health', () {
      const telemetry = FluidDielectricTelemetry(
        fluidType: FleetFluidType.engineOil,
        dielectricConstant: 2.25, // Baseline 2.2 => +2.3% shift
        kinematicViscosityCst: 14.2,
        waterContentPpm: 60.0,
        sootOxidationIndex: 0.8,
        operatingKilometers: 2500.0,
      );

      final result = service.auditFluidQuality(
        vehicleId: 'TRK-OIL-01',
        telemetry: telemetry,
      );

      expect(result.grade, equals(FluidDegradationGrade.pristine));
      expect(result.isSafe, isTrue);
      expect(result.hasWaterIntrusion, isFalse);
      expect(result.remainingUsefulLifeKilometers > 20000.0, isTrue);
    });

    test('Water intrusion from blown head gasket triggers immediate mandatory drain', () {
      const telemetry = FluidDielectricTelemetry(
        fluidType: FleetFluidType.engineOil,
        dielectricConstant: 3.1, // Major dielectric spike
        kinematicViscosityCst: 18.5,
        waterContentPpm: 1200.0, // Water emulsion (> 500 ppm)
        sootOxidationIndex: 3.2,
        operatingKilometers: 14000.0,
      );

      final result = service.auditFluidQuality(
        vehicleId: 'TRK-OIL-01',
        telemetry: telemetry,
      );

      expect(result.grade, equals(FluidDegradationGrade.immediateChangeMandatory));
      expect(result.isSafe, isFalse);
      expect(result.hasWaterIntrusion, isTrue);
      expect(result.advisory, contains('EMERGENCY: Coolant / water intrusion'));
    });

    testWidgets('AQIL: FluidDielectricAuditorCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = FluidDielectricTelemetry(
        fluidType: FleetFluidType.engineOil,
        dielectricConstant: 2.3,
        kinematicViscosityCst: 14.1,
        waterContentPpm: 80.0,
        sootOxidationIndex: 1.0,
        operatingKilometers: 5000.0,
      );

      final result = service.auditFluidQuality(
        vehicleId: 'TRK-OIL-01',
        telemetry: telemetry,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FluidDielectricAuditorCard(
                result: result,
                onScheduleOilDrain: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FluidDielectricAuditorCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
