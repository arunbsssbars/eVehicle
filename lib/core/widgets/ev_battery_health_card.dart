import 'package:flutter/material.dart';
import '../services/ev_battery_health_service.dart';

/// Defensive AQIL Card displaying EV traction pack State of Health (SoH) and thermal safety.
class EvBatteryHealthCard extends StatelessWidget {
  final BatteryHealthAudit audit;
  final VoidCallback? onInitiateCellBalancing;

  const EvBatteryHealthCard({
    super.key,
    required this.audit,
    this.onInitiateCellBalancing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCritical = audit.status == BatteryThermalStatus.criticalThermalRunawayRisk;
    final isWarning = audit.status == BatteryThermalStatus.cellImbalanceWarning ||
        audit.status == BatteryThermalStatus.elevatedTemperature;
    final statusColor = isCritical
        ? const Color(0xFFDC2626)
        : (isWarning ? Colors.orange.shade800 : const Color(0xFF10B981));

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
                    Icons.electric_bolt,
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
                        'EV Battery Telemetry',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'SoC: ${audit.stateOfChargePercent.toInt()}% • Temp: ${audit.packMaxTempCelsius}°C',
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
                    _statusLabel(audit.status),
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

            // SoH Health Bar Indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        'SoH: ${audit.stateOfHealthPercent}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 4,
                      child: Text(
                        '~${audit.estimatedRemainingCycles} cycles',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
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
                    value: (audit.stateOfHealthPercent / 100.0).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      audit.stateOfHealthPercent >= 80.0
                          ? const Color(0xFF10B981)
                          : (audit.stateOfHealthPercent >= 70.0 ? Colors.amber.shade800 : Colors.red),
                    ),
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
                  label: 'Cell Delta-V',
                  value: '${(audit.cellDeltaV * 1000).toInt()} mV',
                  icon: Icons.tune,
                  color: audit.cellDeltaV >= 0.08 ? Colors.orange.shade800 : null,
                ),
                _buildMetricBox(
                  context,
                  label: 'Peak Temp',
                  value: '${audit.packMaxTempCelsius}°C',
                  icon: Icons.device_thermostat,
                  color: audit.packMaxTempCelsius >= 50.0 ? Colors.red : null,
                ),
                _buildMetricBox(
                  context,
                  label: 'Cell Range',
                  value: '${audit.minCellVoltage}V - ${audit.maxCellVoltage}V',
                  icon: Icons.battery_charging_full,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Safety Advisory Notice
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
                    isCritical ? Icons.warning : (isWarning ? Icons.info_outline : Icons.check_circle_outline),
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
                        color: isCritical ? Colors.red.shade900 : theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (onInitiateCellBalancing != null && (isWarning || isCritical)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.tonalIcon(
                  onPressed: onInitiateCellBalancing,
                  icon: const Icon(Icons.sync_alt, size: 18),
                  label: const Text(
                    'Initiate Active Cell Balancing Routine',
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

  String _statusLabel(BatteryThermalStatus s) {
    switch (s) {
      case BatteryThermalStatus.optimal:
        return 'OPTIMAL';
      case BatteryThermalStatus.elevatedTemperature:
        return 'ELEVATED';
      case BatteryThermalStatus.cellImbalanceWarning:
        return 'IMBALANCE';
      case BatteryThermalStatus.criticalThermalRunawayRisk:
        return 'OVERHEAT';
    }
  }
}
