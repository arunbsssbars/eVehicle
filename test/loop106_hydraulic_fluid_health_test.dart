import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/hydraulic_fluid_health_service.dart';
import 'package:evehicle_logbook/core/widgets/hydraulic_oil_quality_card.dart';

void main() {
  group('Loop 106: Commercial Tipper & Liftgate Hydraulic Oil Quality Sentinel Tests', () {
    const service = HydraulicFluidHealthService();

    test('Clean hydraulic oil within ISO cleanliness and low water passes audit', () {
      const telemetry = HydraulicFluidTelemetry(
        isoParticleCountCode: 15.0,
        waterContentPpm: 120.0,
        dynamicViscosityCSt: 46.0,
        fluidTemperatureCelsius: 52.0,
        pumpSuctionPressureBar: 0.1,
      );

      final result = service.auditHydraulicOil(
        vehicleId: 'HYD-TIPPER-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(FluidDegradationStatus.pristineCleanFluid));
      expect(result.isClean, isTrue);
      expect(result.isCritical, isFalse);
      expect(result.fluidQualityIndexPercent, equals(100.0));
      expect(result.maintenanceDirective, contains('NOMINAL'));
    });

    test('Excessive water ingress over 800 PPM triggers critical cavitation & varnish alert', () {
      const telemetry = HydraulicFluidTelemetry(
        isoParticleCountCode: 22.0,
        waterContentPpm: 950.0, // Emulsified free water
        dynamicViscosityCSt: 32.0, // Water thinning
        fluidTemperatureCelsius: 88.0, // Thermal varnish
        pumpSuctionPressureBar: -0.35, // High pump cavitation vacuum
      );

      final result = service.auditHydraulicOil(
        vehicleId: 'HYD-TIPPER-02',
        telemetry: telemetry,
      );

      expect(result.status, equals(FluidDegradationStatus.criticalCavitationAndVarnishRisk));
      expect(result.isClean, isFalse);
      expect(result.isCritical, isTrue);
      expect(result.maintenanceDirective, contains('CRITICAL'));
    });

    testWidgets('AQIL: HydraulicOilQualityCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = HydraulicFluidTelemetry(
        isoParticleCountCode: 16.0,
        waterContentPpm: 180.0,
        dynamicViscosityCSt: 45.0,
        fluidTemperatureCelsius: 50.0,
        pumpSuctionPressureBar: 0.05,
      );
      final result = service.auditHydraulicOil(vehicleId: 'HYD-320', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HydraulicOilQualityCard(result: result),
            ),
          ),
        ),
      );

      expect(find.text('Hydraulic Fluid Quality Guard'), findsOneWidget);
      expect(find.text('CLEAN OIL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AQIL: HydraulicOilQualityCard scales gracefully under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = HydraulicFluidTelemetry(
        isoParticleCountCode: 22.0,
        waterContentPpm: 900.0,
        dynamicViscosityCSt: 34.0,
        fluidTemperatureCelsius: 86.0,
        pumpSuctionPressureBar: -0.3,
      );
      final result = service.auditHydraulicOil(vehicleId: 'HYD-FONT', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: HydraulicOilQualityCard(result: result),
              ),
            ),
          ),
        ),
      );

      expect(find.text('FLUID SPOILED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
