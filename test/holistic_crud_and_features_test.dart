import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/vehicle.dart';
import 'package:evehicle_logbook/core/models/vehicle_document.dart';
import 'package:evehicle_logbook/core/models/organization.dart';
import 'package:evehicle_logbook/core/models/user.dart';
import 'package:evehicle_logbook/core/models/journey.dart';
import 'package:evehicle_logbook/core/storage/local_database.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await LocalDatabase.instance.init();
  });

  group('Holistic CRUD & Feature Implementation Tests', () {
    test('Vehicle CRUD: Add, Update, Renew Document, and Delete', () async {
      final db = LocalDatabase.instance;

      // 1. Add Vehicle
      final newVehicle = Vehicle(
        id: 'VEH-CRUD-01',
        registrationNumber: 'UP32-AB-9999',
        make: 'Mahindra',
        model: 'Scorpio-N',
        vehicleType: 'SUV',
        fuelType: 'Diesel',
        manufacturingYear: 2024,
        currentOdometer: 12500.0,
        assignedOffice: 'Lucknow Circle HQ',
        assignedDriverId: 'D1',
        assignedDriverName: 'Driver 1',
        monthlyTargetKm: 2500.0,
        nextServiceDate: DateTime.now().add(const Duration(days: 90)),
      );

      final added = await db.addVehicle(newVehicle);
      expect(added.id, equals('VEH-CRUD-01'));
      expect(db.allVehicles.any((v) => v.id == 'VEH-CRUD-01'), isTrue);
      expect(db.allVehicles.firstWhere((v) => v.id == 'VEH-CRUD-01').make, equals('Mahindra'));

      // 2. Update Vehicle
      final updatedVehicle = added.copyWith(
        model: 'Scorpio-N 4x4 Luxury',
        monthlyTargetKm: 3000.0,
      );
      final updated = await db.updateVehicle(updatedVehicle);
      expect(updated.model, equals('Scorpio-N 4x4 Luxury'));
      expect(db.allVehicles.firstWhere((v) => v.id == 'VEH-CRUD-01').model, equals('Scorpio-N 4x4 Luxury'));
      expect(db.allVehicles.firstWhere((v) => v.id == 'VEH-CRUD-01').monthlyTargetKm, equals(3000.0));

      // 3. Renew Document
      final doc = VehicleDocument(
        id: 'DOC-INS-99',
        vehicleId: 'VEH-CRUD-01',
        type: DocumentType.insurance,
        documentNumber: 'POL-987654321',
        issueDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        isVerified: true,
      );
      final withDoc = await db.renewVehicleDocument('VEH-CRUD-01', doc);
      expect(withDoc.documents.any((d) => d.id == 'DOC-INS-99'), isTrue);

      // 4. Delete / Decommission Vehicle
      final deleted = await db.deleteVehicle('VEH-CRUD-01');
      expect(deleted, isTrue);
      expect(db.allVehicles.any((v) => v.id == 'VEH-CRUD-01'), isFalse);
    });

    test('Organization CRUD & Super Admin Platform Governance', () async {
      final db = LocalDatabase.instance;

      // 1. Create Organization
      final registered = await db.createOrganization(
        name: 'UP State Transport Corporation',
        adminId: 'USR-TEST-ADM',
        adminName: 'Rajesh Kumar',
        contactEmail: 'admin@upsrtc.in',
        contactMobile: '+91 99999 88888',
      );
      expect(registered.id, isNotEmpty);
      expect(db.organizations.any((o) => o.id == registered.id), isTrue);

      // 2. Update Organization
      final updatedOrg = registered.copyWith(
        name: 'UPSRTC Electric Fleet Division',
        subscriptionTier: SubscriptionTier.enterprise,
        status: OrganizationStatus.active,
      );
      final savedUpdated = await db.updateOrganization(updatedOrg);
      expect(savedUpdated.name, equals('UPSRTC Electric Fleet Division'));

      // 3. Regenerate Join Code
      final newCode = await db.regenerateOrganizationCode(registered.id);
      expect(newCode, isNotEmpty);
      expect(db.getOrganizationById(registered.id)!.code, equals(newCode));

      // 4. Broadcast System Announcement
      db.broadcastSystemNotification(
        'Platform Maintenance Notice',
        'All fleets will undergo scheduled maintenance this Sunday.',
      );
      expect(
        db.auditLogs.any((entry) => entry.action == 'BROADCAST_ANNOUNCEMENT'),
        isTrue,
      );

      // 5. Export Platform Backup Data
      final exportJson = db.exportPlatformDataJson();
      final parsed = jsonDecode(exportJson) as Map<String, dynamic>;
      expect(parsed.containsKey('exported_at'), isTrue);
      expect(parsed.containsKey('organizations'), isTrue);
      expect(parsed.containsKey('vehicles'), isTrue);
      expect(parsed.containsKey('journeys'), isTrue);
      expect(parsed.containsKey('users'), isTrue);

      // 6. Delete Organization (Safe archive/removal)
      final deleted = await db.deleteOrganization(registered.id);
      expect(deleted, isTrue);
      expect(db.organizations.any((o) => o.id == registered.id), isFalse);
    });

    test('Workforce CRUD: Add Member, Update Role & Vehicle, Remove Member', () async {
      final db = LocalDatabase.instance;

      // 1. Add Organization Member
      final newMember = await db.addOrganizationMember(
        name: 'Ramesh Verma',
        mobile: '+91 98765 43210',
        role: UserRole.driver,
        department: 'Operations',
        designation: 'Senior Chauffeur',
        orgId: 'ORG-PWD-01',
        orgName: 'Government of Uttar Pradesh',
        assignedVehicleId: 'VEH-001',
      );
      expect(newMember.id, isNotEmpty);
      expect(newMember.name, equals('Ramesh Verma'));
      expect(newMember.role, equals(UserRole.driver));
      expect(newMember.assignedVehicleId, equals('VEH-001'));
      expect(newMember.employeeId, startsWith('EMP-'));

      // 2. Update Role, Dept, and Reassign Vehicle
      final updatedMember = await db.updateMemberRole(
        newMember.id,
        newRole: UserRole.companyAdmin,
        designation: 'Fleet Supervisor',
        department: 'Fleet Management',
        assignedVehicleId: 'VEH-002',
      );
      expect(updatedMember.role, equals(UserRole.companyAdmin));
      expect(updatedMember.designation, equals('Fleet Supervisor'));
      expect(updatedMember.department, equals('Fleet Management'));
      expect(updatedMember.assignedVehicleId, equals('VEH-002'));

      // 3. Remove Member (converts to individual user safely)
      final removedSuccess = await db.removeMemberFromOrganization(newMember.id);
      expect(removedSuccess, isTrue);
      final memberAfterRemoval = db.users.firstWhere((u) => u.id == newMember.id);
      expect(memberAfterRemoval.isIndividual, isTrue);
      expect(memberAfterRemoval.role, equals(UserRole.individualUser));
      expect(memberAfterRemoval.organizationId, equals('INDIVIDUAL'));
      expect(memberAfterRemoval.assignedVehicleId, isNull);
    });

    test('Individual & Journey Operations: Category, Expenses, Duplicate, and Expense Editing', () async {
      final db = LocalDatabase.instance;
      final testVehicle = db.vehicles.first;

      // 1. Start Journey with Trip Classification (Business)
      final journey = await db.startJourney(
        vehicle: testVehicle,
        driverId: 'D-101',
        driverName: 'Amit Singh',
        startLocation: 'Secretariat Gate 1',
        purpose: 'Site inspection and road widening audit',
        openingOdometer: 54200.0,
        tripCategory: TripCategory.business,
      );
      expect(journey.category, equals(TripCategory.business));
      expect(journey.tripCategory, equals(TripCategory.business));
      expect(journey.status, equals(JourneyStatus.active));

      // 2. Complete Journey with Out-of-pocket Expense
      final completed = await db.completeAndSubmitJourney(
        journeyId: journey.id,
        destination: 'Kanpur Bypass Site Office',
        closingOdometer: 54285.0,
        expenseAmount: 450.0,
        expenseReceiptUrl: 'Toll plaza receipt #TXN-99882',
      );
      expect(completed.officialDistance, equals(85.0));
      expect(completed.expenseAmount, equals(450.0));
      expect(completed.expenseReceiptUrl, equals('Toll plaza receipt #TXN-99882'));

      // 3. Edit / Log Out-of-pocket Journey Expense
      final editedExpense = await db.updateJourneyExpense(
        completed.id,
        expenseAmount: 650.0,
        expenseReceiptUrl: 'Toll plaza ₹450 + Parking ₹200',
      );
      expect(editedExpense.expenseAmount, equals(650.0));
      expect(editedExpense.expenseReceiptUrl, equals('Toll plaza ₹450 + Parking ₹200'));

      // 4. Duplicate Journey (Clone into draft with current vehicle odometer)
      final duplicated = await db.duplicateJourney(completed.id);
      expect(duplicated.purpose, equals('[Repeat] ${completed.purpose}'));
      expect(duplicated.startLocation, equals(completed.startLocation));
      expect(duplicated.destination, equals(completed.destination));
      expect(duplicated.status, equals(JourneyStatus.draft));
      expect(duplicated.openingOdometer, greaterThanOrEqualTo(54200.0));

      // 5. Delete Journey (e.g. personal / draft trip deletion)
      final deleted = await db.deleteJourney(journeyId: duplicated.id);
      expect(deleted, isTrue);
      expect(db.journeys.any((j) => j.id == duplicated.id), isFalse);
    });
  });
}
