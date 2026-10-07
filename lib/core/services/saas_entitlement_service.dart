import '../models/organization.dart';

/// Granular premium capabilities gated by subscription tier.
enum SaaSFeature {
  unlimitedVehicles,
  highVolumeMonthlyTrips,
  advancedPdfReports,
  advancedTelematicsSentinels,
  multiLevelApprovals,
  tenantWhiteLabeling,
  apiKeysAndWebhooks,
  immutableAuditLogExport,
}

/// Snapshot of tenant resource usage vs plan quota limits.
class QuotaUsageSummary {
  final int vehiclesUsed;
  final int vehiclesAllowed;
  final int monthlyJourneysUsed;
  final int monthlyJourneysAllowed;
  final int activeSeatsUsed;
  final int activeSeatsAllowed;

  const QuotaUsageSummary({
    required this.vehiclesUsed,
    required this.vehiclesAllowed,
    required this.monthlyJourneysUsed,
    required this.monthlyJourneysAllowed,
    required this.activeSeatsUsed,
    required this.activeSeatsAllowed,
  });

  double get vehicleUsageRatio =>
      vehiclesAllowed > 0 ? (vehiclesUsed / vehiclesAllowed).clamp(0.0, 1.0) : 1.0;

  double get journeyUsageRatio => monthlyJourneysAllowed > 0
      ? (monthlyJourneysUsed / monthlyJourneysAllowed).clamp(0.0, 1.0)
      : 1.0;

  bool get isVehicleLimitReached => vehiclesUsed >= vehiclesAllowed;
  bool get isJourneyLimitReached => monthlyJourneysUsed >= monthlyJourneysAllowed;
  bool get isSeatLimitReached => activeSeatsUsed >= activeSeatsAllowed;
}

/// Central enterprise policy engine governing resource quotas and feature gating.
class SaasEntitlementService {
  const SaasEntitlementService();

  /// Determine if a tenant is allowed to add another vehicle.
  bool canAddVehicle({
    required int currentVehicleCount,
    required SubscriptionTier tier,
  }) {
    return currentVehicleCount < tier.maxVehicles;
  }

  /// Determine if a tenant is allowed to start another journey within billing cycle.
  bool canStartJourney({
    required int currentMonthlyJourneyCount,
    required SubscriptionTier tier,
  }) {
    return currentMonthlyJourneyCount < tier.maxMonthlyJourneys;
  }

  /// Check if a specific SaaS capability is unlocked by the given tier.
  bool hasFeatureAccess(SaaSFeature feature, SubscriptionTier tier) {
    switch (feature) {
      case SaaSFeature.unlimitedVehicles:
        return tier == SubscriptionTier.enterprise;
      case SaaSFeature.highVolumeMonthlyTrips:
        return tier != SubscriptionTier.free;
      case SaaSFeature.advancedPdfReports:
        return tier != SubscriptionTier.free;
      case SaaSFeature.advancedTelematicsSentinels:
        return tier == SubscriptionTier.enterprise;
      case SaaSFeature.multiLevelApprovals:
        return tier != SubscriptionTier.free;
      case SaaSFeature.tenantWhiteLabeling:
        return tier == SubscriptionTier.enterprise;
      case SaaSFeature.apiKeysAndWebhooks:
        return tier == SubscriptionTier.enterprise;
      case SaaSFeature.immutableAuditLogExport:
        return tier != SubscriptionTier.free;
    }
  }

  /// Compute quota usage summary for an organization.
  QuotaUsageSummary getQuotaUsage({
    required Organization organization,
    required int vehicleCount,
    required int monthlyJourneyCount,
    int? activeMembersCount,
  }) {
    final tier = organization.subscriptionTier;
    final maxSeats = tier == SubscriptionTier.enterprise
        ? 50
        : (tier == SubscriptionTier.pro ? 5 : 1);

    return QuotaUsageSummary(
      vehiclesUsed: vehicleCount,
      vehiclesAllowed: tier.maxVehicles,
      monthlyJourneysUsed: monthlyJourneyCount,
      monthlyJourneysAllowed: tier.maxMonthlyJourneys,
      activeSeatsUsed: activeMembersCount ?? organization.activeMembersCount,
      activeSeatsAllowed: maxSeats,
    );
  }

  /// Human-readable upgrade advisory explaining why an action was blocked.
  String getUpgradeAdvisory(SaaSFeature feature, SubscriptionTier currentTier) {
    switch (feature) {
      case SaaSFeature.unlimitedVehicles:
        return 'Vehicle limit reached (${currentTier.maxVehicles} vehicles on ${currentTier.label}). Upgrade to Enterprise Fleet to register unlimited vehicles.';
      case SaaSFeature.highVolumeMonthlyTrips:
        return 'Monthly journey quota exhausted (${currentTier.maxMonthlyJourneys} trips). Upgrade your subscription to continue logging journeys.';
      case SaaSFeature.advancedTelematicsSentinels:
        return 'Real-time 140-Sentinel Telematics Diagnostics requires an active Enterprise Commercial plan.';
      case SaaSFeature.advancedPdfReports:
        return 'Exporting formal government-compliant audit PDFs requires Pro Individual or Enterprise Fleet.';
      case SaaSFeature.tenantWhiteLabeling:
        return 'Custom workspace white-label branding, logos, and regional currencies are available on Enterprise Commercial.';
      case SaaSFeature.apiKeysAndWebhooks:
        return 'Direct cloud REST API access and webhooks require an Enterprise Commercial license.';
      case SaaSFeature.multiLevelApprovals:
      case SaaSFeature.immutableAuditLogExport:
        return 'This capability is locked on the Free Starter plan. Upgrade to Pro to unlock.';
    }
  }
}
