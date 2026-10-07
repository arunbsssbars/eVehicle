import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/immersion_cooling_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/immersion_cooling_card.dart';

void main() {
  group('Loop 137: ImmersionCoolingAuditorService & Card Tests', () {
    const service = ImmersionCoolingAuditorService();

    test('Flooded liquid dielectric with high voltage resistance reports nominal status', () {
      const telemetry = ImmersionCoolingTelemetry(
        dielectricFluidFlowLitersPerMin: 42.0,
        dielectricFluidInletTemperatureCelsius: 24.0,
        dielectricFluidOutletTemperatureCelsius: 29.5,
        vapourBubbleOpticalFractionPercent: 1.2,
        packHeatFluxWattsPerCm2: 12.0,
        dielectricBreakdownVoltageKiloVolts: 48.0,
      );

      final result = service.auditImmersionCooling(
        vehicleId: 'EV-IMMERSION-137-OK',
        telemetry: telemetry,
      );

      expect(result.status, ImmersionCoolingStatus.dielectricFlowNominal);
      expect(result.isCoolingOptimal, isTrue);
      expect(result.isThermalRunawayDryoutCritical, isFalse);
      expect(result.flowLitersPerMin, 42.0);
      expect(result.thermalAdvisory, contains('NOMINAL'));
    });

    test('Two-phase nucleate boiling onset (>10%) triggers vapour bubble warning', () {
      const telemetry = ImmersionCoolingTelemetry(
        dielectricFluidFlowLitersPerMin: 22.0,
        dielectricFluidInletTemperatureCelsius: 32.0,
        dielectricFluidOutletTemperatureCelsius: 48.0,
        vapourBubbleOpticalFractionPercent: 14.5,
        packHeatFluxWattsPerCm2: 38.0,
        dielectricBreakdownVoltageKiloVolts: 42.0,
      );

      final result = service.auditImmersionCooling(
        vehicleId: 'EV-IMMERSION-137-WARN',
        telemetry: telemetry,
      );

      expect(result.status, ImmersionCoolingStatus.vapourBubbleBoilWarning);
      expect(result.isCoolingOptimal, isFalse);
      expect(result.vapourFractionPercent, closeTo(14.5, 0.1));
      expect(result.thermalAdvisory, contains('WARNING: Dielectric immersion fluid two-phase boiling'));
    });

    test('Severe vapour dryout (>=28%) or dielectric collapse triggers critical runaway abort', () {
      const telemetry = ImmersionCoolingTelemetry(
        dielectricFluidFlowLitersPerMin: 6.5,
        dielectricFluidInletTemperatureCelsius: 45.0,
        dielectricFluidOutletTemperatureCelsius: 72.0,
        vapourBubbleOpticalFractionPercent: 34.0,
        packHeatFluxWattsPerCm2: 65.0,
        dielectricBreakdownVoltageKiloVolts: 22.0,
      );

      final result = service.auditImmersionCooling(
        vehicleId: 'EV-IMMERSION-137-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, ImmersionCoolingStatus.criticalDryoutThermalRunawayHazard);
      expect(result.isThermalRunawayDryoutCritical, isTrue);
      expect(result.thermalAdvisory, contains('CRITICAL IMMERSION DRY-OUT'));
    });

    testWidgets('ImmersionCoolingCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool pumpBoosted = false;
      const telemetry = ImmersionCoolingTelemetry(
        dielectricFluidFlowLitersPerMin: 16.0,
        dielectricFluidInletTemperatureCelsius: 30.0,
        dielectricFluidOutletTemperatureCelsius: 45.0,
        vapourBubbleOpticalFractionPercent: 12.0,
        packHeatFluxWattsPerCm2: 30.0,
        dielectricBreakdownVoltageKiloVolts: 40.0,
      );

      final result = service.auditImmersionCooling(
        vehicleId: 'HYPER-PACK-88',
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
                child: ImmersionCoolingCard(
                  result: result,
                  onBoostDielectricPump: () {
                    pumpBoosted = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Battery Immersion Cooling Sentry'), findsOneWidget);
      expect(find.textContaining('HYPER-PACK-88'), findsOneWidget);
      expect(find.text('NUCLEATE BOILING'), findsOneWidget);

      final boostBtn = find.text('Boost Dielectric Circulation Pump to 100%');
      expect(boostBtn, findsOneWidget);
      await tester.tap(boostBtn);
      expect(pumpBoosted, isTrue);
    });
  });
}
