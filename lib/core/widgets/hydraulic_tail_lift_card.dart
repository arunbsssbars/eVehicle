import 'package:flutter/material.dart';
import '../services/hydraulic_tail_lift_service.dart';

/// Card showing hydraulic tail-lift cylinder seal wear, fluid health, and remaining cycles.
class HydraulicTailLiftCard extends StatelessWidget {
  final HydraulicHealthAudit audit;
  final int currentCycles;
  final VoidCallback? onScheduleService;

  const HydraulicTailLiftCard({
    super.key,
    required this.audit,
    required this.currentCycles,
    this.onScheduleService,
  });

  Color _getStatusColor(HydraulicWearStatus status) {
    switch (status) {
      case HydraulicWearStatus.sealOverhaulMandatory:
        return Colors.red.shade700;
      case HydraulicWearStatus.fluidDegraded:
      case HydraulicWearStatus.serviceRecommended:
        return Colors.orange.shade800;
      case HydraulicWearStatus.normalOperational:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(HydraulicWearStatus status) {
    switch (status) {
      case HydraulicWearStatus.sealOverhaulMandatory:
        return 'LOCKOUT HAZARD';
      case HydraulicWearStatus.fluidDegraded:
        return 'OIL DEGRADED';
      case HydraulicWearStatus.serviceRecommended:
        return 'SERVICE DUE';
      case HydraulicWearStatus.normalOperational:
        return 'HEALTHY';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(audit.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: audit.safetyLockoutRequired ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: audit.safetyLockoutRequired ? 1.5 : 1.0,
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
                  Icons.precision_manufacturing_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hydraulic Tail-Lift Duty Wear',
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
                    _getStatusTitle(audit.status),
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
                    'Duty Cycles',
                    '$currentCycles',
                    Icons.repeat_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Seal Wear',
                    '${audit.sealWearPercentage.toStringAsFixed(0)}%',
                    Icons.hardware_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Remaining',
                    '${audit.remainingCyclesToOverhaul}',
                    Icons.hourglass_bottom_rounded,
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
            if (audit.safetyLockoutRequired || onScheduleService != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: audit.safetyLockoutRequired ? statusColor : theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onScheduleService,
                  icon: const Icon(Icons.build_rounded, size: 18),
                  label: Text(
                    audit.safetyLockoutRequired ? 'Schedule Emergency Hydraulic Service' : 'Log Maintenance Inspection',
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
