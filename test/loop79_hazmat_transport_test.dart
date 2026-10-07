import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/hazmat_transport_service.dart';
import 'package:evehicle_logbook/core/widgets/hazmat_transport_card.dart';

void main() {
  group('Loop 79: Hazardous Materials (HAZMAT) Transport Service Tests', () {
    const service = HazmatTransportService();

    test('Certified diesel freight passes manifest audit and obtains ERG Guide 128', () {
      const consignment = HazmatConsignment(
        unNumber: 'UN 1202',
        properShippingName: 'DIESEL FUEL / GAS OIL',
        primaryClass: HazmatClass.class3FlammableLiquids,
        packingGroup: 'III',
        netQuantityKg: 18000,
        hasTremcardCarried: true,
        hasPlacardsMounted: true,
        isDriverAdrHazmatCertified: true,
      );

      final audit = service.auditConsignment(
        consignment: consignment,
        intendedTunnelCategory: TunnelRestrictionCode.codeA,
      );

      expect(audit.isDispatchAuthorized, isTrue);
      expect(audit.emergencyProtocol.ergGuideNumber, 128);
      expect(audit.emergencyProtocol.initialIsolationRadiusMeters, 50);
      expect(audit.complianceDefects.isEmpty, isTrue);
    });

    test('Missing TREMCARD and Tunnel Category D breach stops dispatch', () {
      const consignment = HazmatConsignment(
        unNumber: 'UN 1075',
        properShippingName: 'PETROLEUM GASES, LIQUEFIED (LPG)',
        primaryClass: HazmatClass.class2Gases,
        packingGroup: 'II',
        netQuantityKg: 12000,
        hasTremcardCarried: false, // Missing TREMCARD!
        hasPlacardsMounted: true,
        isDriverAdrHazmatCertified: true,
      );

      final audit = service.auditConsignment(
        consignment: consignment,
        intendedTunnelCategory: TunnelRestrictionCode.codeD, // Forbidden in Tunnel D!
      );

      expect(audit.isDispatchAuthorized, isFalse);
      expect(audit.isPermittedInTunnel, isFalse);
      expect(audit.complianceDefects.any((d) => d.contains('TREMCARD')), isTrue);
      expect(audit.complianceDefects.any((d) => d.contains('Tunnel Category D')), isTrue);
    });
  });

  group('Loop 79: AQIL UI Multi-Viewport & Accessibility Tests', () {
    const service = HazmatTransportService();

    final testAudit = service.auditConsignment(
      consignment: const HazmatConsignment(
        unNumber: 'UN 1830',
        properShippingName: 'SULPHURIC ACID (>51% ACID)',
        primaryClass: HazmatClass.class8Corrosives,
        packingGroup: 'II',
        netQuantityKg: 15000,
      ),
    );

    testWidgets('HazmatTransportCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HazmatTransportCard(
                audit: testAudit,
                onDispatchEmergencySms: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('UN 1830'), findsOneWidget);
      expect(find.textContaining('Transmit First-Responder ERG Manifest'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HazmatTransportCard maintains integrity under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: SingleChildScrollView(
                child: HazmatTransportCard(
                  audit: testAudit,
                  onDispatchEmergencySms: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HazmatTransportCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
