import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/esg_decarbonization_service.dart';
import 'package:evehicle_logbook/core/widgets/esg_decarbonization_card.dart';

void main() {
  group('Loop 70 - EsgDecarbonizationService Unit Tests', () {
    late EsgDecarbonizationService service;

    setUp(() {
      service = const EsgDecarbonizationService();
    });

    test('High-renewable EV fleet achieves Net-Zero Leader rating', () {
      const telemetry = FleetEnergyConsumptionTelemetry(
        totalDieselLiters: 1200.0,
        totalGasolineLiters: 0.0,
        totalGridElectricityKwh: 85000.0,
        renewableElectricityPercentage: 90.0, // 90% green PPA
        upstreamThirdPartyFreightTonKm: 15000.0,
        totalFleetDistanceKm: 120000.0,
        totalActiveFleetVehicles: 25,
      );

      final scorecard = service.generateScorecard(telemetry);

      expect(scorecard.ratingTier, EsgRatingTier.leaderNetZeroAligned);
      expect(scorecard.fleetAverageGramsCo2PerKm, lessThanOrEqualTo(95.0));
      expect(scorecard.sustainabilityAdvisory, contains('ESG LEADER'));
    });

    test('Heavy fossil diesel fleet triggers lagging carbon penalty tier', () {
      const telemetry = FleetEnergyConsumptionTelemetry(
        totalDieselLiters: 48000.0,
        totalGasolineLiters: 5000.0,
        totalGridElectricityKwh: 2000.0,
        renewableElectricityPercentage: 0.0,
        upstreamThirdPartyFreightTonKm: 120000.0,
        totalFleetDistanceKm: 180000.0,
        totalActiveFleetVehicles: 40,
      );

      final scorecard = service.generateScorecard(telemetry);

      expect(
        scorecard.ratingTier == EsgRatingTier.laggingHighEmissions ||
            scorecard.ratingTier == EsgRatingTier.nonCompliantCarbonPenalty,
        isTrue,
      );
      expect(scorecard.scope1DirectCo2Tons, greaterThan(120.0));
      expect(scorecard.potentialCarbonOffsetCreditCostUsd, greaterThan(5000.0));
    });
  });

  group('Loop 70 - EsgDecarbonizationCard Widget & AQIL Tests', () {
    testWidgets('Renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const telemetry = FleetEnergyConsumptionTelemetry(
        totalDieselLiters: 8000.0,
        totalGasolineLiters: 1000.0,
        totalGridElectricityKwh: 25000.0,
        renewableElectricityPercentage: 60.0,
        upstreamThirdPartyFreightTonKm: 30000.0,
        totalFleetDistanceKm: 85000.0,
        totalActiveFleetVehicles: 20,
      );

      const scorecard = EsgDecarbonizationScorecard(
        scope1DirectCo2Tons: 23.75,
        scope2IndirectGridCo2Tons: 3.85,
        scope3ValueChainCo2Tons: 2.46,
        totalGrossCo2Tons: 30.06,
        fleetAverageGramsCo2PerKm: 353.6,
        ratingTier: EsgRatingTier.laggingHighEmissions,
        potentialCarbonOffsetCreditCostUsd: 1954.0,
        sustainabilityAdvisory: 'LAGGING BENCHMARK: High reliance on fossil diesel fuel.',
        keyDecarbonizationLever: 'Incorporate HVO100 renewable diesel.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EsgDecarbonizationCard(
                scorecard: scorecard,
                telemetry: telemetry,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Corporate ESG Decarbonization'), findsOneWidget);
      expect(find.text('HIGH EMISSIONS'), findsOneWidget);
      expect(find.text('354 g CO₂/km'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Displays report export button and scales under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const telemetry = FleetEnergyConsumptionTelemetry(
        totalDieselLiters: 500.0,
        totalGasolineLiters: 0.0,
        totalGridElectricityKwh: 45000.0,
        renewableElectricityPercentage: 100.0,
        upstreamThirdPartyFreightTonKm: 5000.0,
        totalFleetDistanceKm: 60000.0,
        totalActiveFleetVehicles: 15,
      );

      const scorecard = EsgDecarbonizationScorecard(
        scope1DirectCo2Tons: 1.34,
        scope2IndirectGridCo2Tons: 0.0,
        scope3ValueChainCo2Tons: 0.41,
        totalGrossCo2Tons: 1.75,
        fleetAverageGramsCo2PerKm: 29.2,
        ratingTier: EsgRatingTier.leaderNetZeroAligned,
        potentialCarbonOffsetCreditCostUsd: 114.0,
        sustainabilityAdvisory: 'ESG LEADER: Fleet emissions intensity aligned with SBTi.',
        keyDecarbonizationLever: 'Maintain high renewable PPA contracts.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: EsgDecarbonizationCard(
                  scorecard: scorecard,
                  telemetry: telemetry,
                  onDownloadEsgAuditReport: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NET-ZERO LEADER'), findsOneWidget);
      expect(find.text('Export ISO 14064 ESG Audit Certificate'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
