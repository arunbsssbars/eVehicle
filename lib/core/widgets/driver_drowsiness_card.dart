import 'package:flutter/material.dart';
import '../services/driver_drowsiness_service.dart';

/// Card displaying driver heart rate variability and microsleep warning.
class DriverDrowsinessCard extends StatelessWidget {
  final DriverDrowsinessAudit audit;
  final VoidCallback? onAcknowledgeAlert;

  const DriverDrowsinessCard({
    super.key,
    required this.audit,
    this.onAcknowledgeAlert,
  });

  Color _getStatusColor(DrowsinessRiskLevel level) {
    switch (level) {
      case DrowsinessRiskLevel.criticalMicrosleepRisk:
        return Colors.red.shade700;
      case DrowsinessRiskLevel.highFatigue:
        return Colors.orange.shade800;
      case DrowsinessRiskLevel.mildFatigue:
        return Colors.amber.shade700;
      case DrowsinessRiskLevel.normal:
        return Colors.teal.shade700;
    }
  }

  String _getLevelTitle(DrowsinessRiskLevel level) {
    switch (level) {
      case DrowsinessRiskLevel.criticalMicrosleepRisk:
        return 'MICROSLEEP RISK';
      case DrowsinessRiskLevel.highFatigue:
        return 'HIGH FATIGUE';
      case DrowsinessRiskLevel.mildFatigue:
        return 'MILD FATIGUE';
      case DrowsinessRiskLevel.normal:
        return 'ALERT & VIGILANT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(audit.riskLevel);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: audit.requiresImmediateRestBreak ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: audit.requiresImmediateRestBreak ? 1.5 : 1.0,
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
                  Icons.favorite_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Biometric Vigilance Monitor',
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
                    _getLevelTitle(audit.riskLevel),
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
                    'Heart Rate',
                    '${audit.averageBpm.toStringAsFixed(0)} bpm',
                    Icons.monitor_heart_outlined,
                  ),
                  _buildMetric(
                    context,
                    'HRV (RMSSD)',
                    '${audit.rmssdMs.toStringAsFixed(0)} ms',
                    Icons.waves_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Fatigue Index',
                    '${audit.fatigueIndexPercent.toStringAsFixed(0)}%',
                    Icons.bedtime_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              audit.recommendation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (audit.requiresImmediateRestBreak) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: statusColor,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onAcknowledgeAlert,
                  icon: const Icon(Icons.coffee_rounded, size: 18),
                  label: const Text(
                    'Schedule Immediate Rest Break',
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
