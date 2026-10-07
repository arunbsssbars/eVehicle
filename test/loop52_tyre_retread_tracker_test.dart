import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/tyre_retread_tracker_service.dart';
import 'package:evehicle_logbook/core/widgets/tyre_retread_tracker_card.dart';

void main() {
  group('Loop 52 - Tyre Retread & Casing Integrity Tests', () {
    const service = TyreRetreadTrackerService();

    test('auditCasing certifies sound virgin casing on steer axle', () {
      const casing = CommercialTyreCasing(
        casingSerial: 'CASING-883192',
        retreadCount: 0,
        axlePosition: TyreAxlePosition.steerAxle,
        casingIntegrityRatingPercent: 95.0,
        currentTreadDepthMm: 11.5,
        totalCasingMileageKm: 85000.0,
      );

      final audit = service.auditCasing(casing);
      expect(audit.status, CasingIntegrityStatus.certifiedSound);
      expect(audit.legallyCompliant, isTrue);
      expect(audit.requiresImmediateReplacement, isFalse);
    });

    test('auditCasing flags illegal retread on steer axle', () {
      const casing = CommercialTyreCasing(
        casingSerial: 'CASING-441092',
        retreadCount: 1, // Retread fitted to steer
        axlePosition: TyreAxlePosition.steerAxle,
        casingIntegrityRatingPercent: 88.0,
        currentTreadDepthMm: 9.0,
        totalCasingMileageKm: 180000.0,
      );

      final audit = service.auditCasing(casing);
      expect(audit.status, CasingIntegrityStatus.steerAxleViolation);
      expect(audit.legallyCompliant, isFalse);
      expect(audit.requiresImmediateReplacement, isTrue);
    });

    test('auditCasing condemns casing when shearography rating falls below 60%', () {
      const casing = CommercialTyreCasing(
        casingSerial: 'CASING-991200',
        retreadCount: 2,
        axlePosition: TyreAxlePosition.trailerAxle,
        casingIntegrityRatingPercent: 52.0, // Internal ply delamination
        currentTreadDepthMm: 4.5,
        totalCasingMileageKm: 320000.0,
      );

      final audit = service.auditCasing(casing);
      expect(audit.status, CasingIntegrityStatus.condemnedScrap);
      expect(audit.requiresImmediateReplacement, isTrue);
    });

    testWidgets('TyreRetreadTrackerCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = TyreRetreadAudit(
        status: CasingIntegrityStatus.condemnedScrap,
        legallyCompliant: false,
        maxAllowableRetreads: 2,
        remainingRetreadCycles: 0,
        complianceSummary: 'CASING CONDEMNED: Shearography reveals internal ply separation.',
        requiresImmediateReplacement: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TyreRetreadTrackerCard(
              audit: audit,
              casingSerial: 'CASING-39182746',
              retreadCount: 2,
              onLogShearographyScan: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tyre Casing & Retread Tracker'), findsOneWidget);
      expect(find.text('SCRAP CONDEMNED'), findsOneWidget);
      expect(find.text('Order Mandatory Casing Replacement'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TyreRetreadTrackerCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = TyreRetreadAudit(
        status: CasingIntegrityStatus.certifiedSound,
        legallyCompliant: true,
        maxAllowableRetreads: 3,
        remainingRetreadCycles: 2,
        complianceSummary: 'CASING SOUND: Structural belt integrity certified at 90%.',
        requiresImmediateReplacement: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: TyreRetreadTrackerCard(
                audit: audit,
                casingSerial: 'CASING-12903',
                retreadCount: 1,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CERTIFIED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
