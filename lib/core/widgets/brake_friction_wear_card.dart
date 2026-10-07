import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/brake_friction_wear_auditor_service.dart';

/// Responsive, AQIL-compliant Brake Pad Friction Material & Rotor Thickness Sentry Card.
class BrakeFrictionWearCard extends StatelessWidget {
  final BrakeFrictionAuditResult result;
  final VoidCallback? onSchedulePadReplacement;

  const BrakeFrictionWearCard({
    super.key,
    required this.result,
    this.onSchedulePadReplacement,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String badgeText;
    switch (result.status) {
      case BrakeFrictionWearStatus.adequateLiningThickness:
        statusColor = AppColors.success;
        badgeText = 'LINING HEALTHY';
        break;
      case BrakeFrictionWearStatus.scheduledServiceThreshold:
        statusColor = AppColors.warning;
        badgeText = 'WEAR WARNING';
        break;
      case BrakeFrictionWearStatus.criticalMetalOnMetalBackingPlateRisk:
        statusColor = AppColors.error;
        badgeText = 'METAL CONTACT';
        break;
    }

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
                  result.isSafeForRoad ? Icons.disc_full_rounded : Icons.warning_amber_rounded,
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
                      'Brake Pad Lining Sentry',
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
                      '${result.vehicleId} • Caliper Friction Puck & Rotor',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor, width: 0.8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metric Tiles
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Min Pad Lining',
                  value: '${result.minPadMm.toStringAsFixed(1)} mm',
                  isWarning: result.minPadMm <= 5.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Disc Rotor',
                  value: '${result.rotorMm.toStringAsFixed(1)} mm',
                  isWarning: result.rotorMm < 28.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Taper Delta',
                  value: '${result.taperDeltaMm.toStringAsFixed(1)} mm',
                  isWarning: result.taperDeltaMm >= 2.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Lining Life Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Friction Lining Remaining Usable Life',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${result.remainingLiningLifePercent.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (result.remainingLiningLifePercent / 100.0).clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceContainerLow,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // Advisory Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.serviceAdvisory,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: statusColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          if (onSchedulePadReplacement != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onSchedulePadReplacement,
                icon: const Icon(Icons.handyman_rounded, size: 18),
                label: const Text('Book Brake Pad & Rotor Service', style: TextStyle(fontWeight: FontWeight.w700)),
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
