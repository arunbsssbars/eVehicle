import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/hydroplaning_risk_service.dart';
import 'package:evehicle_logbook/core/widgets/hydroplaning_risk_card.dart';

void main() {
  group('Loop 45 - Weather Hydroplaning Hazard Tests', () {
    const service = HydroplaningRiskService();

    test('evaluateHazard returns safe dry rating when rainfall is negligible', () {
      const telemetry = WeatherSurfaceTelemetry(
        precipitationRateMmPerHour: 0.0,
        vehicleSpeedKmh: 90.0,
        tyrePressurePsi: 34.0,
        tyreTreadDepthMm: 6.5,
        ambientTempCelsius: 22.0,
      );

      final audit = service.evaluateHazard(telemetry);
      expect(audit.riskLevel, HydroplaningRiskLevel.lowDryRoad);
      expect(audit.estimatedWaterFilmDepthMm, 0.0);
      expect(audit.riskScorePercent, 0.0);
    });

    test('evaluateHazard triggers extreme danger when speed exceeds critical threshold on torrential rain', () {
      const telemetry = WeatherSurfaceTelemetry(
        precipitationRateMmPerHour: 40.0, // Torrential downpour
        vehicleSpeedKmh: 110.0,
        tyrePressurePsi: 32.0,
        tyreTreadDepthMm: 2.0, // Worn tyre
        ambientTempCelsius: 16.0,
      );

      final audit = service.evaluateHazard(telemetry);
      expect(audit.riskLevel, HydroplaningRiskLevel.extremeCriticalDanger);
      expect(audit.riskScorePercent, greaterThanOrEqualTo(90.0));
      expect(audit.recommendedSpeedKmh, lessThan(audit.criticalHydroplaningSpeedKmh));
    });

    test('evaluateHazard confirms worn tyre lowers hydroplaning critical speed', () {
      const healthyTread = WeatherSurfaceTelemetry(
        precipitationRateMmPerHour: 20.0,
        vehicleSpeedKmh: 80.0,
        tyrePressurePsi: 35.0,
        tyreTreadDepthMm: 8.0,
        ambientTempCelsius: 18.0,
      );
      const wornTread = WeatherSurfaceTelemetry(
        precipitationRateMmPerHour: 20.0,
        vehicleSpeedKmh: 80.0,
        tyrePressurePsi: 35.0,
        tyreTreadDepthMm: 1.8,
        ambientTempCelsius: 18.0,
      );

      final healthyAudit = service.evaluateHazard(healthyTread);
      final wornAudit = service.evaluateHazard(wornTread);

      expect(wornAudit.criticalHydroplaningSpeedKmh, lessThan(healthyAudit.criticalHydroplaningSpeedKmh));
    });

    testWidgets('HydroplaningRiskCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = HydroplaningSafetyAudit(
        estimatedWaterFilmDepthMm: 0.51,
        criticalHydroplaningSpeedKmh: 58.4,
        safetyMarginKmh: -6.6,
        riskScorePercent: 100.0,
        riskLevel: HydroplaningRiskLevel.extremeCriticalDanger,
        advisoryMessage: 'CRITICAL HYDROPLANING DANGER: Decelerate immediately to under 41 km/h.',
        recommendedSpeedKmh: 41.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HydroplaningRiskCard(
              audit: audit,
              onAcknowledgeAlert: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hydroplaning & Wet Risk'), findsOneWidget);
      expect(find.text('CRITICAL HAZARD'), findsOneWidget);
      expect(find.text('Limit Speed to 41 km/h'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HydroplaningRiskCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = HydroplaningSafetyAudit(
        estimatedWaterFilmDepthMm: 0.18,
        criticalHydroplaningSpeedKmh: 75.0,
        safetyMarginKmh: 20.0,
        riskScorePercent: 55.0,
        riskLevel: HydroplaningRiskLevel.moderateWetSurface,
        advisoryMessage: 'WET ASPHALT: Moderate traction reduction.',
        recommendedSpeedKmh: 55.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: HydroplaningRiskCard(audit: audit),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WET ROAD'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
