import 'package:flutter/material.dart';
import '../services/regen_efficiency_service.dart';

/// Card showing regenerative braking recovery metrics, friction losses, and range recaptured.
class RegenEfficiencyCard extends StatelessWidget {
  final RegenEfficiencyAudit audit;
  final VoidCallback? onAdjustRegenProfile;

  const RegenEfficiencyCard({
    super.key,
    required this.audit,
    this.onAdjustRegenProfile,
  });

  Color _getStatusColor(RegenEfficiencyGrade grade) {
    switch (grade) {
      case RegenEfficiencyGrade.excellentOnePedal:
        return Colors.teal.shade700;
      case RegenEfficiencyGrade.goodModerate:
        return Colors.green.shade700;
      case RegenEfficiencyGrade.poorFrictionHeavy:
        return Colors.orange.shade800;
      case RegenEfficiencyGrade.criticalWastedHeat:
        return Colors.red.shade700;
    }
  }

  String _getStatusTitle(RegenEfficiencyGrade grade) {
    switch (grade) {
      case RegenEfficiencyGrade.excellentOnePedal:
        return 'EXCELLENT';
      case RegenEfficiencyGrade.goodModerate:
        return 'GOOD';
      case RegenEfficiencyGrade.poorFrictionHeavy:
        return 'FRICTION LOSS';
      case RegenEfficiencyGrade.criticalWastedHeat:
        return 'WASTED HEAT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(audit.grade);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.2),
          width: 1.0,
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
                  Icons.energy_savings_leaf_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Regenerative KERS Efficiency',
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
                    _getStatusTitle(audit.grade),
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
                    'Efficiency',
                    '${audit.captureEfficiencyPercent.toStringAsFixed(0)}%',
                    Icons.bolt_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Recaptured',
                    '${audit.recapturedEnergyKwh.toStringAsFixed(3)} kWh',
                    Icons.battery_charging_full_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Added Range',
                    '+${audit.addedRangeMeters.toStringAsFixed(0)} m',
                    Icons.add_road_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              audit.coachingTip,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onAdjustRegenProfile != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onAdjustRegenProfile,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text(
                    'Adjust Regenerative Braking Profile',
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
