import 'package:flutter/material.dart';
import '../services/multi_zone_reefer_service.dart';

/// Card displaying multi-zone refrigeration compartment temperatures, frost thickness, and alarms.
class MultiZoneReeferCard extends StatelessWidget {
  final MultiZoneReeferAudit audit;
  final List<ReeferZoneReading> zones;
  final VoidCallback? onTriggerDefrost;

  const MultiZoneReeferCard({
    super.key,
    required this.audit,
    required this.zones,
    this.onTriggerDefrost,
  });

  Color _getStatusColor(ReeferOperatingMode mode) {
    switch (mode) {
      case ReeferOperatingMode.temperatureDeviationAlarm:
        return Colors.red.shade700;
      case ReeferOperatingMode.defrostCycleActive:
        return Colors.orange.shade800;
      case ReeferOperatingMode.coolingPullDown:
        return Colors.blue.shade700;
      case ReeferOperatingMode.setpointSatisfied:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(ReeferOperatingMode mode) {
    switch (mode) {
      case ReeferOperatingMode.temperatureDeviationAlarm:
        return 'TEMP ALARM';
      case ReeferOperatingMode.defrostCycleActive:
        return 'DEFROST';
      case ReeferOperatingMode.coolingPullDown:
        return 'PULL-DOWN';
      case ReeferOperatingMode.setpointSatisfied:
        return 'STABLE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(audit.mode);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: audit.requiresEmergencyInspection ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: audit.requiresEmergencyInspection ? 1.5 : 1.0,
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
                  Icons.kitchen_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Multi-Zone Cold-Chain Reefer',
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
                    _getStatusTitle(audit.mode),
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
                children: zones.map((z) {
                  final isViolated = z.isViolated();
                  return _buildZoneMetric(
                    context,
                    z.zoneName,
                    '${z.currentTempCelsius.toStringAsFixed(1)}°C',
                    'Set: ${z.setpointTempCelsius.toStringAsFixed(0)}°C',
                    isViolated,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              audit.statusSummary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (audit.hotGasDefrostNeeded && onTriggerDefrost != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onTriggerDefrost,
                  icon: const Icon(Icons.whatshot_rounded, size: 18),
                  label: const Text(
                    'Execute Hot-Gas Defrost Cycle',
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

  Widget _buildZoneMetric(BuildContext context, String title, String temp, String setpoint, bool isViolated) {
    final theme = Theme.of(context);
    final color = isViolated ? Colors.red.shade700 : theme.colorScheme.primary;

    return Flexible(
      child: Column(
        children: [
          Icon(Icons.thermostat_rounded, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            temp,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isViolated ? Colors.red.shade700 : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            setpoint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
