import 'package:flutter/material.dart';
import '../services/hvil_isolation_service.dart';

/// Card displaying EV High-Voltage Interlock Loop (HVIL) and chassis isolation resistance metrics.
class HvilIsolationCard extends StatelessWidget {
  final HvilIsolationAudit audit;
  final HvilIsolationTelemetry telemetry;
  final VoidCallback? onDispatchEvTechnician;

  const HvilIsolationCard({
    super.key,
    required this.audit,
    required this.telemetry,
    this.onDispatchEvTechnician,
  });

  Color _getStatusColor() {
    if (audit.activeHighVoltageHazard) {
      return Colors.red.shade700;
    }
    if (audit.isolationStatus == HvIsolationStatus.warningDegradation ||
        audit.hvilStatus == HvilCircuitStatus.highResistanceDegraded) {
      return Colors.amber.shade800;
    }
    return Colors.teal.shade700;
  }

  String _getStatusLabel() {
    if (audit.activeHighVoltageHazard) {
      return 'HV HAZARD LOCKOUT';
    }
    if (audit.isolationStatus == HvIsolationStatus.warningDegradation ||
        audit.hvilStatus == HvilCircuitStatus.highResistanceDegraded) {
      return 'DEGRADED WARNING';
    }
    return 'HV INTERLOCK SECURE';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: audit.activeHighVoltageHazard ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: audit.activeHighVoltageHazard ? 1.5 : 1.0,
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
                  Icons.bolt_rounded,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'EV HVIL & Isolation Guard',
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

            // Isolation Status Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Chassis Isolation (${telemetry.busVoltageVdc.toStringAsFixed(0)}V DC-Link)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${audit.minimumIsolationOhmsPerVolt.toStringAsFixed(0)} Ω/V',
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
                value: (audit.minimumIsolationOhmsPerVolt / 2000.0).clamp(0.0, 1.0),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),

            // Diagnostic Telemetry Details
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
                    'HVIL Loop',
                    '${telemetry.hvilLoopResistanceOhms.toStringAsFixed(1)} Ω',
                  ),
                  _buildMetric(
                    context,
                    'MSD Interlock',
                    telemetry.manualServiceDisconnectPlugged ? 'Plugged' : 'PULLED',
                  ),
                  _buildMetric(
                    context,
                    'Contactors',
                    audit.contactorsPermittedToClose ? 'Ready' : 'LOCKED OPEN',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Safety Advisory
            Text(
              audit.safetyAdvisory,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              audit.recommendedAction,
              style: theme.textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (audit.activeHighVoltageHazard || onDispatchEvTechnician != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: audit.activeHighVoltageHazard ? statusColor : theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onDispatchEvTechnician,
                  icon: const Icon(Icons.engineering_rounded, size: 18),
                  label: const Text(
                    'Dispatch Certified EV Technician',
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
