import 'package:flutter/material.dart';
import '../services/brake_fade_thermal_service.dart';

/// Card displaying mountain grade descent thermal rotor analysis and brake fade risk.
class BrakeFadeThermalCard extends StatelessWidget {
  final BrakeThermalAudit audit;
  final MountainDescentTelemetry telemetry;
  final VoidCallback? onActivateRunawayRampGuidance;

  const BrakeFadeThermalCard({
    super.key,
    required this.audit,
    required this.telemetry,
    this.onActivateRunawayRampGuidance,
  });

  Color _getRiskColor(BrakeFadeRiskLevel risk) {
    switch (risk) {
      case BrakeFadeRiskLevel.nominalCool:
        return Colors.green;
      case BrakeFadeRiskLevel.moderateThermalLoad:
        return Colors.amber.shade800;
      case BrakeFadeRiskLevel.imminentBrakeFadeWarning:
        return Colors.deepOrange;
      case BrakeFadeRiskLevel.criticalThermalRunawayLockout:
        return Colors.red.shade700;
    }
  }

  String _getRiskLabel(BrakeFadeRiskLevel risk) {
    switch (risk) {
      case BrakeFadeRiskLevel.nominalCool:
        return 'COOL / NOMINAL';
      case BrakeFadeRiskLevel.moderateThermalLoad:
        return 'MODERATE HEAT';
      case BrakeFadeRiskLevel.imminentBrakeFadeWarning:
        return 'FADE RISK';
      case BrakeFadeRiskLevel.criticalThermalRunawayLockout:
        return 'CRITICAL FADE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getRiskColor(audit.riskLevel);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: audit.runawayRampRequired ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: audit.runawayRampRequired ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title & Status Chip
            Row(
              children: [
                Icon(
                  Icons.thermostat_outlined,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Grade Brake Thermal Profiler',
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
                    _getRiskLabel(audit.riskLevel),
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

            // Temperature Visual Gauge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Predicted Rotor Temperature (${telemetry.roadGradePercent.toStringAsFixed(1)}% Grade)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${audit.estimatedRotorTempCelsius.toStringAsFixed(0)}°C',
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
                value: (audit.estimatedRotorTempCelsius / 700.0).clamp(0.0, 1.0),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),

            // Descent Metrics Grid
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
                    'Brake Power',
                    '${audit.brakingThermalAbsorptionKw.toStringAsFixed(0)} kW',
                  ),
                  _buildMetric(
                    context,
                    'Dissipated Energy',
                    '${audit.cumulativeDissipatedEnergyMegaJoules.toStringAsFixed(1)} MJ',
                  ),
                  _buildMetric(
                    context,
                    'Safe Speed',
                    '${audit.recommendedSafeDescentSpeedKmh.toStringAsFixed(0)} km/h',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Advisory Message
            Text(
              audit.safetyAdvisory,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            if (audit.runawayRampRequired || onActivateRunawayRampGuidance != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: audit.runawayRampRequired ? statusColor : theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onActivateRunawayRampGuidance,
                  icon: const Icon(Icons.emergency_outlined, size: 18),
                  label: const Text(
                    'Locate Runaway Escape Ramp',
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

  Widget _buildMetric(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Flexible(
      child: Column(
        children: [
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
