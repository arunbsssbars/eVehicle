import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/fleet_tco_forecaster_service.dart';
import 'package:evehicle_logbook/core/widgets/fleet_tco_forecaster_card.dart';

void main() {
  group('Loop 40 - Fleet Lifetime TCO & Residual Value Forecaster Service', () {
    const service = FleetTcoForecasterService();

    test('Fresh commercial asset computes early lifecycle and residual valuation', () {
      const profile = TcoVehicleProfile(
        purchasePriceUsd: 45000.0,
        currentAgeMonths: 6,
        currentOdometerKm: 15000.0,
      );

      const expenses = TcoExpenseHistory(
        cumulativeFuelCostUsd: 2250.0,
        cumulativeMaintenanceCostUsd: 350.0,
        cumulativeInsuranceCostUsd: 600.0,
        cumulativeTollsAndTiresUsd: 200.0,
      );

      final audit = service.forecastTco(profile: profile, expenses: expenses);
      expect(audit.lifecyclePhase, equals('NEW'));
      expect(audit.isInReplacementWindow, isFalse);
      expect(audit.estimatedResidualValueUsd, greaterThan(40000.0));
      expect(audit.costPerKilometerUsd, greaterThan(0.0));
    });

    test('Aging fleet asset (>60 months) triggers optimal disposal replacement window', () {
      const profile = TcoVehicleProfile(
        purchasePriceUsd: 50000.0,
        currentAgeMonths: 62,
        currentOdometerKm: 210000.0,
      );

      const expenses = TcoExpenseHistory(
        cumulativeFuelCostUsd: 35000.0,
        cumulativeMaintenanceCostUsd: 14000.0,
        cumulativeInsuranceCostUsd: 6000.0,
        cumulativeTollsAndTiresUsd: 4000.0,
      );

      final audit = service.forecastTco(profile: profile, expenses: expenses);
      expect(audit.isInReplacementWindow, isTrue);
      expect(audit.lifecyclePhase, equals('REPLACEMENT_WINDOW'));
      expect(audit.strategicAdvisory, contains('OPTIMAL DISPOSAL WINDOW'));
    });

    test('Asset exceeding 72 months triggers immediate REPLACE_NOW phase', () {
      const profile = TcoVehicleProfile(
        purchasePriceUsd: 50000.0,
        currentAgeMonths: 75,
        currentOdometerKm: 260000.0,
      );

      const expenses = TcoExpenseHistory(
        cumulativeFuelCostUsd: 42000.0,
        cumulativeMaintenanceCostUsd: 22000.0,
        cumulativeInsuranceCostUsd: 7500.0,
        cumulativeTollsAndTiresUsd: 5000.0,
      );

      final audit = service.forecastTco(profile: profile, expenses: expenses);
      expect(audit.lifecyclePhase, equals('REPLACE_NOW'));
      expect(audit.strategicAdvisory, contains('COST INVERSION ZONE'));
    });
  });

  group('Loop 40 - Fleet TCO AQIL Responsive UI Tests', () {
    testWidgets('FleetTcoForecasterCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = FleetTcoAudit(
        totalCostOfOwnershipUsd: 68450.0,
        costPerKilometerUsd: 0.385,
        estimatedResidualValueUsd: 18500.0,
        cumulativeOpexUsd: 36950.0,
        optimalReplacementAgeMonths: 60,
        isInReplacementWindow: false,
        lifecyclePhase: 'OPTIMAL_SERVICE',
        strategicAdvisory: 'PRIME PRODUCTIVE ASSET: Operating cost stabilized at peak ROI.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FleetTcoForecasterCard(
              audit: audit,
              onInitiateReplacementRfQ: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lifetime Asset TCO & Residuals'), findsOneWidget);
      expect(find.text('PRIME ROI'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('FleetTcoForecasterCard preserves layout stability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = FleetTcoAudit(
        totalCostOfOwnershipUsd: 112000.0,
        costPerKilometerUsd: 0.448,
        estimatedResidualValueUsd: 8500.0,
        cumulativeOpexUsd: 70500.0,
        optimalReplacementAgeMonths: 60,
        isInReplacementWindow: true,
        lifecyclePhase: 'REPLACE_NOW',
        strategicAdvisory: 'COST INVERSION ZONE: Maintenance escalation exceeds savings.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Scaffold(
              body: FleetTcoForecasterCard(
                audit: audit,
                onInitiateReplacementRfQ: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DISPOSE NOW'), findsOneWidget);
      expect(find.text('Initiate Asset Replacement Tender (RfQ)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
