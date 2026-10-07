import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/organization.dart';
import '../services/saas_entitlement_service.dart';
import '../theme/app_colors.dart';

/// Responsive, AQIL-compliant SaaS resource quota consumption meter card.
class QuotaUsageMeterCard extends StatelessWidget {
  final Organization organization;
  final QuotaUsageSummary quotaSummary;
  final VoidCallback? onUpgradeTapped;

  const QuotaUsageMeterCard({
    super.key,
    required this.organization,
    required this.quotaSummary,
    this.onUpgradeTapped,
  });

  @override
  Widget build(BuildContext context) {
    final tier = organization.subscriptionTier;
    final isFree = tier == SubscriptionTier.free;

    Color badgeColor;
    String badgeText;
    switch (tier) {
      case SubscriptionTier.free:
        badgeColor = AppColors.warning;
        badgeText = 'FREE STARTER';
        break;
      case SubscriptionTier.pro:
        badgeColor = AppColors.primary;
        badgeText = 'PRO FLEET';
        break;
      case SubscriptionTier.enterprise:
        badgeColor = AppColors.success;
        badgeText = 'ENTERPRISE';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFree ? AppColors.warning.withValues(alpha: 0.3) : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pie_chart_rounded,
                  color: badgeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Subscription Quota & Usage',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${organization.name} • Workspace Capacity',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Meter 1: Active Vehicles
          _buildMeterBar(
            label: 'Active Vehicles Quota',
            used: quotaSummary.vehiclesUsed,
            allowed: quotaSummary.vehiclesAllowed,
            ratio: quotaSummary.vehicleUsageRatio,
            isExceeded: quotaSummary.isVehicleLimitReached,
          ),
          const SizedBox(height: 10),

          // Meter 2: Monthly Journeys
          _buildMeterBar(
            label: 'Monthly Journeys Quota',
            used: quotaSummary.monthlyJourneysUsed,
            allowed: quotaSummary.monthlyJourneysAllowed,
            ratio: quotaSummary.journeyUsageRatio,
            isExceeded: quotaSummary.isJourneyLimitReached,
          ),
          const SizedBox(height: 14),

          // Upgrade or Manage Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.push('/tenant/billing');
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Manage Billing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onUpgradeTapped ?? () => context.push('/plans'),
                  icon: const Icon(Icons.bolt_rounded, size: 16),
                  label: const Text('Upgrade Plan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeterBar({
    required String label,
    required int used,
    required int allowed,
    required double ratio,
    required bool isExceeded,
  }) {
    final color = isExceeded ? AppColors.error : (ratio > 0.8 ? AppColors.warning : AppColors.primary);
    final countLabel = allowed > 1000 ? '$used / ∞' : '$used / $allowed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              countLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.surfaceContainerLow,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
