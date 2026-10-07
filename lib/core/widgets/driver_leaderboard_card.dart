import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../services/driver_safety_service.dart';

/// Responsive card displaying driver leaderboard and safety badges.
class DriverLeaderboardCard extends StatelessWidget {
  final List<DriverLeaderboardEntry> leaderboard;
  final VoidCallback? onViewAllPressed;

  const DriverLeaderboardCard({
    super.key,
    required this.leaderboard,
    this.onViewAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (leaderboard.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No driver journey data available for leaderboard',
              style: TextStyle(fontSize: 12, color: AppColors.secondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final topDrivers = leaderboard.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.military_tech_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Safety & Performance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Eco Pacing • Safety Scores • Leaderboard',
                      style: TextStyle(fontSize: 11, color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onViewAllPressed != null)
                TextButton(
                  onPressed: onViewAllPressed,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(44, 32),
                  ),
                  child: const Text('View All', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Driver List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topDrivers.length,
            separatorBuilder: (_, __) => const Divider(height: 12, thickness: 0.6, color: AppColors.borderSubtle),
            itemBuilder: (context, index) {
              final entry = topDrivers[index];
              return _buildDriverRow(context, entry);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDriverRow(BuildContext context, DriverLeaderboardEntry entry) {
    final profile = entry.profile;
    final isTop3 = entry.rank <= 3;
    final rankColor = entry.rank == 1
        ? const Color(0xFFEAB308) // Gold
        : entry.rank == 2
            ? const Color(0xFF94A3B8) // Silver
            : entry.rank == 3
                ? const Color(0xFFB45309) // Bronze
                : AppColors.secondary;

    return Row(
      children: [
        // Rank Indicator
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isTop3 ? rankColor.withValues(alpha: 0.15) : AppColors.surfaceContainerLow,
            shape: BoxShape.circle,
            border: isTop3 ? Border.all(color: rankColor, width: 1.2) : null,
          ),
          child: Text(
            '${entry.rank}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: rankColor,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Driver Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.driverName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${NumberFormat('#,##0').format(profile.totalDistanceKm)} km • ${profile.totalJourneys} trips',
                style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Tier Chip & Score
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Color(profile.tier.colorValue).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                profile.tier.title,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(profile.tier.colorValue),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${profile.compositeScore.toStringAsFixed(0)}/100',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(profile.tier.colorValue),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
