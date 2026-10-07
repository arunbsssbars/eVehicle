import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/vehicle_document.dart';
import 'package:evehicle_logbook/core/services/document_vault_service.dart';
import 'package:evehicle_logbook/core/widgets/document_vault_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Loop 6: Document Vault & Verification Lifecycle Tests', () {
    final now = DateTime.now();

    final validDoc = VehicleDocument(
      id: 'DOC-01',
      vehicleId: 'VEH-01',
      type: VehicleDocumentType.registrationCertificate,
      documentNumber: 'RC-DL01-123456',
      issuedDate: now.subtract(const Duration(days: 365)),
      expiryDate: now.add(const Duration(days: 365)), // 1 year left
      sha256Checksum: DocumentVaultService.calculateStringChecksum('RC-VALID-SAMPLE-BYTES'),
      status: DocumentVerificationStatus.verified,
    );

    final expiringDoc = VehicleDocument(
      id: 'DOC-02',
      vehicleId: 'VEH-01',
      type: VehicleDocumentType.pollutionCertificate,
      documentNumber: 'PUC-998877',
      issuedDate: now.subtract(const Duration(days: 170)),
      expiryDate: now.add(const Duration(days: 10)), // 10 days left (urgent)
      sha256Checksum: DocumentVaultService.calculateStringChecksum('PUC-SAMPLE-BYTES'),
      status: DocumentVerificationStatus.verified,
    );

    final expiredDoc = VehicleDocument(
      id: 'DOC-03',
      vehicleId: 'VEH-01',
      type: VehicleDocumentType.insurancePolicy,
      documentNumber: 'INS-445566',
      issuedDate: now.subtract(const Duration(days: 400)),
      expiryDate: now.subtract(const Duration(days: 10)), // Expired 10 days ago
      sha256Checksum: DocumentVaultService.calculateStringChecksum('INS-SAMPLE-BYTES'),
      status: DocumentVerificationStatus.expired,
    );

    test('Cryptographic SHA-256 calculation produces reproducible 64-char hex', () {
      final sample = utf8.encode('VEHICLE_LOGBOOK_OFFICIAL_DOCUMENT_2026');
      final hash = DocumentVaultService.calculateChecksum(sample);

      expect(hash.length, equals(64));
      // Same input produces identical hash
      expect(DocumentVaultService.calculateChecksum(sample), equals(hash));
    });

    test('verifyIntegrity correctly identifies authentic bytes and flags tampered data', () {
      final genuineBytes = utf8.encode('GENUINE_POLICY_CONTENT');
      final expectedHash = DocumentVaultService.calculateChecksum(genuineBytes);

      expect(DocumentVaultService.verifyIntegrity(genuineBytes, expectedHash), isTrue);

      final tamperedBytes = utf8.encode('TAMPERED_POLICY_CONTENT');
      expect(DocumentVaultService.verifyIntegrity(tamperedBytes, expectedHash), isFalse);
    });

    test('DocumentVaultService evaluates compliance summary accurately', () {
      final summary = DocumentVaultService.evaluateCompliance([
        validDoc,
        expiringDoc,
        expiredDoc,
      ]);

      expect(summary.totalDocuments, equals(3));
      expect(summary.validCount, equals(1));
      expect(summary.expiringSoonCount, equals(1));
      expect(summary.expiredCount, equals(1));
      expect(summary.isFullyCompliant, isFalse);
    });

    testWidgets('AQIL: DocumentVaultCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: DocumentVaultCard(
                documents: [validDoc, expiringDoc, expiredDoc],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DocumentVaultCard), findsOneWidget);
      expect(find.text('Statutory Document Vault'), findsOneWidget);
    });

    testWidgets('AQIL: DocumentVaultCard scales under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DocumentVaultCard(
                    documents: [validDoc, expiringDoc],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DocumentVaultCard), findsOneWidget);
    });
  });
}
