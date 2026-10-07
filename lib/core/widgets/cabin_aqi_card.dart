import 'package:flutter/material.dart';
import '../services/cabin_aqi_service.dart';

/// Card showing cabin AQI, CO2 levels, and purifier / damper state.
class CabinAqiCard extends StatelessWidget {
  final CabinAirQualityAudit audit;
  final int currentCo2Ppm;
  final VoidCallback? onPurifierBoost;

  const CabinAqiCard({
    super.key,
    required this.audit,
    required this.currentCo2Ppm,
    this.onPurifierBoost,
  });

  Color _getStatusColor(CabinAirQualityTier tier) {
    switch (tier) {
      case CabinAirQualityTier.hazardousDrowsinessTrigger:
        return Colors.red.shade700;
      case CabinAirQualityTier.unhealthy:
        return Colors.orange.shade800;
      case CabinAirQualityTier.moderate:
        return Colors.amber.shade700;
      case CabinAirQualityTier.pristine:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(CabinAirQualityTier tier) {
    switch (tier) {
      case CabinAirQualityTier.hazardousDrowsinessTrigger:
        return 'HAZARDOUS CO₂';
      case CabinAirQualityTier.unhealthy:
        return 'POOR AIR';
      case CabinAirQualityTier.moderate:
        return 'MODERATE';
      case CabinAirQualityTier.pristine:
        return 'PRISTINE';
    }
  }

  String _getDamperTitle(CabinDamperMode mode) {
    switch (mode) {
      case CabinDamperMode.emergencyVentilate:
        return 'EMERGENCY FLUSH';
      case CabinDamperMode.recirculationPurify:
        return 'RECIRCULATE & PURIFY';
      case CabinDamperMode.freshAirIntake:
        return 'FRESH AIR INTAKE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(audit.tier);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: audit.cognitiveImpairmentRisk ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: audit.cognitiveImpairmentRisk ? 1.5 : 1.0,
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
                  Icons.air_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cabin Air Quality & CO₂',
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
                    _getStatusTitle(audit.tier),
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
                    'In-Cabin AQI',
                    '${audit.calculatedAqi}',
                    Icons.grain_rounded,
                  ),
                  _buildMetric(
                    context,
                    'CO₂ Level',
                    '$currentCo2Ppm ppm',
                    Icons.co2_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Damper Mode',
                    _getDamperTitle(audit.recommendedDamperMode),
                    Icons.sync_alt_rounded,
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
            if (onPurifierBoost != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: statusColor,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onPurifierBoost,
                  icon: const Icon(Icons.mode_fan_off_rounded, size: 18),
                  label: const Text(
                    'Trigger Fresh Air Cabin Ventilation',
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
