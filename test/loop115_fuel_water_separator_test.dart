import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/fuel_water_separator_service.dart';
import 'package:evehicle_logbook/core/widgets/fuel_water_separator_card.dart';

void main() {
  group('Loop 115: FuelWaterSeparatorService & Card Tests', () {
    const service = FuelWaterSeparatorService();

    test('Clean fuel with dry separator bowl reports inert nominal status', () {
      const telemetry = FuelWaterSeparatorTelemetry(
        waterBowlAccumulationMl: 12.0,
        coalescerDifferentialPressureKPa: 18.0,
        fuelConductivityMicroSiemens: 3.2,
        isWifElectricalProbeTripped: false,
        ambientTemperatureCelsius: 22.0,
      );

      final result = service.auditSeparator(
        vehicleId: 'DIESEL-RIG-115-OK',
        telemetry: telemetry,
      );

      expect(result.status, FuelWaterSeparatorStatus.dryInertOperation);
      expect(result.isSafeForInjection, isTrue);
      expect(result.isCriticalPumpCorrosionRisk, isFalse);
      expect(result.isSubZeroIcingDanger, isFalse);
      expect(result.maintenanceAdvisory, contains('NOMINAL'));
    });

    test('Elevated water bowl accumulation triggers drain scheduled warning', () {
      const telemetry = FuelWaterSeparatorTelemetry(
        waterBowlAccumulationMl: 110.0,
        coalescerDifferentialPressureKPa: 32.0,
        fuelConductivityMicroSiemens: 8.5,
        isWifElectricalProbeTripped: false,
        ambientTemperatureCelsius: 15.0,
      );

      final result = service.auditSeparator(
        vehicleId: 'DIESEL-RIG-115-WARN',
        telemetry: telemetry,
      );

      expect(result.status, FuelWaterSeparatorStatus.drainReservoirScheduled);
      expect(result.isSafeForInjection, isFalse);
      expect(result.waterPercent, closeTo(44.0, 0.5));
      expect(result.maintenanceAdvisory, contains('WARNING: Water-in-fuel accumulation'));
    });

    test('Tripped WIF probe or emulsified water triggers critical pump cavitation risk', () {
      const telemetry = FuelWaterSeparatorTelemetry(
        waterBowlAccumulationMl: 215.0,
        coalescerDifferentialPressureKPa: 60.0,
        fuelConductivityMicroSiemens: 75.0,
        isWifElectricalProbeTripped: true,
        ambientTemperatureCelsius: -5.0,
      );

      final result = service.auditSeparator(
        vehicleId: 'DIESEL-RIG-115-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, FuelWaterSeparatorStatus.criticalWaterBypassHighPressurePumpRisk);
      expect(result.isCriticalPumpCorrosionRisk, isTrue);
      expect(result.isSubZeroIcingDanger, isTrue);
      expect(result.maintenanceAdvisory, contains('CRITICAL DANGER: WIF sensor tripped'));
    });

    testWidgets('FuelWaterSeparatorCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool purgeClicked = false;
      const telemetry = FuelWaterSeparatorTelemetry(
        waterBowlAccumulationMl: 190.0,
        coalescerDifferentialPressureKPa: 52.0,
        fuelConductivityMicroSiemens: 55.0,
        isWifElectricalProbeTripped: true,
        ambientTemperatureCelsius: -3.0,
      );

      final result = service.auditSeparator(
        vehicleId: 'FREIGHT-WIF-007',
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
                child: FuelWaterSeparatorCard(
                  result: result,
                  onPurgeWaterDrain: () {
                    purgeClicked = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Diesel Fuel Water Separator (WIF)'), findsOneWidget);
      expect(find.textContaining('FREIGHT-WIF-007'), findsOneWidget);
      expect(find.text('WIF PROBE TRIPPED'), findsOneWidget);

      final drainBtn = find.text('Purge & Drain Water Condensate Bowl');
      expect(drainBtn, findsOneWidget);
      await tester.tap(drainBtn);
      expect(purgeClicked, isTrue);
    });
  });
}
