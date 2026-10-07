import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/driver_coaching_service.dart';

/// Responsive, AQIL-compliant driver coaching and habit scoring widget.
class DriverCoachingCard extends StatelessWidget {
  final DriverHabitReport report;
  final VoidCallback? onDetailedReview;

  const DriverCoachingCard({
    super.key,
    required this.report,
    this.onDetailedReview,
  });

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'S':
        return AppColors.success;
      case 'A':
        return const Color(0xFF0D9488); // Teal
      case 'B':
        return AppColors.primary;
      case 'C':
        return AppColors.warning;
      case 'D':
      default:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradeColor = _getGradeColor(report.grade);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with Driver Name & Grade badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    report.grade,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: gradeColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.driverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI Driver Coaching • Score: ${report.score.toStringAsFixed(1)} / 100',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Telematics metrics overview
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricChip(
                label: 'Braking: ${report.harshBrakingCount}',
                isAlert: report.harshBrakingCount > 2,
              ),
              _buildMetricChip(
                label: 'Accel: ${report.harshAccelCount}',
                isAlert: report.harshAccelCount > 2,
              ),
              _buildMetricChip(
                label: 'Cornering: ${report.severeCorneringCount}',
                isAlert: report.severeCorneringCount > 1,
              ),
              _buildMetricChip(
                label: 'Speeding: ${report.speedingCount}',
                isAlert: report.speedingCount > 0,
              ),
              _buildMetricChip(
                label: 'Idling: ${report.idlingMinutes}m',
                isAlert: report.idlingMinutes > 15,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Fuel impact summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_gas_station_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fuel Penalty: +${report.fuelEfficiencyImpactPercent.toStringAsFixed(1)}% consumption variance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Coaching tips list
          ...report.tips.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    tip.isPriority
                        ? Icons.warning_amber_rounded
                        : Icons.lightbulb_outline_rounded,
                    size: 15,
                    color: tip.isPriority ? AppColors.warning : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${tip.title} • ${tip.description}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          if (onDetailedReview != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: onDetailedReview,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
                child: const Text(
                  'View Driver Telematics Log',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChip({required String label, required bool isAlert}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAlert
            ? AppColors.errorContainer.withValues(alpha: 0.5)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAlert ? AppColors.error : AppColors.borderSubtle,
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isAlert ? AppColors.error : AppColors.onSurface,
        ),
      ),
    );
  }
}
