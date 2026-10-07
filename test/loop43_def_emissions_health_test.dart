import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/def_emissions_health_service.dart';
import 'package:evehicle_logbook/core/widgets/def_emissions_health_card.dart';

void main() {
  group('Loop 43 - AdBlue & DEF Emissions Health Tests', () {
    const service = DefEmissionsHealthService();

    test('evaluateDefHealth reports optimal state for normal levels and quality', () {
      const sample = DefTelemetrySample(
        tankLevelPercent: 75.0,
        tankCapacityLiters: 20.0,
        defConsumptionLitersPer1000Km: 1.5,
        noxReductionEfficiencyPercent: 96.0,
        defQualityConcentrationPercent: 32.5,
        tankTempCelsius: 16.0,
      );

      final audit = service.evaluateDefHealth(sample);
      expect(audit.status, DefSystemStatus.optimal);
      expect(audit.remainingDefLiters, 15.0);
      expect(audit.requiresImmediateAction, isFalse);
      expect(audit.heaterActive, isFalse);
    });

    test('evaluateDefHealth triggers derating crawl mode when tank drops below 2%', () {
      const sample = DefTelemetrySample(
        tankLevelPercent: 1.0,
        tankCapacityLiters: 20.0,
        defConsumptionLitersPer1000Km: 1.8,
        noxReductionEfficiencyPercent: 45.0,
        defQualityConcentrationPercent: 32.5,
        tankTempCelsius: 10.0,
      );

      final audit = service.evaluateDefHealth(sample);
      expect(audit.status, DefSystemStatus.inducementDerated);
      expect(audit.inducementCountdownKm, 0);
      expect(audit.requiresImmediateAction, isTrue);
    });

    test('evaluateDefHealth detects corrupted or watered-down urea concentration', () {
      const sample = DefTelemetrySample(
        tankLevelPercent: 60.0,
        tankCapacityLiters: 20.0,
        defConsumptionLitersPer1000Km: 1.8,
        noxReductionEfficiencyPercent: 68.0,
        defQualityConcentrationPercent: 24.0, // Watered down DEF
        tankTempCelsius: 8.0,
      );

      final audit = service.evaluateDefHealth(sample);
      expect(audit.status, DefSystemStatus.qualityMalfunction);
      expect(audit.requiresImmediateAction, isTrue);
    });

    testWidgets('DefEmissionsHealthCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = DefComplianceAudit(
        remainingDefLiters: 1.2,
        estimatedRemainingKm: 650.0,
        status: DefSystemStatus.criticalDepleted,
        inducementCountdownKm: 80,
        heaterActive: true,
        complianceMessage: 'CRITICAL DEF WARNING: Refill immediately! Engine derating in 80 km.',
        requiresImmediateAction: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefEmissionsHealthCard(
              audit: audit,
              onLogDefRefill: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AdBlue / DEF SCR Health'), findsOneWidget);
      expect(find.text('CRITICAL LOW'), findsOneWidget);
      expect(find.text('HEATER'), findsOneWidget);
      expect(find.text('Log DEF / AdBlue Refill'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DefEmissionsHealthCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = DefComplianceAudit(
        remainingDefLiters: 18.0,
        estimatedRemainingKm: 9500.0,
        status: DefSystemStatus.optimal,
        inducementCountdownKm: 1500,
        heaterActive: false,
        complianceMessage: 'SCR SYSTEM HEALTHY: DEF dosing optimal; NOx conversion at 96%.',
        requiresImmediateAction: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: DefEmissionsHealthCard(audit: audit),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OPTIMAL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
