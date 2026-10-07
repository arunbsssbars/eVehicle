import 'package:flutter/material.dart';
import '../services/hydroplaning_risk_service.dart';

/// Card warning drivers about standing water film depth and dynamic hydroplaning critical speed.
class HydroplaningRiskCard extends StatelessWidget {
  final HydroplaningSafetyAudit audit;
  final VoidCallback? onAcknowledgeAlert;

  const HydroplaningRiskCard({
    super.key,
    required this.audit,
    this.onAcknowledgeAlert,
  });

  Color _getStatusColor(HydroplaningRiskLevel level) {
    switch (level) {
      case HydroplaningRiskLevel.extremeCriticalDanger:
        return Colors.red.shade700;
      case HydroplaningRiskLevel.highHydroplaningHazard:
        return Colors.orange.shade800;
      case HydroplaningRiskLevel.moderateWetSurface:
        return Colors.amber.shade700;
      case HydroplaningRiskLevel.lowDryRoad:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(HydroplaningRiskLevel level) {
    switch (level) {
      case HydroplaningRiskLevel.extremeCriticalDanger:
        return 'CRITICAL HAZARD';
      case HydroplaningRiskLevel.highHydroplaningHazard:
        return 'HIGH RISK';
      case HydroplaningRiskLevel.moderateWetSurface:
        return 'WET ROAD';
      case HydroplaningRiskLevel.lowDryRoad:
        return 'SAFE TRACTION';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(audit.riskLevel);
    final isCritical = audit.riskLevel == HydroplaningRiskLevel.extremeCriticalDanger ||
        audit.riskLevel == HydroplaningRiskLevel.highHydroplaningHazard;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCritical ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: isCritical ? 1.5 : 1.0,
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
                  Icons.thunderstorm_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hydroplaning & Wet Risk',
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
                    _getStatusTitle(audit.riskLevel),
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
                    'Critical Speed',
                    '${audit.criticalHydroplaningSpeedKmh.toStringAsFixed(0)} km/h',
                    Icons.speed_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Safety Margin',
                    '${audit.safetyMarginKmh.toStringAsFixed(0)} km/h',
                    Icons.shield_outlined,
                  ),
                  _buildMetric(
                    context,
                    'Water Film',
                    '${audit.estimatedWaterFilmDepthMm.toStringAsFixed(2)} mm',
                    Icons.water_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              audit.advisoryMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isCritical) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: statusColor,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onAcknowledgeAlert,
                  icon: const Icon(Icons.warning_amber_rounded, size: 18),
                  label: Text(
                    'Limit Speed to ${audit.recommendedSpeedKmh.toStringAsFixed(0)} km/h',
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
