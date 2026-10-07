import 'package:flutter/material.dart';
import '../services/parasitic_drain_service.dart';

/// Card showing battery voltage, parasitic vampire draw, and low-voltage disconnect relay status.
class ParasiticDrainCard extends StatelessWidget {
  final ElectricalHealthAudit audit;
  final double currentVoltage;
  final double quiescentDrawMilliAmps;
  final VoidCallback? onTripDisconnectRelay;

  const ParasiticDrainCard({
    super.key,
    required this.audit,
    required this.currentVoltage,
    required this.quiescentDrawMilliAmps,
    this.onTripDisconnectRelay,
  });

  Color _getStatusColor(ElectricalHealthStatus status) {
    switch (status) {
      case ElectricalHealthStatus.criticalStartingRisk:
        return Colors.red.shade700;
      case ElectricalHealthStatus.parasiticDrainExcessive:
      case ElectricalHealthStatus.alternatorCurrentMismatch:
        return Colors.orange.shade800;
      case ElectricalHealthStatus.normalHoldingCharge:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(ElectricalHealthStatus status) {
    switch (status) {
      case ElectricalHealthStatus.criticalStartingRisk:
        return 'DEAD RISK';
      case ElectricalHealthStatus.parasiticDrainExcessive:
        return 'VAMPIRE DRAIN';
      case ElectricalHealthStatus.alternatorCurrentMismatch:
        return 'ALT MISMATCH';
      case ElectricalHealthStatus.normalHoldingCharge:
        return 'CHARGED';
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
          color: audit.isolationRelayTripRecommended ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: audit.isolationRelayTripRecommended ? 1.5 : 1.0,
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
                  Icons.battery_alert_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Parasitic Drain & Battery Health',
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
                    'Battery OCV',
                    '${currentVoltage.toStringAsFixed(1)}V',
                    Icons.bolt_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Vampire Draw',
                    '${quiescentDrawMilliAmps.toStringAsFixed(0)} mA',
                    Icons.electric_meter_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Reserve Time',
                    audit.estimatedHoursUntilNoStart > 168
                        ? '> 7 days'
                        : '${audit.estimatedHoursUntilNoStart}h',
                    Icons.hourglass_top_rounded,
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
            if (audit.isolationRelayTripRecommended && onTripDisconnectRelay != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: statusColor,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onTripDisconnectRelay,
                  icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                  label: const Text(
                    'Trip Low-Voltage Disconnect Relay',
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
