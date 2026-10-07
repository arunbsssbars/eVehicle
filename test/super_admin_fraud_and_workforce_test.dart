import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/organization.dart';
import 'package:evehicle_logbook/core/models/user.dart';
import 'package:evehicle_logbook/core/models/journey.dart';
import 'package:evehicle_logbook/core/models/membership_request.dart';
import 'package:evehicle_logbook/core/storage/local_database.dart';
import 'package:evehicle_logbook/core/services/fraud_detection_service.dart';
import 'package:evehicle_logbook/features/admin/super_admin_screen.dart';
import 'package:evehicle_logbook/features/admin/company_admin_screen.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await LocalDatabase.instance.init();
  });

  group('Senior Developer Holistic Implementation Tests', () {
    test('FraudDetectionService detects odometer rollbacks', () {
      final now = DateTime.now();
      final normalJourney = Journey(
        id: 'J1',
        localId: 'L1',
        clientOperationId: 'OP1',
        vehicleId: 'VEH-TEST',
        vehicleRegistration: 'TEST-01',
        vehicleModel: 'SUV',
        driverId: 'D1',
        driverName: 'Driver 1',
        officerId: 'O1',
        officerName: 'Officer 1',
        department: 'Logistics',
        office: 'HQ',
        journeyDate: now.subtract(const Duration(hours: 5)),
        startTime: now.subtract(const Duration(hours: 5)),
        endTime: now.subtract(const Duration(hours: 3)),
        startLocation: 'A',
        destination: 'B',
        purpose: 'Duty',
        openingOdometer: 1000.0,
        closingOdometer: 1050.0,
        officialDistance: 50.0,
        gpsDistance: 49.5,
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      );

      // Rollback: opening 1040 is less than previous closing 1050
      final rollbackJourney = Journey(
        id: 'J2',
        localId: 'L2',
        clientOperationId: 'OP2',
        vehicleId: 'VEH-TEST',
        vehicleRegistration: 'TEST-01',
        vehicleModel: 'SUV',
        driverId: 'D1',
        driverName: 'Driver 1',
        officerId: 'O1',
        officerName: 'Officer 1',
        department: 'Logistics',
        office: 'HQ',
        journeyDate: now.subtract(const Duration(hours: 2)),
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        startLocation: 'B',
        destination: 'C',
        purpose: 'Duty',
        openingOdometer: 1040.0, // Rollback of 10 km!
        closingOdometer: 1080.0,
        officialDistance: 40.0,
        gpsDistance: 39.5,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      );

      final alerts = FraudDetectionService.instance.scanJourneys([normalJourney, rollbackJourney]);
      expect(alerts.isNotEmpty, isTrue);

      final rollbackAlert = alerts.firstWhere((a) => a.type == FraudAnomalyType.odometerRollback);
      expect(rollbackAlert.severity, AnomalySeverity.critical);
      expect(rollbackAlert.discrepancyValue, 10.0);
      expect(rollbackAlert.vehicleRegistration, 'TEST-01');
    });

    test('FraudDetectionService detects GPS vs Odometer discrepancy (>25%)', () {
      final now = DateTime.now();
      final varianceJourney = Journey(
        id: 'J-VAR',
        localId: 'L-VAR',
        clientOperationId: 'OP-VAR',
        vehicleId: 'VEH-VAR',
        vehicleRegistration: 'VAR-99',
        vehicleModel: 'Truck',
        driverId: 'D2',
        driverName: 'Driver 2',
        officerId: 'O2',
        officerName: 'Officer 2',
        department: 'Logistics',
        office: 'HQ',
        journeyDate: now,
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        startLocation: 'Hub A',
        destination: 'Hub B',
        purpose: 'Transport',
        openingOdometer: 5000.0,
        closingOdometer: 5100.0,
        officialDistance: 100.0,
        gpsDistance: 60.0, // 40% discrepancy
        createdAt: now,
        updatedAt: now,
      );

      final alerts = FraudDetectionService.instance.scanJourneys([varianceJourney]);
      expect(alerts.isNotEmpty, isTrue);

      final gpsAlert = alerts.firstWhere((a) => a.type == FraudAnomalyType.gpsVariance);
      expect(gpsAlert.vehicleRegistration, 'VAR-99');
      expect(gpsAlert.discrepancyValue, 40.0);
    });

    test('Organization status updates and persistence', () async {
      final org = LocalDatabase.instance.organizations.first;
      expect(org.status, OrganizationStatus.active);

      // Suspend organization
      final success = await LocalDatabase.instance.updateOrganizationStatus(
        org.id,
        OrganizationStatus.suspended,
        reason: 'Payment Overdue for 60 days',
      );
      expect(success, isTrue);

      final updatedOrg = LocalDatabase.instance.getOrganizationById(org.id);
      expect(updatedOrg?.status, OrganizationStatus.suspended);
      expect(updatedOrg?.isSuspended, isTrue);
      expect(updatedOrg?.statusReason, 'Payment Overdue for 60 days');

      // Re-activate
      await LocalDatabase.instance.updateOrganizationStatus(
        org.id,
        OrganizationStatus.active,
      );
      final reactivatedOrg = LocalDatabase.instance.getOrganizationById(org.id);
      expect(reactivatedOrg?.status, OrganizationStatus.active);
      expect(reactivatedOrg?.isActive, isTrue);
    });

    test('MembershipRequest flow: submission, query, and approval', () async {
      final org = LocalDatabase.instance.organizations.first;
      final testUser = User(
        id: 'USR-APPLICANT-01',
        name: 'Applicant Driver',
        email: 'applicant@test.com',
        mobile: '+91 99999 88888',
        employeeId: 'EMP-APP-01',
        designation: 'Driver',
        department: 'Operations',
        office: 'City Branch',
        role: UserRole.individualUser,
        isIndividual: true,
        createdAt: DateTime.now(),
      );

      // Submit membership request using company join code
      final req = await LocalDatabase.instance.submitMembershipRequest(
        orgCode: org.code,
        user: testUser,
        requestedRole: UserRole.driver,
      );
      expect(req.status, MembershipRequestStatus.pending);
      expect(req.organizationId, org.id);

      // Query pending requests
      final pending = LocalDatabase.instance.getPendingMembershipRequests(org.id);
      expect(pending.any((r) => r.id == req.id), isTrue);

      // Approve membership request
      final approved = await LocalDatabase.instance.approveMembershipRequest(
        req.id,
        assignedRole: UserRole.driver,
        approvedBy: 'Company Admin',
        remarks: 'Documents verified',
      );
      expect(approved, isTrue);

      // Verify request status
      final reqAfter = LocalDatabase.instance.membershipRequests.firstWhere((r) => r.id == req.id);
      expect(reqAfter.status, MembershipRequestStatus.approved);
      expect(reqAfter.isApproved, isTrue);
    });

    testWidgets('SuperAdminScreen renders telemetry, fraud center, and org status',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SuperAdminScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Super Admin Console'), findsOneWidget);
      expect(find.text('Global Platform Telemetry'), findsOneWidget);
      expect(find.text('Fraud & Anomaly Detection Center'), findsOneWidget);
      expect(find.text('Registered Organizations'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('CompanyAdminScreen renders join code, compliance monitor, and pending queue',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CompanyAdminScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Company Driver / Officer Join Code'), findsOneWidget);
      expect(find.text('Fleet Compliance & Expiry Monitor'), findsOneWidget);
      expect(find.text('Enrolled Drivers & Officers'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
