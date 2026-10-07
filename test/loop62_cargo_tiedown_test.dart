import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/cargo_tiedown_service.dart';
import 'package:evehicle_logbook/core/widgets/cargo_tiedown_card.dart';

void main() {
  group('Loop 62 - Cargo Tie-Down & Load Security Tests', () {
    const service = CargoTieDownService();

    test('auditCargoSecurity confirms compliant status when lashing matches cargo weight', () {
      const arrangement = CargoTieDownArrangement(
        cargoMassKg: 10000.0,
        surfaceFrictionCoefficient: 0.6, // High-friction anti-slip mats
        activeStrapCount: 6,
        averageStrapPretensionDan: 450.0,
        lashingAngleDegrees: 85.0,
        blockedAgainstHeadboard: true,
      );

      final audit = service.auditCargoSecurity(arrangement);
      expect(audit.status, LoadSecurementStatus.secureCompliant);
      expect(audit.additionalStrapsMandatory, isFalse);
      expect(audit.requiredStrapCount, lessThanOrEqualTo(6));
    });

    test('auditCargoSecurity triggers critical shift hazard when straps are grossly insufficient', () {
      const arrangement = CargoTieDownArrangement(
        cargoMassKg: 22000.0, // Heavy machinery
        surfaceFrictionCoefficient: 0.3, // Greasy steel deck
        activeStrapCount: 2, // Only 2 straps applied
        averageStrapPretensionDan: 350.0,
        lashingAngleDegrees: 60.0,
        blockedAgainstHeadboard: false,
      );

      final audit = service.auditCargoSecurity(arrangement);
      expect(audit.status, LoadSecurementStatus.criticalShiftImminent);
      expect(audit.additionalStrapsMandatory, isTrue);
      expect(audit.requiredStrapCount, greaterThan(6));
    });

    test('auditCargoSecurity flags low tension warning if straps are slack', () {
      const arrangement = CargoTieDownArrangement(
        cargoMassKg: 6000.0,
        surfaceFrictionCoefficient: 0.5,
        activeStrapCount: 6,
        averageStrapPretensionDan: 180.0, // Slack straps
        lashingAngleDegrees: 80.0,
        blockedAgainstHeadboard: true,
      );

      final audit = service.auditCargoSecurity(arrangement);
      expect(audit.status, LoadSecurementStatus.insufficientTensionWarning);
      expect(audit.additionalStrapsMandatory, isFalse);
    });

    testWidgets('CargoTieDownCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = CargoTieDownAudit(
        status: LoadSecurementStatus.criticalShiftImminent,
        requiredStrapCount: 8,
        totalRestraintForceKn: 32.4,
        forwardDecelerationCapacityG: 0.35,
        complianceSummary: 'CRITICAL UNDER-SECURED: Only 2 straps applied.',
        additionalStrapsMandatory: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CargoTieDownCard(
              audit: audit,
              activeStrapCount: 2,
              onLogStrapInspection: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cargo Strap & Load Security'), findsOneWidget);
      expect(find.text('SHIFT HAZARD'), findsOneWidget);
      expect(find.text('Log Additional Ratchet Straps'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CargoTieDownCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = CargoTieDownAudit(
        status: LoadSecurementStatus.secureCompliant,
        requiredStrapCount: 5,
        totalRestraintForceKn: 54.0,
        forwardDecelerationCapacityG: 0.88,
        complianceSummary: 'CARGO RESTRAINT COMPLIANT.',
        additionalStrapsMandatory: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: CargoTieDownCard(
                audit: audit,
                activeStrapCount: 6,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SECURE & SAFE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
