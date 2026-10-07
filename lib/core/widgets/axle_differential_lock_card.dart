import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/axle_differential_lock_service.dart';

/// Responsive, AQIL-compliant Cross-Axle Differential Lock Sentry Card.
class AxleDifferentialLockCard extends StatelessWidget {
  final AxleDifferentialLockAuditResult result;
  final VoidCallback? onDisengageLock;

  const AxleDifferentialLockCard({
    super.key,
    required this.result,
    this.onDisengageLock,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String badgeText;
    switch (result.status) {
      case AxleDifferentialLockStatus.openDifferentialDisengaged:
        statusColor = AppColors.success;
        badgeText = 'OPEN DIFF';
        break;
      case AxleDifferentialLockStatus.crossLockEngagedNormalTraction:
        statusColor = AppColors.primary;
        badgeText = 'LOCK ENGAGED';
        break;
      case AxleDifferentialLockStatus.criticalPavementLockBindingHazard:
        statusColor = AppColors.error;
        badgeText = 'WIND-UP BINDING';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.isDrivelineWindUpRisk ? AppColors.error : AppColors.borderSubtle,
          width: result.isDrivelineWindUpRisk ? 1.5 : 1.0,
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
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  result.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Axle Differential Lock Sentry',
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
                      '${result.vehicleId} • ${result.axleDesignation}',
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
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
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

          // 3 Metric Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Wheel Δ Speed',
                  value: '${result.speedDeltaKmh.toStringAsFixed(1)} km/h',
                  isWarning: result.isLocked && result.speedDeltaKmh > 2.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Actuator Air',
                  value: '${result.actuatorPressureKPa.toStringAsFixed(0)} kPa',
                  isWarning: result.actuatorPressureKPa < 550.0 && result.isLocked,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Clutch State',
                  value: result.isLocked ? 'Dog Meshed' : 'Disengaged',
                  isWarning: result.isDrivelineWindUpRisk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Driveline Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: result.isDrivelineWindUpRisk
                  ? AppColors.error.withValues(alpha: 0.08)
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: result.isDrivelineWindUpRisk
                    ? AppColors.error.withValues(alpha: 0.4)
                    : AppColors.borderSubtle,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  result.isDrivelineWindUpRisk ? Icons.report_problem_rounded : Icons.check_circle_rounded,
                  size: 16,
                  color: result.isDrivelineWindUpRisk ? AppColors.error : AppColors.success,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.isDrivelineWindUpRisk
                        ? 'Driveline Wind-Up Detected: Torsional Shaft Stress Extreme'
                        : 'Driveline Torsion: Open Differentiation or Low-Speed Straight Grip',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: result.isDrivelineWindUpRisk ? AppColors.error : AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Advisory banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: statusColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.safetyAdvisory,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          if (onDisengageLock != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onDisengageLock,
                icon: const Icon(Icons.lock_open_rounded, size: 18),
                label: const Text('Disengage Cross-Axle Lock Actuator', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({required String label, required String value, required bool isWarning}) {
    final color = isWarning ? AppColors.error : AppColors.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isWarning ? AppColors.error.withValues(alpha: 0.4) : AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.secondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
