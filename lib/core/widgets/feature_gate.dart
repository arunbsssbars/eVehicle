import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/organization.dart';
import '../services/saas_entitlement_service.dart';
import '../theme/app_colors.dart';

/// Declarative widget that gates premium SaaS capabilities behind subscription tiers.
class FeatureGate extends StatelessWidget {
  final SaaSFeature feature;
  final SubscriptionTier currentTier;
  final Widget child;
  final Widget? fallback;
  final bool showBannerIfLocked;

  const FeatureGate({
    super.key,
    required this.feature,
    required this.currentTier,
    required this.child,
    this.fallback,
    this.showBannerIfLocked = true,
  });

  @override
  Widget build(BuildContext context) {
    const service = SaasEntitlementService();
    final hasAccess = service.hasFeatureAccess(feature, currentTier);

    if (hasAccess) {
      return child;
    }

    if (fallback != null) {
      return fallback!;
    }

    if (!showBannerIfLocked) {
      return const SizedBox.shrink();
    }

    // Default premium lock banner
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium SaaS Capability',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Upgrade your plan to unlock this enterprise feature',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            service.getUpgradeAdvisory(feature, currentTier),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/plans');
              },
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: const Text('Upgrade Subscription Plan', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
