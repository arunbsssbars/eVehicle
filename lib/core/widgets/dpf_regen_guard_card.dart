import 'package:flutter/material.dart';
import '../services/dpf_regen_guard_service.dart';

/// Interactive AQIL-compliant card for Diesel Particulate Filter (DPF) soot loading & regeneration safety.
class DpfRegenGuardCard extends StatelessWidget {
  final DpfHealthAudit audit;
  final DpfExhaustTelemetry telemetry;
  final VoidCallback? onTriggerParkedRegen;

  const DpfRegenGuardCard({
    super.key,
    required this.audit,
    required this.telemetry,
    this.onTriggerParkedRegen,
  });

  Color _getStateColor(DpfRegenState state) {
    switch (state) {
      case DpfRegenState.sootCleanNormal:
        return Colors.green;
      case DpfRegenState.passiveRegenUnderway:
        return Colors.teal;
      case DpfRegenState.activeRegenRequired:
        return Colors.amber.shade800;
      case DpfRegenState.parkedRegenMandatory:
        return Colors.deepOrange;
      case DpfRegenState.dpfCrackedFilterAlarm:
        return Colors.red;
    }
  }

  IconData _getStateIcon(DpfRegenState state) {
    switch (state) {
      case DpfRegenState.sootCleanNormal:
        return Icons.check_circle_outline;
      case DpfRegenState.passiveRegenUnderway:
        return Icons.local_fire_department;
      case DpfRegenState.activeRegenRequired:
        return Icons.warning_amber_rounded;
      case DpfRegenState.parkedRegenMandatory:
        return Icons.error_outline;
      case DpfRegenState.dpfCrackedFilterAlarm:
        return Icons.broken_image_outlined;
    }
  }

  String _formatStateLabel(DpfRegenState state) {
    switch (state) {
      case DpfRegenState.sootCleanNormal:
        return 'NORMAL';
      case DpfRegenState.passiveRegenUnderway:
        return 'PASSIVE REGEN';
      case DpfRegenState.activeRegenRequired:
        return 'ACTIVE REGEN REQ';
      case DpfRegenState.parkedRegenMandatory:
        return 'PARKED REGEN REQ';
      case DpfRegenState.dpfCrackedFilterAlarm:
        return 'CRACKED FILTER';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStateColor(audit.state);
    final iconData = _getStateIcon(audit.state);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                Icon(iconData, color: statusColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DPF Aftertreatment Guard',
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
                    _formatStateLabel(audit.state),
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

            // Soot Capacity Progress Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Soot Loading (${telemetry.sootMassGrams.toStringAsFixed(1)}g)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${audit.sootCapacityPercentage.toStringAsFixed(1)}%',
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
                value: (audit.sootCapacityPercentage / 100.0).clamp(0.0, 1.0),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),

            // Core Telemetry Metrics Row
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricCell(
                    context,
                    'Delta Pressure',
                    '${telemetry.differentialPressureMbar.toStringAsFixed(0)} mbar',
                  ),
                  _buildMetricCell(
                    context,
                    'Exhaust Temp',
                    '${telemetry.exhaustGasTempCelsius.toStringAsFixed(0)} °C',
                  ),
                  _buildMetricCell(
                    context,
                    'Speed',
                    '${telemetry.vehicleSpeedKmh.toStringAsFixed(0)} km/h',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Status Diagnostic Summary
            Text(
              audit.statusSummary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            // Parked Regen Action Button
            if (audit.parkedRegenRequired) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onTriggerParkedRegen,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  icon: const Icon(Icons.local_fire_department, size: 18),
                  label: const Text(
                    'Initiate Parked Regen Protocol',
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

  Widget _buildMetricCell(BuildContext context, String label, String value) {
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
