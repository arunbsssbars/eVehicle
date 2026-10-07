import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/organization.dart';
import 'package:evehicle_logbook/core/models/user.dart';
import 'package:evehicle_logbook/core/storage/local_database.dart';
import 'package:evehicle_logbook/core/storage/seed_data.dart';
import 'package:evehicle_logbook/features/admin/super_admin_screen.dart';
import 'package:evehicle_logbook/features/admin/company_admin_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalDatabase.instance.init();
  });

  group('Phase 1 Multi-Tenancy Architecture Tests', () {
    test('Organization model correctly assigns free tier and generates join codes', () {
      final org = Organization(
        id: 'ORG-TEST-01',
        name: 'Test Logistics Ltd.',
        code: 'LOG-9999',
        adminId: 'USR-TEST-01',
        adminName: 'Test Admin',
        contactEmail: 'admin@testlogistics.com',
        contactMobile: '9876543210',
        subscriptionTier: SubscriptionTier.free,
        activeVehiclesCount: 5,
        activeMembersCount: 10,
        createdAt: DateTime.now(),
      );

      expect(org.isFreeTier, isTrue);
      expect(org.isProTier, isFalse);
      expect(org.code, equals('LOG-9999'));

      final json = org.toJson();
      final reconstructed = Organization.fromJson(json);
      expect(reconstructed.name, equals('Test Logistics Ltd.'));
      expect(reconstructed.code, equals('LOG-9999'));
      expect(reconstructed.subscriptionTier, equals(SubscriptionTier.free));
    });

    test('Creating organization via LocalDatabase assigns unique join code and stores it', () async {
      final db = LocalDatabase.instance;
      final org = await db.createOrganization(
        name: 'Apex Freight Inc.',
        adminId: 'USR-APEX-01',
        adminName: 'Apex Admin',
        contactEmail: 'admin@apex.com',
        contactMobile: '9988776655',
      );

      expect(org.id.startsWith('ORG-'), isTrue);
      expect(org.code.length, greaterThanOrEqualTo(6));

      final retrievedByCode = db.getOrganizationByCode(org.code);
      expect(retrievedByCode, isNotNull);
      expect(retrievedByCode!.name, equals('Apex Freight Inc.'));

      final retrievedById = db.getOrganizationById(org.id);
      expect(retrievedById, isNotNull);
      expect(retrievedById!.code, equals(org.code));
    });

    test('Joining organization by join code increments member count', () async {
      final db = LocalDatabase.instance;
      final org = await db.createOrganization(
        name: 'Himalayan Express',
        adminId: 'USR-HIM-01',
        adminName: 'Himalayan Admin',
        contactEmail: 'admin@himalayan.com',
        contactMobile: '9123456780',
      );

      final initialCount = org.activeMembersCount;
      final joined = await db.joinOrganizationByCode('USR-002', org.code);
      expect(joined, isTrue);

      final updatedOrg = db.getOrganizationById(org.id);
      expect(updatedOrg, isNotNull);
      expect(updatedOrg!.activeMembersCount, equals(initialCount + 1));
    });

    test('Individual user model is configured as self-approver with personal logbook', () {
      final user = User(
        id: 'USR-INDIV-TEST',
        name: 'Personal Driver',
        email: 'driver@personal.me',
        mobile: '+91 99999 11111',
        employeeId: 'IND-TEST',
        designation: 'Car Owner',
        department: 'Personal',
        office: 'Personal',
        role: UserRole.individualUser,
        isIndividual: true,
        requiresApproval: false,
        createdAt: DateTime.now(),
      );

      expect(user.isIndividual, isTrue);
      expect(user.isSelfApprover, isTrue);
      expect(user.isSuperAdmin, isFalse);
      expect(user.isCompanyAdmin, isFalse);
    });

    test('Super Admin user model correctly identifies superAdmin role', () {
      final superUser = SeedData.demoUsers.firstWhere((u) => u.id == 'USR-SUPER');
      expect(superUser.isSuperAdmin, isTrue);
      expect(superUser.role, equals(UserRole.superAdmin));
    });

    test('Company Admin user model correctly identifies companyAdmin role', () {
      final compUser = SeedData.demoUsers.firstWhere((u) => u.id == 'USR-004');
      expect(compUser.isCompanyAdmin, isTrue);
    });
  });

  group('Phase 1 Admin Screens UI Tests', () {
    testWidgets('SuperAdminScreen renders platform telemetry, organizations & free tier notice', (tester) async {
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
      expect(find.text('Phase 1: Free Viral Growth Mode Active'), findsOneWidget);
      expect(find.text('Registered Organizations'), findsOneWidget);
    });

    testWidgets('CompanyAdminScreen renders fleet workspace, join code and member roster', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CompanyAdminScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Company Driver / Officer Join Code'), findsOneWidget);
      expect(find.text('COMPANY ADMIN'), findsOneWidget);
    });
  });
}
