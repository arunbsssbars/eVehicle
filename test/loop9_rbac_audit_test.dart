import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/services/rbac_guard_service.dart';
import 'package:evehicle_logbook/core/widgets/audit_chain_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Loop 9: Enterprise RBAC Guard & Immutable Audit Hash Chaining Tests', () {
    test('RBAC permission guard enforces enterprise least-privilege matrix', () {
      // Super admin
      expect(RbacGuardService.hasPermission(UserEnterpriseRole.superAdmin, AppPermission.overrideTamperFlag), isTrue);
      expect(RbacGuardService.hasPermission(UserEnterpriseRole.superAdmin, AppPermission.deleteRecords), isTrue);

      // Company admin
      expect(RbacGuardService.hasPermission(UserEnterpriseRole.companyAdmin, AppPermission.approveJourneys), isTrue);
      expect(RbacGuardService.hasPermission(UserEnterpriseRole.companyAdmin, AppPermission.overrideTamperFlag), isFalse);

      // Manager
      expect(RbacGuardService.hasPermission(UserEnterpriseRole.manager, AppPermission.approveJourneys), isTrue);
      expect(RbacGuardService.hasPermission(UserEnterpriseRole.manager, AppPermission.manageVehicles), isFalse);

      // Driver
      expect(RbacGuardService.hasPermission(UserEnterpriseRole.driver, AppPermission.approveJourneys), isFalse);
      expect(RbacGuardService.hasPermission(UserEnterpriseRole.driver, AppPermission.deleteRecords), isFalse);

      // Auditor
      expect(RbacGuardService.hasPermission(UserEnterpriseRole.auditor, AppPermission.verifyCryptographicChain), isTrue);
      expect(RbacGuardService.hasPermission(UserEnterpriseRole.auditor, AppPermission.approveJourneys), isFalse);
    });

    test('Cryptographic audit hash chain validates genuine ledger and flags tampering', () {
      final now = DateTime.now();

      // Block 1 (Genesis child)
      final block1 = RbacGuardService.createChainedEntry(
        id: 'BLOCK-01',
        actorId: 'ADMIN-01',
        action: 'JOURNEY_CREATED',
        entityId: 'JRN-100',
        previousHash: RbacGuardService.genesisHash,
        timestamp: now,
      );

      // Block 2
      final block2 = RbacGuardService.createChainedEntry(
        id: 'BLOCK-02',
        actorId: 'MANAGER-01',
        action: 'JOURNEY_APPROVED',
        entityId: 'JRN-100',
        previousHash: block1.currentHash,
        timestamp: now.add(const Duration(minutes: 5)),
      );

      // Block 3
      final block3 = RbacGuardService.createChainedEntry(
        id: 'BLOCK-03',
        actorId: 'SYSTEM',
        action: 'RECORD_LOCKED',
        entityId: 'JRN-100',
        previousHash: block2.currentHash,
        timestamp: now.add(const Duration(minutes: 10)),
      );

      final validChain = [block1, block2, block3];
      expect(RbacGuardService.verifyChainIntegrity(validChain), isTrue);

      // Tampered chain: an attacker attempts to change actorId in block 2
      final tamperedBlock2 = AuditLogEntry(
        id: block2.id,
        timestamp: block2.timestamp,
        actorId: 'ATTACKER_PIRATE', // Tampered!
        action: block2.action,
        entityId: block2.entityId,
        previousHash: block2.previousHash,
        currentHash: block2.currentHash,
      );

      final brokenChain = [block1, tamperedBlock2, block3];
      expect(RbacGuardService.verifyChainIntegrity(brokenChain), isFalse);
    });

    testWidgets('AQIL: AuditChainCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final block1 = RbacGuardService.createChainedEntry(
        id: 'BLOCK-01',
        actorId: 'ADMIN-01',
        action: 'JOURNEY_CREATED',
        entityId: 'JRN-100',
        previousHash: RbacGuardService.genesisHash,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: AuditChainCard(
                auditChain: [block1],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AuditChainCard), findsOneWidget);
      expect(find.text('Cryptographic Audit Ledger'), findsOneWidget);
    });

    testWidgets('AQIL: AuditChainCard scales gracefully under 1.5x dynamic text scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final block1 = RbacGuardService.createChainedEntry(
        id: 'BLOCK-01',
        actorId: 'ADMIN-01',
        action: 'JOURNEY_CREATED',
        entityId: 'JRN-100',
        previousHash: RbacGuardService.genesisHash,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: AuditChainCard(
                    auditChain: [block1],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AuditChainCard), findsOneWidget);
    });
  });
}
