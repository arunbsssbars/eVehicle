import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/hazmat_compliance_service.dart';
import 'package:evehicle_logbook/core/widgets/hazmat_compliance_card.dart';

void main() {
  group('Loop 34 - HAZMAT Placarding & Tunnel Restriction Service', () {
    const service = HazmatComplianceService();

    test('Non-hazardous cargo clears all tunnels and requires 0 placards', () {
      final audit = service.evaluateHazmatCargo([]);
      expect(audit.consignments, isEmpty);
      expect(audit.requiredPlacards, isEmpty);
      expect(audit.canTraverseTunnel(TunnelCategory.categoryE), isTrue);
      expect(audit.canTraverseTunnel(TunnelCategory.categoryA), isTrue);
    });

    test('Class 3 flammable cargo bans category D/E tunnels and specifies placards', () {
      const consignments = [
        HazmatConsignment(
          unNumber: 'UN 1203',
          shippingName: 'Gasoline (Motor Spirit)',
          division: HazmatDivision.class3FlammableLiquids,
          quantityKg: 4000.0,
          ergGuideNumber: '128',
        ),
      ];

      final audit = service.evaluateHazmatCargo(consignments);
      expect(audit.totalHazmatWeightKg, equals(4000.0));
      expect(audit.strictestTunnelAllowed, equals(TunnelCategory.categoryD));
      expect(audit.requiredPlacards.first, contains('UN 1203'));
      // Permitted in A, B, C; Banned in D and E
      expect(audit.canTraverseTunnel(TunnelCategory.categoryA), isTrue);
      expect(audit.canTraverseTunnel(TunnelCategory.categoryC), isTrue);
      expect(audit.canTraverseTunnel(TunnelCategory.categoryD), isFalse);
      expect(audit.canTraverseTunnel(TunnelCategory.categoryE), isFalse);
    });

    test('Class 1 explosives imposes strict category B restriction', () {
      const consignments = [
        HazmatConsignment(
          unNumber: 'UN 0027',
          shippingName: 'Black Powder (Gunpowder)',
          division: HazmatDivision.class1Explosives,
          quantityKg: 200.0,
          ergGuideNumber: '112',
        ),
      ];

      final audit = service.evaluateHazmatCargo(consignments);
      expect(audit.hasExplosivesOrToxics, isTrue);
      expect(audit.strictestTunnelAllowed, equals(TunnelCategory.categoryB));
      expect(audit.canTraverseTunnel(TunnelCategory.categoryB), isFalse);
    });
  });

  group('Loop 34 - HAZMAT Compliance AQIL Responsive UI Tests', () {
    testWidgets('HazmatComplianceCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = HazmatRouteAudit(
        consignments: [
          HazmatConsignment(
            unNumber: 'UN 1993',
            shippingName: 'Flammable Liquid N.O.S.',
            division: HazmatDivision.class3FlammableLiquids,
            quantityKg: 1500.0,
            ergGuideNumber: '128',
          ),
        ],
        totalHazmatWeightKg: 1500.0,
        strictestTunnelAllowed: TunnelCategory.categoryD,
        requiredPlacards: ['UN 1993 (Class 3 Flammables)'],
        hasExplosivesOrToxics: false,
        emergencyResponseGuideSummary: 'ERG Guide #128: Isolation distance 100m.',
        complianceStatus: 'RESTRICTED: Tunnel Ban on Categories >= D',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HazmatComplianceCard(
              audit: audit,
              onViewErgGuide: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HAZMAT & Tunnel Guard'), findsOneWidget);
      expect(find.text('HAZMAT'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HazmatComplianceCard preserves layout stability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = HazmatRouteAudit(
        consignments: [],
        totalHazmatWeightKg: 0.0,
        strictestTunnelAllowed: TunnelCategory.categoryE,
        requiredPlacards: [],
        hasExplosivesOrToxics: false,
        emergencyResponseGuideSummary: 'NO HAZMAT: Standard general freight.',
        complianceStatus: 'CLEARED FOR ALL TUNNELS',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: const Scaffold(
              body: HazmatComplianceCard(
                audit: audit,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STANDARD'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
