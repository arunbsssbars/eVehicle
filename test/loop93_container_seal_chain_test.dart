import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/container_seal_chain_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/container_seal_chain_auditor_card.dart';

void main() {
  group('Loop 93: ISO 17712 Container Seal Chain of Custody Auditor Tests', () {
    const service = ContainerSealChainAuditorService();

    test('Intact high security bolt seal across all checkpoints verifies custody chain', () {
      final now = DateTime(2026, 10, 6, 8, 0);
      final manifest = CargoContainerSealManifest(
        containerNumber: 'MSCU-9021884',
        originalDispatchSealNumber: 'SEAL-BOLT-99881',
        sealType: SecuritySealType.highSecurityBoltIso17712,
        dispatchTimestamp: now,
        originFacility: 'JNPT Port Mumbai',
        destinationFacility: 'Inland Container Depot Delhi',
        checkpointAudits: [
          SealCheckpointAudit(
            checkpointName: 'Toll Plaza Vapi',
            timestamp: now.add(const Duration(hours: 4)),
            inspectedSealNumber: 'SEAL-BOLT-99881',
            isPhysicalIntegrityIntact: true,
            isElectronicNfcMatch: true,
            inspectorStaffId: 'OFFICER-VP-12',
          ),
        ],
      );

      final result = service.auditSealChain(manifest: manifest);

      expect(result.status, equals(SealCustodyStatus.secureAndVerified));
      expect(result.isClean, isTrue);
      expect(result.isIso17712Compliant, isTrue);
      expect(result.isChainOfCustodyContinuous, isTrue);
      expect(result.chainHash, startsWith('CHAIN-'));
    });

    test('Cut or broken seal triggers immediate security breach alert', () {
      final now = DateTime(2026, 10, 6, 8, 0);
      final manifest = CargoContainerSealManifest(
        containerNumber: 'MSCU-9021884',
        originalDispatchSealNumber: 'SEAL-BOLT-99881',
        sealType: SecuritySealType.highSecurityBoltIso17712,
        dispatchTimestamp: now,
        originFacility: 'JNPT Port Mumbai',
        destinationFacility: 'Inland Container Depot Delhi',
        checkpointAudits: [
          SealCheckpointAudit(
            checkpointName: 'Border RTO Checkpost',
            timestamp: now.add(const Duration(hours: 6)),
            inspectedSealNumber: 'SEAL-BOLT-99881',
            isPhysicalIntegrityIntact: false, // Seal cut
            isElectronicNfcMatch: false,
            inspectorStaffId: 'CUSTOMS-INSP-09',
          ),
        ],
      );

      final result = service.auditSealChain(manifest: manifest);

      expect(result.status, equals(SealCustodyStatus.tamperedOrBroken));
      expect(result.isClean, isFalse);
      expect(result.securityAlertMessage, contains('SECURITY BREACH'));
    });

    testWidgets('AQIL: ContainerSealChainAuditorCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime(2026, 10, 6, 8, 0);
      final manifest = CargoContainerSealManifest(
        containerNumber: 'MSCU-9021884',
        originalDispatchSealNumber: 'SEAL-BOLT-99881',
        sealType: SecuritySealType.highSecurityBoltIso17712,
        dispatchTimestamp: now,
        originFacility: 'JNPT Port Mumbai',
        destinationFacility: 'Inland Container Depot Delhi',
        checkpointAudits: [],
      );

      final result = service.auditSealChain(manifest: manifest);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ContainerSealChainAuditorCard(
                result: result,
                onLogSealScan: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ContainerSealChainAuditorCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
