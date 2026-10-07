import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/solar_range_extender_service.dart';
import 'package:evehicle_logbook/core/widgets/solar_range_extender_card.dart';

void main() {
  group('Loop 42 - Solar Range Extender Tests', () {
    const service = SolarRangeExtenderService();

    test('calculateSolarYield correctly handles dormant nighttime conditions', () {
      const reading = SolarPvReading(
        irradianceWattsPerSqMeter: 0.0,
        panelSurfaceAreaSqMeters: 4.5,
        ambientTempCelsius: 18.0,
      );

      final audit = service.calculateSolarYield(reading: reading);
      expect(audit.status, SolarGenerationStatus.dormantNight);
      expect(audit.currentPowerOutputWatts, 0.0);
      expect(audit.netExtendedRangeKm, 0.0);
    });

    test('calculateSolarYield calculates high generation during peak midday sun', () {
      const reading = SolarPvReading(
        irradianceWattsPerSqMeter: 900.0,
        panelSurfaceAreaSqMeters: 5.0,
        ambientTempCelsius: 28.0,
      );

      final audit = service.calculateSolarYield(
        reading: reading,
        vehicleWhPerKm: 180.0,
      );

      expect(audit.status, SolarGenerationStatus.peakIrradiance);
      expect(audit.currentPowerOutputWatts, greaterThan(800.0));
      expect(audit.netExtendedRangeKm, greaterThan(15.0));
      expect(audit.co2AvoidedKg, greaterThan(2.0));
    });

    test('calculateSolarYield applies high-temperature derating above 25C', () {
      const baselineReading = SolarPvReading(
        irradianceWattsPerSqMeter: 800.0,
        panelSurfaceAreaSqMeters: 4.0,
        ambientTempCelsius: 25.0,
      );
      const hotReading = SolarPvReading(
        irradianceWattsPerSqMeter: 800.0,
        panelSurfaceAreaSqMeters: 4.0,
        ambientTempCelsius: 45.0,
      );

      final baselineAudit = service.calculateSolarYield(reading: baselineReading);
      final hotAudit = service.calculateSolarYield(reading: hotReading);

      expect(hotAudit.currentPowerOutputWatts, lessThan(baselineAudit.currentPowerOutputWatts));
    });

    testWidgets('SolarRangeExtenderCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = SolarEnergyYieldAudit(
        currentPowerOutputWatts: 720.5,
        dailyGenerationKwh: 5.4,
        hvacAuxiliaryOffsetKwh: 2.16,
        netExtendedRangeKm: 18.2,
        co2AvoidedKg: 2.27,
        status: SolarGenerationStatus.peakIrradiance,
        statusSummary: 'PEAK HARVEST: Rooftop PV generating maximum auxiliary & traction energy.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SolarRangeExtenderCard(
              audit: audit,
              onConfigurePanels: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Solar PV Range Extender'), findsOneWidget);
      expect(find.text('PEAK YIELD'), findsOneWidget);
      expect(find.text('Configure Rooftop Solar Array'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SolarRangeExtenderCard preserves layout stability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = SolarEnergyYieldAudit(
        currentPowerOutputWatts: 340.0,
        dailyGenerationKwh: 2.5,
        hvacAuxiliaryOffsetKwh: 1.0,
        netExtendedRangeKm: 8.5,
        co2AvoidedKg: 1.05,
        status: SolarGenerationStatus.optimalClearSky,
        statusSummary: 'OPTIMAL HARVEST: Steady solar irradiance offsetting auxiliary loads.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: SolarRangeExtenderCard(audit: audit),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE HARVEST'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
