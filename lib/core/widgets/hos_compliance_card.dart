import 'package:flutter/material.dart';
import '../services/hours_of_service_engine.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Card displaying Hours of Service (HOS) shift limits, fatigue status, and rest timers
class HosComplianceCard extends StatelessWidget {
  final HosShiftReport report;
  final VoidCallback? onLogBreakPressed;

  const HosComplianceCard({
    super.key,
    required this.report,
    this.onLogBreakPressed,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(report.status.colorValue);
    final dailyHoursUsedFraction =
        (report.totalDrivingTime.inMinutes / HoursOfServiceEngine.maxDailyDriving.inMinutes).clamp(0.0, 1.0);

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
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.timelapse_rounded,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hours of Service (HOS)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Shift Fatigue • 4.5h Continuous • 9h Daily',
                      style: TextStyle(fontSize: 11, color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  report.status.shortLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Daily Shift Progress Bar
          Row(
            children: [
              Expanded(
                child: Text(
                  'Shift Driving: ${_formatDuration(report.totalDrivingTime)} / 9h',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Rem: ${_formatDuration(report.remainingDailyDriveTime)}',
                style: const TextStyle(fontSize: 11, color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: dailyHoursUsedFraction,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),

          // Metrics row: continuous driving & rest
          Row(
            children: [
              Expanded(
                child: _buildTimeMetric(
                  label: 'Continuous Drive',
                  value: _formatDuration(report.currentContinuousDrivingTime),
                  sublabel: 'Max 4.5h',
                  color: report.currentContinuousDrivingTime > HoursOfServiceEngine.maxContinuousDriving
                      ? AppColors.error
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimeMetric(
                  label: 'Total Rest Logged',
                  value: _formatDuration(report.totalRestTime),
                  sublabel: 'Min 30m break',
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),

          // Warning banner if any
          if (report.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                report.warnings.first,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeMetric({
    required String label,
    required String value,
    required String sublabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.secondary)),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(sublabel, style: const TextStyle(fontSize: 9, color: AppColors.outline)),
        ],
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60);
    return '${hours}h ${mins}m';
  }
}
