import 'package:flutter/material.dart';
import '../services/ev_charging_thermal_service.dart';

/// Card showing battery temperature readiness, deliverable kW, and pre-conditioning status.
class EvChargingThermalCard extends StatelessWidget {
  final ChargeThermalAudit audit;
  final double currentPackTempCelsius;
  final VoidCallback? onActivatePreconditioning;

  const EvChargingThermalCard({
    super.key,
    required this.audit,
    required this.currentPackTempCelsius,
    this.onActivatePreconditioning,
  });

  Color _getStatusColor(BatteryThermalBand band) {
    switch (band) {
      case BatteryThermalBand.overheatCutoff:
      case BatteryThermalBand.freezingPlateRisk:
        return Colors.red.shade700;
      case BatteryThermalBand.hotDerating:
      case BatteryThermalBand.coldSuboptimal:
        return Colors.orange.shade800;
      case BatteryThermalBand.optimalFastAcceptance:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(BatteryThermalBand band) {
    switch (band) {
      case BatteryThermalBand.overheatCutoff:
        return 'OVERHEAT CUT';
      case BatteryThermalBand.freezingPlateRisk:
        return 'FREEZING DANGER';
      case BatteryThermalBand.hotDerating:
        return 'THERMAL DERATE';
      case BatteryThermalBand.coldSuboptimal:
        return 'COLD SLOW';
      case BatteryThermalBand.optimalFastAcceptance:
        return 'OPTIMAL PEAK';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(audit.thermalBand);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: audit.preconditioningActive ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
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
                  Icons.electric_bolt_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'EV Battery Thermal Charging',
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
                    _getStatusTitle(audit.thermalBand),
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
                    'Pack Temp',
                    '${currentPackTempCelsius.toStringAsFixed(0)}°C',
                    Icons.thermostat_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Charge Power',
                    '${audit.deliverablePowerKw.toStringAsFixed(0)} kW',
                    Icons.ev_station_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Pre-Condition',
                    audit.preconditioningMinutesRequired > 0
                        ? '${audit.preconditioningMinutesRequired} min'
                        : 'READY',
                    Icons.hvac_rounded,
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
            if (audit.preconditioningMinutesRequired > 0 && onActivatePreconditioning != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onActivatePreconditioning,
                  icon: const Icon(Icons.heat_pump_rounded, size: 18),
                  label: Text(
                    'Pre-Condition Battery (${audit.preconditioningMinutesRequired} min / ${audit.preconditioningEnergyCostKwh.toStringAsFixed(1)} kWh)',
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
