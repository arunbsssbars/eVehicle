import 'package:flutter/material.dart';
import '../services/rollover_stability_service.dart';

/// Card showing commercial vehicle rollover threshold, Load Transfer Ratio (LTR), and ESP differential braking status.
class RolloverStabilityCard extends StatelessWidget {
  final RolloverStabilityAudit audit;
  final RolloverDynamicsTelemetry telemetry;
  final VoidCallback? onResetEspFault;

  const RolloverStabilityCard({
    super.key,
    required this.audit,
    required this.telemetry,
    this.onResetEspFault,
  });

  Color _getStatusColor() {
    switch (audit.riskState) {
      case RolloverRiskState.stableNominal:
        return Colors.teal.shade700;
      case RolloverRiskState.lateralGWarning:
        return Colors.amber.shade800;
      case RolloverRiskState.espDifferentialBrakingActive:
        return Colors.deepOrange;
      case RolloverRiskState.criticalTrippingOrRollThreshold:
        return Colors.red.shade700;
    }
  }

  String _getStatusLabel() {
    switch (audit.riskState) {
      case RolloverRiskState.stableNominal:
        return 'STABLE';
      case RolloverRiskState.lateralGWarning:
        return 'G WARNING';
      case RolloverRiskState.espDifferentialBrakingActive:
        return 'ESP ACTIVE';
      case RolloverRiskState.criticalTrippingOrRollThreshold:
        return 'ROLL HAZARD';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor();
    final isAlert = audit.espInterventionTriggered;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAlert ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: isAlert ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                Icon(
                  Icons.sync_problem_rounded,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Roll Stability & ESP Guard',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getStatusLabel(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Load Transfer Ratio Gauge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Load Transfer Ratio (LTR)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(audit.loadTransferRatio * 100).toStringAsFixed(0)}% / 100%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: audit.loadTransferRatio.clamp(0.0, 1.0),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),

            // Telemetry Grid
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    context,
                    'Lateral G',
                    '${telemetry.lateralAccelerationG.abs().toStringAsFixed(2)} G',
                    Icons.explore_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Roll Limit (SRT)',
                    '${audit.staticRolloverThresholdG.toStringAsFixed(2)} G',
                    Icons.security_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Torque Cut',
                    '${audit.targetTorqueCutbackPercent.toStringAsFixed(0)}%',
                    Icons.speed_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Intervention summary
            Text(
              audit.activeInterventionSummary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            if (isAlert || onResetEspFault != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isAlert ? statusColor : theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onResetEspFault,
                  icon: const Icon(Icons.car_crash_rounded, size: 18),
                  label: const Text(
                    'Review ESP Intervention Telemetry',
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
