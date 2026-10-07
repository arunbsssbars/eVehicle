import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/driver_fatigue_hos_service.dart';

/// Responsive, AQIL-compliant Driver Fatigue & Hours of Service (HOS) Sentinel card.
class DriverFatigueHosCard extends StatelessWidget {
  final FatigueAuditResult audit;
  final VoidCallback? onAuthorizeRestBreak;

  const DriverFatigueHosCard({
    super.key,
    required this.audit,
    this.onAuthorizeRestBreak,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = audit.requiresImmediateStop
        ? AppColors.error
        : (audit.fatigueRiskScore > 50.0 ? AppColors.warning : AppColors.success);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: audit.requiresImmediateStop
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.borderSubtle,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  audit.requiresImmediateStop ? Icons.bedtime_off_rounded : Icons.hotel_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audit.driverName,
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
                      'HOS Fatigue Sentinel • ${audit.requiresImmediateStop ? "MANDATORY REST REQUIRED" : "Shift Compliant"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: audit.requiresImmediateStop ? AppColors.error : AppColors.secondary,
                        fontWeight: audit.requiresImmediateStop ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Driving Hours & Countdown Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Driving', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${(audit.totalDrivingMinutes / 60.0).toStringAsFixed(1)}h / 11h',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: audit.isHosViolated ? AppColors.error : AppColors.onSurface,
                        ),
                      ),
                      Text('On-Duty: ${(audit.totalDutyMinutes / 60.0).toStringAsFixed(1)}h / 14h', style: const TextStyle(fontSize: 9.5, color: AppColors.secondary)),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: AppColors.borderSubtle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Next Mandatory Rest', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${audit.minutesUntilMandatoryBreak} min',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: audit.minutesUntilMandatoryBreak < 30 ? AppColors.error : AppColors.primary,
                        ),
                      ),
                      Text('Fatigue Index: ${audit.fatigueRiskScore.toStringAsFixed(0)}/100', style: TextStyle(fontSize: 9.5, color: audit.fatigueRiskScore > 60 ? AppColors.error : AppColors.secondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Warning indicators
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHosPill(
                label: 'Continuous: ${(audit.continuousDrivingMinutes / 60.0).toStringAsFixed(1)}h',
                isAlert: audit.continuousDrivingMinutes > 420,
              ),
              if (audit.isInCircadianHighRiskWindow)
                _buildHosPill(
                  label: 'Circadian Peak Danger Window (02-06h)',
                  isAlert: true,
                ),
              if (audit.isHosViolated)
                _buildHosPill(
                  label: 'Statutory HOS Limit Exceeded',
                  isAlert: true,
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (onAuthorizeRestBreak != null) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onAuthorizeRestBreak,
                icon: const Icon(Icons.free_breakfast_rounded, size: 16),
                label: Text(
                  audit.requiresImmediateStop ? 'Enforce Immediate 30-Min Rest Stop' : 'Schedule Rest Break',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: audit.requiresImmediateStop ? AppColors.error : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHosPill({required String label, required bool isAlert}) {
    final color = isAlert ? AppColors.error : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAlert ? AppColors.errorContainer.withValues(alpha: 0.4) : AppColors.surfaceContainerLow,
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
          color: color,
        ),
      ),
    );
  }
}
