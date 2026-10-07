import 'package:flutter/material.dart';
import '../services/wheel_alignment_service.dart';

/// Card showing wheel alignment, camber/toe deviation score, and tyre shoulder temperature.
class WheelAlignmentCard extends StatelessWidget {
  final WheelAlignmentAudit audit;
  final VoidCallback? onBookLaserAlignment;

  const WheelAlignmentCard({
    super.key,
    required this.audit,
    this.onBookLaserAlignment,
  });

  Color _getStatusColor(AlignmentSeverity severity) {
    switch (severity) {
      case AlignmentSeverity.criticalChassisMisalignment:
        return Colors.red.shade700;
      case AlignmentSeverity.moderateScrubbing:
        return Colors.orange.shade800;
      case AlignmentSeverity.minorPullDeviation:
        return Colors.amber.shade700;
      case AlignmentSeverity.properAlignment:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(AlignmentSeverity severity) {
    switch (severity) {
      case AlignmentSeverity.criticalChassisMisalignment:
        return 'CRITICAL SCRUB';
      case AlignmentSeverity.moderateScrubbing:
        return 'MODERATE DRIFT';
      case AlignmentSeverity.minorPullDeviation:
        return 'MINOR PULL';
      case AlignmentSeverity.properAlignment:
        return 'TRUE & ALIGNED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(audit.severity);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: audit.laserAlignmentRequired ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: audit.laserAlignmentRequired ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sync_problem_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Wheel Alignment & Camber/Toe',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getStatusTitle(audit.severity),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    context,
                    'Deviation',
                    '${audit.camberToeDeviationScore.toStringAsFixed(0)}/100',
                    Icons.straighten_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Δ Temp Rib',
                    '${audit.deltaShoulderTempCelsius.toStringAsFixed(1)}°C',
                    Icons.thermostat_outlined,
                  ),
                  _buildMetric(
                    context,
                    'Tire Life Loss',
                    '-${audit.projectedTyreLifeLossPercent.toStringAsFixed(0)}%',
                    Icons.tire_repair_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              audit.diagnosticFinding,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (audit.laserAlignmentRequired || onBookLaserAlignment != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: audit.laserAlignmentRequired ? statusColor : theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onBookLaserAlignment,
                  icon: const Icon(Icons.build_circle_outlined, size: 18),
                  label: const Text(
                    'Book 4-Wheel Laser Alignment',
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

  Widget _buildMetric(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Flexible(
      child: Column(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
