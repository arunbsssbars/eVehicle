import 'package:flutter/material.dart';
import '../services/solar_range_extender_service.dart';

/// Card presenting solar PV energy harvesting and range extender metrics.
class SolarRangeExtenderCard extends StatelessWidget {
  final SolarEnergyYieldAudit audit;
  final VoidCallback? onConfigurePanels;

  const SolarRangeExtenderCard({
    super.key,
    required this.audit,
    this.onConfigurePanels,
  });

  Color _getStatusColor(SolarGenerationStatus status) {
    switch (status) {
      case SolarGenerationStatus.peakIrradiance:
        return Colors.amber.shade700;
      case SolarGenerationStatus.optimalClearSky:
        return Colors.teal.shade700;
      case SolarGenerationStatus.overcastSuboptimal:
        return Colors.blueGrey.shade600;
      case SolarGenerationStatus.dormantNight:
        return Colors.grey.shade600;
    }
  }

  String _getStatusTitle(SolarGenerationStatus status) {
    switch (status) {
      case SolarGenerationStatus.peakIrradiance:
        return 'PEAK YIELD';
      case SolarGenerationStatus.optimalClearSky:
        return 'ACTIVE HARVEST';
      case SolarGenerationStatus.overcastSuboptimal:
        return 'SUBOPTIMAL';
      case SolarGenerationStatus.dormantNight:
        return 'DORMANT';
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
                  Icons.wb_sunny_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Solar PV Range Extender',
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
                    'Current Power',
                    '${audit.currentPowerOutputWatts.toStringAsFixed(0)} W',
                    Icons.bolt_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Range Extended',
                    '+${audit.netExtendedRangeKm.toStringAsFixed(1)} km',
                    Icons.add_road_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Day Harvest',
                    '${audit.dailyGenerationKwh.toStringAsFixed(1)} kWh',
                    Icons.solar_power_rounded,
                  ),
                  _buildMetric(
                    context,
                    'CO₂ Avoided',
                    '${audit.co2AvoidedKg.toStringAsFixed(1)} kg',
                    Icons.eco_rounded,
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
            if (onConfigurePanels != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onConfigurePanels,
                  icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                  label: const Text(
                    'Configure Rooftop Solar Array',
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
