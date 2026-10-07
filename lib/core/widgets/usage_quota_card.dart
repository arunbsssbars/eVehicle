import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../providers/auth_provider.dart';
import '../providers/journey_provider.dart';
import '../providers/vehicle_provider.dart';

/// A card displaying usage meters against Free tier quotas.
/// Only renders for Free tier users, automatically hidden for Pro & Enterprise.
class UsageQuotaCard extends ConsumerWidget {
  final EdgeInsetsGeometry? margin;
  final bool compact;

  const UsageQuotaCard({
    super.key,
    this.margin,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;
    final isFree = user?.isFreeTier ?? true;

    // Do not display quota warnings to paying Pro / Enterprise members
    if (!isFree) {
      return const SizedBox.shrink();
    }

    final journeyState = ref.watch(journeyProvider);
    final vehicleState = ref.watch(vehicleProvider);

    final maxJourneys = user?.effectiveTier.maxMonthlyJourneys ?? 50;
    final currentJourneys = journeyState.journeys.length;
    final journeyRatio = (currentJourneys / maxJourneys).clamp(0.0, 1.0);

    final maxVehicles = user?.effectiveTier.maxVehicles ?? 2;
    final currentVehicles = vehicleState.vehicles.length;
    final vehicleRatio = (currentVehicles / maxVehicles).clamp(0.0, 1.0);

    final isNearLimit = journeyRatio >= 0.8 || vehicleRatio >= 1.0;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: isNearLimit
            ? AppColors.warning.withValues(alpha: 0.06)
            : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isNearLimit
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.borderSubtle,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isNearLimit
                            ? AppColors.warning.withValues(alpha: 0.15)
                            : AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isNearLimit
                            ? Icons.warning_amber_rounded
                            : Icons.data_usage_rounded,
                        size: 16,
                        color:
                            isNearLimit ? AppColors.warning : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Free Starter Quota',
                        style: TextStyle(
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.push('/plans'),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 3),
                      Text(
                        'UPGRADE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Meter 1: Monthly Journeys
          _buildMeterRow(
            label: 'Monthly Journeys',
            countText: '$currentJourneys / $maxJourneys',
            ratio: journeyRatio,
            color: journeyRatio >= 0.9
                ? AppColors.error
                : (journeyRatio >= 0.7 ? AppColors.warning : AppColors.primary),
          ),
          const SizedBox(height: 10),

          // Meter 2: Vehicles
          _buildMeterRow(
            label: 'Active Vehicles',
            countText: '$currentVehicles / $maxVehicles',
            ratio: vehicleRatio,
            color: vehicleRatio >= 1.0
                ? AppColors.warning
                : AppColors.primaryContainer,
          ),

          if (!compact) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 13, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isNearLimit
                          ? 'Limit approaching! Upgrade to Pro for unlimited trips.'
                          : 'Pro Individual (\$2.99/mo) unlocks unlimited vehicles & ad-free reports.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeterRow({
    required String label,
    required String countText,
    required double ratio,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              countText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
