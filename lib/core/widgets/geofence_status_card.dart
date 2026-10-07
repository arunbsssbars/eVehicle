import 'package:flutter/material.dart';
import '../models/geofence_zone.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Card showing geofence audit status, active zones, and boundary alerts
class GeofenceStatusCard extends StatelessWidget {
  final GeofenceEvaluationResult result;
  final List<GeofenceZone> zones;
  final VoidCallback? onManageZonesPressed;

  const GeofenceStatusCard({
    super.key,
    required this.result,
    required this.zones,
    this.onManageZonesPressed,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = result.hasViolation ? AppColors.error : AppColors.success;
    final statusBgColor = result.hasViolation ? AppColors.error.withValues(alpha: 0.08) : AppColors.success.withValues(alpha: 0.08);

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
                  result.hasViolation ? Icons.fmd_bad_rounded : Icons.fmd_good_rounded,
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
                      'Geofence & Boundary Audit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Perimeter Check • Restricted Zones',
                      style: TextStyle(fontSize: 11, color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onManageZonesPressed != null)
                TextButton(
                  onPressed: onManageZonesPressed,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(44, 32),
                  ),
                  child: const Text('Zones', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  result.hasViolation ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.summary,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Active Zones Pills
          if (zones.isNotEmpty) ...[
            Text(
              'Configured Zones (${zones.length})',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: zones.take(4).map((zone) {
                final isViolated = result.violatedZoneNames.contains(zone.name);
                final chipColor = isViolated
                    ? AppColors.error
                    : zone.isRestricted
                        ? AppColors.warning
                        : Color(zone.type.colorValue);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: chipColor.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        zone.isPolygon ? Icons.polyline_rounded : Icons.radar_rounded,
                        size: 11,
                        color: chipColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        zone.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: chipColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
