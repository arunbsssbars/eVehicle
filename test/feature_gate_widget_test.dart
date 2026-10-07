import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/models/organization.dart';
import 'package:evehicle_logbook/core/models/tenant_settings.dart';
import 'package:evehicle_logbook/core/services/saas_entitlement_service.dart';
import 'package:evehicle_logbook/core/widgets/feature_gate.dart';
import 'package:evehicle_logbook/core/widgets/quota_usage_meter_card.dart';

void main() {
  group('SaaS UI & FeatureGate Widget Tests', () {
    final testOrg = Organization(
      id: 'ORG-SaaS-01',
      name: 'Apex Fleet Dynamics',
      code: 'APEX-12',
      adminId: 'USR-APEX',
      adminName: 'Chief Officer',
      contactEmail: 'admin@apexfleet.com',
      contactMobile: '+91 91234 56789',
      subscriptionTier: SubscriptionTier.free,
      createdAt: DateTime.now(),
      settings: const TenantSettings(
        currencySymbol: '₹',
        distanceUnit: 'km',
      ),
    );

    testWidgets('FeatureGate renders child when user has required tier', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeatureGate(
              feature: SaaSFeature.advancedTelematicsSentinels,
              currentTier: SubscriptionTier.enterprise,
              child: Text('Secret Telematics Dashboard'),
            ),
          ),
        ),
      );

      expect(find.text('Secret Telematics Dashboard'), findsOneWidget);
      expect(find.text('Premium SaaS Capability'), findsNothing);
    });

    testWidgets('FeatureGate renders lock banner & upgrade button when tier is insufficient', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FeatureGate(
                feature: SaaSFeature.advancedTelematicsSentinels,
                currentTier: SubscriptionTier.free,
                child: Text('Secret Telematics Dashboard'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Secret Telematics Dashboard'), findsNothing);
      expect(find.text('Premium SaaS Capability'), findsOneWidget);
      expect(find.text('Upgrade Subscription Plan'), findsOneWidget);
    });

    testWidgets('QuotaUsageMeterCard renders properly on 320px viewport with font scale 1.5', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const service = SaasEntitlementService();
      final summary = service.getQuotaUsage(
        organization: testOrg,
        vehicleCount: 2,
        monthlyJourneyCount: 42,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: QuotaUsageMeterCard(
                  organization: testOrg,
                  quotaSummary: summary,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Subscription Quota & Usage'), findsOneWidget);
      expect(find.textContaining('Apex Fleet Dynamics'), findsOneWidget);
      expect(find.text('FREE STARTER'), findsOneWidget);
      expect(find.text('Active Vehicles Quota'), findsOneWidget);
      expect(find.text('Monthly Journeys Quota'), findsOneWidget);
      expect(find.text('Manage Billing'), findsOneWidget);
      expect(find.text('Upgrade Plan'), findsOneWidget);
    });
  });
}
