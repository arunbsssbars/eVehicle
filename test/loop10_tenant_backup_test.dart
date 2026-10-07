import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/vehicle.dart';
import 'package:evehicle_logbook/core/models/journey.dart';
import 'package:evehicle_logbook/core/models/vehicle_document.dart';
import 'package:evehicle_logbook/core/services/tenant_backup_service.dart';
import 'package:evehicle_logbook/core/widgets/tenant_backup_portal_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Loop 10: Multi-Tenant Data Backup, Restore & Encrypted Migration Tests', () {
    final now = DateTime.now();

    final testVehicle = Vehicle(
      id: 'VEH-01',
      registrationNumber: 'DL01-AB-1234',
      make: 'Toyota',
      model: 'Innova Crysta',
      vehicleType: 'SUV',
      fuelType: 'Diesel',
      manufacturingYear: 2023,
      currentOdometer: 12500.0,
      assignedOffice: 'HQ',
      assignedDriverId: 'DRV-1',
      assignedDriverName: 'Driver 1',
      nextServiceDate: now.add(const Duration(days: 90)),
      status: VehicleStatus.active,
    );

    final testJourney = Journey(
      id: 'JRN-01',
      localId: 'LOC-01',
      clientOperationId: 'OP-01',
      vehicleId: 'VEH-01',
      vehicleRegistration: 'DL01-AB-1234',
      vehicleModel: 'Toyota Innova',
      driverId: 'DRV-1',
      driverName: 'Driver 1',
      officerId: 'USR-1',
      officerName: 'Officer 1',
      department: 'Logistics',
      office: 'HQ',
      journeyDate: now,
      startTime: now.subtract(const Duration(hours: 2)),
      endTime: now,
      startLocation: 'North Block',
      destination: 'Airport',
      purpose: 'Official Transport',
      openingOdometer: 12400.0,
      closingOdometer: 12500.0,
      officialDistance: 100.0,
      createdAt: now,
      updatedAt: now,
    );

    final testDoc = VehicleDocument(
      id: 'DOC-01',
      vehicleId: 'VEH-01',
      type: VehicleDocumentType.registrationCertificate,
      documentNumber: 'RC-123456',
      issuedDate: now.subtract(const Duration(days: 300)),
      expiryDate: now.add(const Duration(days: 60)),
      sha256Checksum: 'dummy-doc-hash',
    );

    test('createSnapshot packages data and generates authentic SHA-256 signature', () {
      final snapshot = TenantBackupService.createSnapshot(
        tenantId: 'TENANT-ALPHA',
        vehicles: [testVehicle],
        journeys: [testJourney],
        documents: [testDoc],
      );

      expect(snapshot.snapshotVersion, equals(1));
      expect(snapshot.tenantId, equals('TENANT-ALPHA'));
      expect(snapshot.vehicles.length, equals(1));
      expect(snapshot.journeys.length, equals(1));
      expect(snapshot.documents.length, equals(1));
      expect(snapshot.sha256Signature.length, equals(64));
    });

    test('restoreSnapshot restores authentic payload and rejects tampered data', () {
      final snapshot = TenantBackupService.createSnapshot(
        tenantId: 'TENANT-BETA',
        vehicles: [testVehicle],
        journeys: [testJourney],
        documents: [testDoc],
      );

      final exportJson = snapshot.toExportJson();

      // Authentic restore should succeed
      final restored = TenantBackupService.restoreSnapshot(exportJson);
      expect(restored.tenantId, equals('TENANT-BETA'));
      expect(restored.vehicles.first.registrationNumber, equals('DL01-AB-1234'));

      // Tampered restore: change tenant_id without re-signing
      final tamperedJson = Map<String, dynamic>.from(exportJson);
      tamperedJson['tenant_id'] = 'TENANT-HACKED';

      expect(
        () => TenantBackupService.restoreSnapshot(tamperedJson),
        throwsA(isA<FormatException>()),
      );
    });

    testWidgets('AQIL: TenantBackupPortalCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: TenantBackupPortalCard(
                onExportSnapshot: () {},
                onImportSnapshot: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TenantBackupPortalCard), findsOneWidget);
      expect(find.text('Tenant Data Backup & Migration'), findsOneWidget);
    });

    testWidgets('AQIL: TenantBackupPortalCard scales safely under 1.5x dynamic text scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final snapshot = TenantBackupService.createSnapshot(
        tenantId: 'TENANT-1',
        vehicles: [testVehicle],
        journeys: [testJourney],
        documents: [testDoc],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TenantBackupPortalCard(
                    lastSnapshot: snapshot,
                    onExportSnapshot: () {},
                    onImportSnapshot: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TenantBackupPortalCard), findsOneWidget);
    });
  });
}
