import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/models/organization.dart';
import 'package:evehicle_logbook/core/models/tenant_settings.dart';
import 'package:evehicle_logbook/core/services/saas_entitlement_service.dart';

void main() {
  group('SaasEntitlementService Tests', () {
    const service = SaasEntitlementService();

    final testOrgFree = Organization(
      id: 'ORG-FREE-01',
      name: 'Free Logistics Co',
      code: 'FREE-101',
      adminId: 'USR-F1',
      adminName: 'Alice Driver',
      contactEmail: 'alice@freelogistics.com',
      contactMobile: '+91 99999 11111',
      subscriptionTier: SubscriptionTier.free,
      createdAt: DateTime.now(),
    );

    final testOrgEnterprise = Organization(
      id: 'ORG-CORP-99',
      name: 'Mega Transport Corp',
      code: 'MEGA-999',
      adminId: 'USR-M1',
      adminName: 'Director Bob',
      contactEmail: 'bob@megatransport.com',
      contactMobile: '+91 88888 22222',
      subscriptionTier: SubscriptionTier.enterprise,
      createdAt: DateTime.now(),
      settings: const TenantSettings(
        currencyCode: 'USD',
        currencySymbol: '\$',
        distanceUnit: 'mi',
      ),
    );

    test('canAddVehicle correctly evaluates against plan limits', () {
      // Free tier allows max 2 vehicles
      expect(service.canAddVehicle(currentVehicleCount: 0, tier: SubscriptionTier.free), isTrue);
      expect(service.canAddVehicle(currentVehicleCount: 1, tier: SubscriptionTier.free), isTrue);
      expect(service.canAddVehicle(currentVehicleCount: 2, tier: SubscriptionTier.free), isFalse);
      expect(service.canAddVehicle(currentVehicleCount: 5, tier: SubscriptionTier.free), isFalse);

      // Enterprise tier allows up to 100 vehicles
      expect(service.canAddVehicle(currentVehicleCount: 15, tier: SubscriptionTier.enterprise), isTrue);
      expect(service.canAddVehicle(currentVehicleCount: 100, tier: SubscriptionTier.enterprise), isFalse);
    });

    test('canStartJourney evaluates monthly trip quota limits', () {
      // Free tier allows max 50 journeys
      expect(service.canStartJourney(currentMonthlyJourneyCount: 49, tier: SubscriptionTier.free), isTrue);
      expect(service.canStartJourney(currentMonthlyJourneyCount: 50, tier: SubscriptionTier.free), isFalse);

      // Enterprise tier allows max 10,000 journeys
      expect(service.canStartJourney(currentMonthlyJourneyCount: 500, tier: SubscriptionTier.enterprise), isTrue);
    });

    test('hasFeatureAccess enforces capability gating', () {
      // Free tier has basic access only
      expect(service.hasFeatureAccess(SaaSFeature.unlimitedVehicles, SubscriptionTier.free), isFalse);
      expect(service.hasFeatureAccess(SaaSFeature.advancedPdfReports, SubscriptionTier.free), isFalse);
      expect(service.hasFeatureAccess(SaaSFeature.advancedTelematicsSentinels, SubscriptionTier.free), isFalse);
      expect(service.hasFeatureAccess(SaaSFeature.tenantWhiteLabeling, SubscriptionTier.free), isFalse);

      // Pro tier unlocks reports and higher volume
      expect(service.hasFeatureAccess(SaaSFeature.advancedPdfReports, SubscriptionTier.pro), isTrue);
      expect(service.hasFeatureAccess(SaaSFeature.advancedTelematicsSentinels, SubscriptionTier.pro), isFalse);

      // Enterprise unlocks all enterprise features
      expect(service.hasFeatureAccess(SaaSFeature.unlimitedVehicles, SubscriptionTier.enterprise), isTrue);
      expect(service.hasFeatureAccess(SaaSFeature.advancedTelematicsSentinels, SubscriptionTier.enterprise), isTrue);
      expect(service.hasFeatureAccess(SaaSFeature.tenantWhiteLabeling, SubscriptionTier.enterprise), isTrue);
      expect(service.hasFeatureAccess(SaaSFeature.apiKeysAndWebhooks, SubscriptionTier.enterprise), isTrue);
    });

    test('getQuotaUsage generates accurate consumption metrics and flags', () {
      final freeUsage = service.getQuotaUsage(
        organization: testOrgFree,
        vehicleCount: 2,
        monthlyJourneyCount: 30,
      );

      expect(freeUsage.vehiclesUsed, 2);
      expect(freeUsage.vehiclesAllowed, 2);
      expect(freeUsage.isVehicleLimitReached, isTrue);
      expect(freeUsage.vehicleUsageRatio, 1.0);
      expect(freeUsage.isJourneyLimitReached, isFalse);
      expect(freeUsage.journeyUsageRatio, closeTo(0.6, 0.05));

      final enterpriseUsage = service.getQuotaUsage(
        organization: testOrgEnterprise,
        vehicleCount: 12,
        monthlyJourneyCount: 250,
      );

      expect(enterpriseUsage.vehiclesUsed, 12);
      expect(enterpriseUsage.vehiclesAllowed, 100);
      expect(enterpriseUsage.isVehicleLimitReached, isFalse);
      expect(enterpriseUsage.isJourneyLimitReached, isFalse);
    });

    test('getUpgradeAdvisory provides clear actionable guidance', () {
      final msg = service.getUpgradeAdvisory(SaaSFeature.advancedTelematicsSentinels, SubscriptionTier.free);
      expect(msg, contains('140-Sentinel Telematics Diagnostics requires an active Enterprise Commercial plan'));
    });
  });
}
