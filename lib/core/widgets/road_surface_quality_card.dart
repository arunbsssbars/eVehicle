import 'package:flutter/material.dart';
import '../services/road_vibration_profiler_service.dart';

/// Defensive AQIL Card displaying road roughness index and pothole impact telemetry.
class RoadSurfaceQualityCard extends StatelessWidget {
  final RoadRoughnessAudit audit;
  final VoidCallback? onReportPotholeHazard;

  const RoadSurfaceQualityCard({
    super.key,
    required this.audit,
    this.onReportPotholeHazard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHazard = audit.qualityClass == RoadQualityClass.severePotholes;
    final isRough = audit.qualityClass == RoadQualityClass.roughDegraded;
    final statusColor = isHazard
        ? const Color(0xFFDC2626)
        : (isRough ? Colors.amber.shade900 : const Color(0xFF10B981));

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.waves,
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
                        'Road Surface Profiler',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Roughness: ${audit.roughnessIndex}/10 • ${audit.potholeStrikeCount} strikes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    _classLabel(audit.qualityClass),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Roughness Meter Indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Text(
                        'IRI Roughness Index: ${audit.roughnessIndex} / 10.0',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 4,
                      child: Text(
                        '+${audit.suspensionWearPenaltyPercent}% wear',
                        style: TextStyle(
                          fontSize: 11,
                          color: isHazard ? Colors.red : theme.textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (audit.roughnessIndex / 10.0).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Metrics Grid
            Row(
              children: [
                _buildMetricBox(
                  context,
                  label: 'Pothole Impacts',
                  value: '${audit.potholeStrikeCount}',
                  icon: Icons.warning_amber_rounded,
                  color: audit.potholeStrikeCount > 0 ? statusColor : null,
                ),
                _buildMetricBox(
                  context,
                  label: 'Avg Speed',
                  value: '${audit.averageSpeedKmph} km/h',
                  icon: Icons.speed,
                ),
                _buildMetricBox(
                  context,
                  label: 'Chassis Stress',
                  value: '${audit.suspensionWearPenaltyPercent}%',
                  icon: Icons.compress,
                  color: audit.suspensionWearPenaltyPercent >= 20.0 ? Colors.orange.shade800 : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary Text Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    isHazard ? Icons.dangerous_outlined : Icons.check_circle_outline,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      audit.surfaceSummary,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isHazard ? Colors.red.shade900 : theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (onReportPotholeHazard != null && isHazard) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.tonalIcon(
                  onPressed: onReportPotholeHazard,
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  label: const Text(
                    'Broadcast Road Hazard Geo-Tag',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color ?? theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _classLabel(RoadQualityClass c) {
    switch (c) {
      case RoadQualityClass.smoothHighway:
        return 'SMOOTH';
      case RoadQualityClass.acceptableCity:
        return 'NORMAL';
      case RoadQualityClass.roughDegraded:
        return 'ROUGH';
      case RoadQualityClass.severePotholes:
        return 'HAZARD';
    }
  }
}
