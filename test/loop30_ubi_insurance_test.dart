import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/ubi_insurance_service.dart';
import 'package:evehicle_logbook/core/widgets/ubi_insurance_card.dart';

void main() {
  group('Loop 30 - Fleet Insurance Telematics & UBI Premium Service', () {
    const service = UbiInsuranceService();

    test('Safe driving telemetry qualifies for Platinum Preferred 25% discount', () {
      const factors = TelematicsRiskFactors(
        monthlyKmDriven: 2500.0,
        nightDrivingRatioPercent: 2.0,
        harshEventsPer100Km: 0.2,
        speedCompliancePercent: 98.5,
      );

      final audit = service.calculatePremium(
        baseMonthlyPremiumUsd: 200.0,
        factors: factors,
      );

      expect(audit.tier, equals(InsuranceTier.platinumPreferred));
      expect(audit.premiumAdjustmentPercent, equals(-25.0));
      expect(audit.adjustedMonthlyPremiumUsd, equals(150.0));
      expect(audit.netMonthlySavingsUsd, equals(50.0));
    });

    test('Aggressive driving with high night ratio incurs 30% surcharge', () {
      const factors = TelematicsRiskFactors(
        monthlyKmDriven: 6500.0,
        nightDrivingRatioPercent: 45.0,
        harshEventsPer100Km: 4.8,
        speedCompliancePercent: 65.0,
      );

      final audit = service.calculatePremium(
        baseMonthlyPremiumUsd: 300.0,
        factors: factors,
      );

      expect(audit.tier, equals(InsuranceTier.highRiskProvisional));
      expect(audit.premiumAdjustmentPercent, equals(30.0));
      expect(audit.adjustedMonthlyPremiumUsd, equals(390.0));
      expect(audit.netMonthlySavingsUsd, equals(-90.0));
    });
  });

  group('Loop 30 - UBI Insurance AQIL Responsive UI Tests', () {
    testWidgets('UbiInsuranceCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = UbiPremiumAudit(
        baseMonthlyPremiumUsd: 250.0,
        adjustedMonthlyPremiumUsd: 187.50,
        netMonthlySavingsUsd: 62.50,
        premiumAdjustmentPercent: -25.0,
        tier: InsuranceTier.platinumPreferred,
        compositeRiskScore: 12.4,
        actuarialSummary: 'PLATINUM PREFERRED: Flawless driving profile.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UbiInsuranceCard(
              audit: audit,
              onDownloadCertificate: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Telematics Insurance Rating'), findsOneWidget);
      expect(find.text('PLATINUM -25%'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('UbiInsuranceCard maintains readability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = UbiPremiumAudit(
        baseMonthlyPremiumUsd: 300.0,
        adjustedMonthlyPremiumUsd: 390.0,
        netMonthlySavingsUsd: -90.0,
        premiumAdjustmentPercent: 30.0,
        tier: InsuranceTier.highRiskProvisional,
        compositeRiskScore: 82.0,
        actuarialSummary: 'HIGH RISK: Critical risk indicators detected.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: const Scaffold(
              body: UbiInsuranceCard(
                audit: audit,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HIGH RISK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
