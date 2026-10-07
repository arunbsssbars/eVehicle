import 'package:flutter/material.dart';
import '../services/chassis_corrosion_service.dart';

/// Card showing undercarriage road salt exposure, corrosion index, and wash scheduling.
class ChassisCorrosionCard extends StatelessWidget {
  final ChassisCorrosionAudit audit;
  final int daysSinceWash;
  final VoidCallback? onScheduleWash;

  const ChassisCorrosionCard({
    super.key,
    required this.audit,
    required this.daysSinceWash,
    this.onScheduleWash,
  });

  Color _getStatusColor(CorrosionRiskLevel level) {
    switch (level) {
      case CorrosionRiskLevel.criticalCorrosionHazard:
        return Colors.red.shade700;
      case CorrosionRiskLevel.heavySaltAccumulation:
        return Colors.orange.shade800;
      case CorrosionRiskLevel.mildExposure:
        return Colors.amber.shade700;
      case CorrosionRiskLevel.cleanProtected:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(CorrosionRiskLevel level) {
    switch (level) {
      case CorrosionRiskLevel.criticalCorrosionHazard:
        return 'CRITICAL SALT';
      case CorrosionRiskLevel.heavySaltAccumulation:
        return 'WASH DUE';
      case CorrosionRiskLevel.mildExposure:
        return 'MILD RESIDUE';
      case CorrosionRiskLevel.cleanProtected:
        return 'PROTECTED';
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
          color: audit.requiresMandatoryChassisWash ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: audit.requiresMandatoryChassisWash ? 1.5 : 1.0,
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
                  Icons.local_car_wash_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chassis Salt & Corrosion Guard',
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
                    'Last Wash',
                    '$daysSinceWash days ago',
                    Icons.calendar_today_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Corrosion Index',
                    '${audit.corrosionIndexScore.toStringAsFixed(0)}/100',
                    Icons.shield_outlined,
                  ),
                  _buildMetric(
                    context,
                    'Wash Window',
                    audit.recommendedWashWindowDays == 0
                        ? 'TODAY'
                        : '${audit.recommendedWashWindowDays} days',
                    Icons.schedule_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              audit.statusSummary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onScheduleWash != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: audit.requiresMandatoryChassisWash ? statusColor : theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onScheduleWash,
                  icon: const Icon(Icons.waves_rounded, size: 18),
                  label: const Text(
                    'Book Undercarriage High-Pressure Wash',
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
