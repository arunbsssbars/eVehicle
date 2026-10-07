import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/auto_drop_auxiliary_axle_service.dart';

/// Responsive, AQIL-compliant Auxiliary Axle Auto-Drop & Reverse-Lift Interlock Sentry Card.
class AutoDropAuxiliaryAxleCard extends StatelessWidget {
  final AutoDropAuxiliaryAxleAuditResult result;
  final VoidCallback? onExecuteAutoDrop;

  const AutoDropAuxiliaryAxleCard({
    super.key,
    required this.result,
    this.onExecuteAutoDrop,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String badgeText;
    switch (result.status) {
      case AutoDropAuxiliaryAxleStatus.logicArmedNominal:
        statusColor = AppColors.success;
        badgeText = 'INTERLOCK ARMED';
        break;
      case AutoDropAuxiliaryAxleStatus.speedInterlockOverrideWarning:
        statusColor = AppColors.warning;
        badgeText = 'AUTO-DROP MANDATE';
        break;
      case AutoDropAuxiliaryAxleStatus.criticalReverseGearTireScrubShearHazard:
        statusColor = AppColors.error;
        badgeText = 'REVERSE SCRUB';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.isReverseScrubDanger ? AppColors.error : AppColors.borderSubtle,
          width: result.isReverseScrubDanger ? 1.5 : 1.0,
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
                  result.isInterlockSafe ? Icons.settings_backup_restore_rounded : Icons.warning_rounded,
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
                      'Auxiliary Axle Auto-Drop Sentry',
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
                      '${result.vehicleId} • Speed/Load Deployment Logic',
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
                  label: 'Axle State',
                  value: result.isAxleDown ? 'GROUNDED' : 'LIFTED',
                  isWarning: result.shouldAutoDropBeEnacted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Drive Load',
                  value: '${result.driveLoadTonnes.toStringAsFixed(1)} T',
                  isWarning: result.driveLoadTonnes >= 9.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Logic Command',
                  value: result.shouldAutoLiftInReverseBeEnacted ? 'LIFT IN REV' : 'NORMAL',
                  isWarning: result.isReverseScrubDanger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Interlock Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: result.isReverseScrubDanger
                  ? AppColors.error.withValues(alpha: 0.08)
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: result.isReverseScrubDanger
                    ? AppColors.error.withValues(alpha: 0.4)
                    : AppColors.borderSubtle,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  result.isReverseScrubDanger ? Icons.sync_disabled_rounded : Icons.verified_rounded,
                  size: 16,
                  color: result.isReverseScrubDanger ? AppColors.error : AppColors.success,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.isReverseScrubDanger
                        ? 'Reverse Gear Interlock: Auto-Lift Enacted to Prevent Tire Scrub'
                        : 'Speed & Load Sentinel: Auto-Drop Armed Above 8 km/h',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: result.isReverseScrubDanger ? AppColors.error : AppColors.onSurface,
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
                    result.interlockAdvisory,
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

          if (onExecuteAutoDrop != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onExecuteAutoDrop,
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                label: const Text('Deploy Auxiliary Axle Down Now', style: TextStyle(fontWeight: FontWeight.w700)),
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
