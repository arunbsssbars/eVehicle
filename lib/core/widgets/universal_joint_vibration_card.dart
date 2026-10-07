import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/universal_joint_vibration_service.dart';

/// Responsive, AQIL-compliant Propshaft Universal Joint & Driveline Harmonic Sentry Card.
class UniversalJointVibrationCard extends StatelessWidget {
  final UniversalJointVibrationAuditResult result;
  final VoidCallback? onScheduleDrivelineInspection;

  const UniversalJointVibrationCard({
    super.key,
    required this.result,
    this.onScheduleDrivelineInspection,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String badgeText;
    switch (result.status) {
      case UniversalJointVibrationStatus.drivelinePhasedNominal:
        statusColor = AppColors.success;
        badgeText = 'DRIVELINE PHASED';
        break;
      case UniversalJointVibrationStatus.uJointTrunnionWearWarning:
        statusColor = AppColors.warning;
        badgeText = '2X VIBRATION';
        break;
      case UniversalJointVibrationStatus.criticalNeedleShatterDriveshaftDropHazard:
        statusColor = AppColors.error;
        badgeText = 'U-JOINT SHATTER';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.isDriveshaftDropCatastrophicRisk ? AppColors.error : AppColors.borderSubtle,
          width: result.isDriveshaftDropCatastrophicRisk ? 1.5 : 1.0,
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
                  result.isDrivelineSmooth ? Icons.sync_rounded : Icons.vibration_rounded,
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
                      'Universal Joint Sentry',
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
                      '${result.vehicleId} • ${result.shaftSegment}',
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
                  label: '2X Vibration',
                  value: '${result.vibrationMmPerSec.toStringAsFixed(1)} mm/s',
                  isWarning: result.vibrationMmPerSec >= 4.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Joint Angle',
                  value: '${result.workingAngleDeg.toStringAsFixed(1)}°',
                  isWarning: result.workingAngleDeg >= 4.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Trunnion Temp',
                  value: '${result.trunnionTempCelsius.toStringAsFixed(0)} °C',
                  isWarning: result.trunnionTempCelsius >= 95.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Vibration Threshold Indicator Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Propshaft Rotational 2X Vibration Amplitude',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${result.vibrationMmPerSec.toStringAsFixed(1)} / 9.0 mm/s',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (result.vibrationMmPerSec / 10.0).clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceContainerLow,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
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
                Icon(Icons.cached_rounded, color: statusColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.harmonicAdvisory,
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

          if (onScheduleDrivelineInspection != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onScheduleDrivelineInspection,
                icon: const Icon(Icons.build_rounded, size: 18),
                label: const Text('Schedule Driveline Balance & U-Joint Lube', style: TextStyle(fontWeight: FontWeight.w700)),
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
