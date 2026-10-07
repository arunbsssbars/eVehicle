import 'package:flutter/material.dart';
import '../services/adas_safety_service.dart';

/// Defensive AQIL Card displaying ADAS headway and forward collision risk metrics.
class AdasSafetyCard extends StatelessWidget {
  final AdasSafetyAudit audit;
  final VoidCallback? onReviewTelemetry;

  const AdasSafetyCard({
    super.key,
    required this.audit,
    this.onReviewTelemetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDanger = audit.isHighCollisionRisk;
    final isCaution = audit.adasSafetyScore < 85.0 && !isDanger;
    final statusColor = isDanger
        ? const Color(0xFFDC2626)
        : (isCaution ? Colors.amber.shade900 : const Color(0xFF10B981));

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
                    Icons.radar,
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
                        'ADAS Collision & Headway',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Avg Headway: ${audit.averageHeadwaySeconds}s • ${audit.forwardCollisionWarningCount} FCW alerts',
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
                    isDanger ? 'RISK' : (isCaution ? 'CAUTION' : 'SAFE'),
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

            // Safety Score Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Text(
                        'ADAS Safety Cushion: ${audit.adasSafetyScore} / 100',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 4,
                      child: Text(
                        '${audit.tailgatingDurationTotalSeconds.toInt()}s tailgating',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDanger ? Colors.red : theme.textTheme.bodySmall?.color,
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
                    value: (audit.adasSafetyScore / 100.0).clamp(0.0, 1.0),
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
                  label: 'Min Headway',
                  value: '${audit.minObservedHeadwaySeconds}s',
                  icon: Icons.compress,
                  color: audit.minObservedHeadwaySeconds < 1.5 ? Colors.red : null,
                ),
                _buildMetricBox(
                  context,
                  label: 'Tailgate Events',
                  value: '${audit.tailgatingEventsCount}',
                  icon: Icons.car_crash_outlined,
                  color: audit.tailgatingEventsCount > 0 ? statusColor : null,
                ),
                _buildMetricBox(
                  context,
                  label: 'FCW Warnings',
                  value: '${audit.forwardCollisionWarningCount}',
                  icon: Icons.notification_important_outlined,
                  color: audit.forwardCollisionWarningCount > 0 ? Colors.red : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Safety Advisory
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
                    isDanger ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      audit.safetyAdvisory,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDanger ? Colors.red.shade900 : theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (onReviewTelemetry != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: onReviewTelemetry,
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text(
                    'Inspect Headway Distance Timeline',
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
}
