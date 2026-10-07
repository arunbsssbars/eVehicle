import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/cabin_aqi_service.dart';
import 'package:evehicle_logbook/core/widgets/cabin_aqi_card.dart';

void main() {
  group('Loop 47 - Cabin Air Quality & CO2 Tests', () {
    const service = CabinAqiService();

    test('evaluateCabinAir marks clean air pristine under normal thresholds', () {
      const sample = CabinAirTelemetry(
        pm25MicrogramsPerCubicMeter: 8.0,
        co2Ppm: 600,
        vocIndex: 45,
        filterHealthRemainingPercent: 85.0,
      );

      final audit = service.evaluateCabinAir(sample);
      expect(audit.tier, CabinAirQualityTier.pristine);
      expect(audit.cognitiveImpairmentRisk, isFalse);
      expect(audit.filterReplacementDue, isFalse);
    });

    test('evaluateCabinAir triggers emergency ventilation when CO2 exceeds 1800 ppm', () {
      const sample = CabinAirTelemetry(
        pm25MicrogramsPerCubicMeter: 10.0,
        co2Ppm: 2100, // Dangerous cabin CO2 concentration
        vocIndex: 80,
        filterHealthRemainingPercent: 60.0,
      );

      final audit = service.evaluateCabinAir(sample);
      expect(audit.tier, CabinAirQualityTier.hazardousDrowsinessTrigger);
      expect(audit.recommendedDamperMode, CabinDamperMode.emergencyVentilate);
      expect(audit.cognitiveImpairmentRisk, isTrue);
    });

    test('evaluateCabinAir switches to recirculation purify during high external PM2.5', () {
      const sample = CabinAirTelemetry(
        pm25MicrogramsPerCubicMeter: 48.0, // High PM2.5 smog
        co2Ppm: 750,
        vocIndex: 120,
        filterHealthRemainingPercent: 40.0,
      );

      final audit = service.evaluateCabinAir(sample);
      expect(audit.tier, CabinAirQualityTier.unhealthy);
      expect(audit.recommendedDamperMode, CabinDamperMode.recirculationPurify);
    });

    testWidgets('CabinAqiCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = CabinAirQualityAudit(
        calculatedAqi: 115,
        tier: CabinAirQualityTier.hazardousDrowsinessTrigger,
        recommendedDamperMode: CabinDamperMode.emergencyVentilate,
        statusSummary: 'CRITICAL CO₂ ELEVATION: In-cabin CO₂ is 1950 ppm.',
        filterReplacementDue: false,
        cognitiveImpairmentRisk: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CabinAqiCard(
              audit: audit,
              currentCo2Ppm: 1950,
              onPurifierBoost: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cabin Air Quality & CO₂'), findsOneWidget);
      expect(find.text('HAZARDOUS CO₂'), findsOneWidget);
      expect(find.text('Trigger Fresh Air Cabin Ventilation'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CabinAqiCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = CabinAirQualityAudit(
        calculatedAqi: 25,
        tier: CabinAirQualityTier.pristine,
        recommendedDamperMode: CabinDamperMode.freshAirIntake,
        statusSummary: 'CABIN AIR PRISTINE: Atmospheric parameters within clean thresholds.',
        filterReplacementDue: false,
        cognitiveImpairmentRisk: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: CabinAqiCard(
                audit: audit,
                currentCo2Ppm: 540,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PRISTINE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
