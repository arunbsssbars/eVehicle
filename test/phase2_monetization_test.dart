import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/organization.dart';
import 'package:evehicle_logbook/core/models/user.dart';
import 'package:evehicle_logbook/core/storage/local_database.dart';
import 'package:evehicle_logbook/core/storage/seed_data.dart';
import 'package:evehicle_logbook/core/providers/auth_provider.dart';
import 'package:evehicle_logbook/core/widgets/usage_quota_card.dart';
import 'package:evehicle_logbook/core/services/ad_service.dart';
import 'package:evehicle_logbook/features/subscription/subscription_plans_screen.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await LocalDatabase.instance.init();
  });

  group('Phase 2: Monetization Architecture & Model Tests', () {
    test('SubscriptionTier enum defines correct quotas and labels', () {
      expect(SubscriptionTier.free.label, 'Free Starter');
      expect(SubscriptionTier.free.maxVehicles, 2);
      expect(SubscriptionTier.free.maxMonthlyJourneys, 50);

      expect(SubscriptionTier.pro.label, 'Pro Individual');
      expect(SubscriptionTier.pro.maxVehicles, 5);
      expect(SubscriptionTier.pro.maxMonthlyJourneys, 250);

      expect(SubscriptionTier.enterprise.label, 'Enterprise Fleet');
      expect(SubscriptionTier.enterprise.maxVehicles, 100);
      expect(SubscriptionTier.enterprise.maxMonthlyJourneys, 10000);
    });

    test('User effectiveTier resolves correctly for individual and pro users', () {
      final freeUser = User(
        id: 'TEST-01',
        name: 'Free Driver',
        email: 'free@test.com',
        mobile: '9876543210',
        employeeId: 'EMP-01',
        designation: 'Driver',
        department: 'Logistics',
        office: 'HQ',
        role: UserRole.individualUser,
        isIndividual: true,
        createdAt: DateTime.now(),
      );

      expect(freeUser.effectiveTier, SubscriptionTier.free);
      expect(freeUser.isFreeTier, isTrue);
      expect(freeUser.isProTier, isFalse);

      final proUser = freeUser.copyWith(personalSubscriptionTier: SubscriptionTier.pro);
      expect(proUser.effectiveTier, SubscriptionTier.pro);
      expect(proUser.isFreeTier, isFalse);
      expect(proUser.isProTier, isTrue);

      // JSON roundtrip
      final json = proUser.toJson();
      expect(json['personal_subscription_tier'], 'PRO');
      final restored = User.fromJson(json);
      expect(restored.personalSubscriptionTier, SubscriptionTier.pro);
      expect(restored.isProTier, isTrue);
    });

    test('LocalDatabase updates organization tier and persists', () async {
      final orgs = LocalDatabase.instance.organizations;
      expect(orgs, isNotEmpty);
      final targetOrg = orgs.first;

      final updated = await LocalDatabase.instance.updateOrganizationTier(
        targetOrg.id,
        SubscriptionTier.enterprise,
      );
      expect(updated, isTrue);

      final fetched = LocalDatabase.instance.getOrganizationById(targetOrg.id);
      expect(fetched?.subscriptionTier, SubscriptionTier.enterprise);
    });

    test('LocalDatabase updates individual user subscription tier', () async {
      final user = SeedData.demoUsers.firstWhere((u) => u.isIndividual);
      await LocalDatabase.instance.setCurrentUser(user);

      final updated = await LocalDatabase.instance.updateUserSubscriptionTier(
        user.id,
        SubscriptionTier.pro,
      );
      expect(updated, isTrue);
      expect(LocalDatabase.instance.currentUser?.personalSubscriptionTier, SubscriptionTier.pro);
      expect(LocalDatabase.instance.currentUser?.isProTier, isTrue);
    });
  });

  group('Phase 2: Monetization UI Widget Tests', () {
    testWidgets('UsageQuotaCard renders for Free tier users and hides for Pro',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final freeUser = SeedData.demoUsers.firstWhere((u) => u.id == 'USR-INDIV');
      final container = ProviderContainer();
      await container.read(authProvider.notifier).loginAsUser(freeUser);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: UsageQuotaCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Free Starter Quota'), findsOneWidget);
      expect(find.text('Monthly Journeys'), findsOneWidget);
      expect(find.text('Active Vehicles'), findsOneWidget);
      expect(find.text('UPGRADE'), findsOneWidget);

      // 2. Upgrade user to Pro -> UsageQuotaCard should disappear
      final proUser = freeUser.copyWith(personalSubscriptionTier: SubscriptionTier.pro);
      await container.read(authProvider.notifier).loginAsUser(proUser);
      await tester.pumpAndSettle();

      expect(find.text('Free Starter Quota'), findsNothing);
    });

    testWidgets('AdBannerWidget renders for Free users and disappears for Pro users',
        (tester) async {
      final freeUser = SeedData.demoUsers.firstWhere((u) => u.id == 'USR-INDIV');
      final container = ProviderContainer();
      await container.read(authProvider.notifier).loginAsUser(freeUser);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AdBannerWidget(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ad'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);

      // Switch to Pro
      final proUser = freeUser.copyWith(personalSubscriptionTier: SubscriptionTier.pro);
      await container.read(authProvider.notifier).loginAsUser(proUser);
      await tester.pumpAndSettle();

      expect(find.text('Ad'), findsNothing);
    });

    testWidgets('SubscriptionPlansScreen renders all 3 tiers with billing toggle',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SubscriptionPlansScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subscription & Pricing Plans'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Annual (Save 20%)'), findsOneWidget);
      expect(find.text('Free Starter'), findsOneWidget);
      expect(find.text('Pro Individual'), findsOneWidget);
      expect(find.text('Enterprise Fleet'), findsOneWidget);
      expect(find.text('Frequently Asked Questions'), findsOneWidget);

      // Tap Monthly toggle
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();

      // Pro price should switch to $2.99
      expect(find.text('\$2.99'), findsOneWidget);
    });
  });
}
