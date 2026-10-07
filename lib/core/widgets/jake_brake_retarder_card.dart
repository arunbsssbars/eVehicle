import 'package:flutter/material.dart';
import '../services/jake_brake_retarder_service.dart';

/// Card displaying engine compression brake retarder stages, downhill grade power, and noise ordinances.
class JakeBrakeRetarderCard extends StatelessWidget {
  final RetarderGradeAudit audit;
  final double roadGradePercent;
  final VoidCallback? onToggleRetarderStage;

  const JakeBrakeRetarderCard({
    super.key,
    required this.audit,
    required this.roadGradePercent,
    this.onToggleRetarderStage,
  });

  Color _getStatusColor(RetarderNoiseZoneStatus status) {
    switch (status) {
      case RetarderNoiseZoneStatus.emergencyExemptionActive:
        return Colors.red.shade700;
      case RetarderNoiseZoneStatus.noiseOrdinanceRestricted:
        return Colors.orange.shade800;
      case RetarderNoiseZoneStatus.unrestrictedHighway:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(RetarderNoiseZoneStatus status) {
    switch (status) {
      case RetarderNoiseZoneStatus.emergencyExemptionActive:
        return 'SAFETY OVERRIDE';
      case RetarderNoiseZoneStatus.noiseOrdinanceRestricted:
        return 'NO JAKE ZONE';
      case RetarderNoiseZoneStatus.unrestrictedHighway:
        return 'RETARDER ACTIVE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(audit.noiseZoneStatus);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: audit.serviceBrakeAssistanceRequired ? Colors.red.shade700 : theme.dividerColor.withValues(alpha: 0.2),
          width: audit.serviceBrakeAssistanceRequired ? 1.5 : 1.0,
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
                  Icons.downhill_skiing_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jake Brake & Grade Retarder',
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
                    _getStatusTitle(audit.noiseZoneStatus),
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
                    'Grade Slope',
                    '${roadGradePercent.toStringAsFixed(1)}%',
                    Icons.trending_down_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Stage',
                    audit.recommendedStage.name.replaceAll('Stage', ' Stg ').toUpperCase(),
                    Icons.speed_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Hold Power',
                    '${audit.retardingPowerKw.toStringAsFixed(0)} kW',
                    Icons.power_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              audit.operationalAdvisory,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onToggleRetarderStage != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onToggleRetarderStage,
                  icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                  label: const Text(
                    'Manually Select Retarder Stage',
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
