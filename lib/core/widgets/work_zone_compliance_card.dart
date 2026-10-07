import 'package:flutter/material.dart';
import '../services/work_zone_compliance_service.dart';

/// Card alerting drivers and dispatchers to variable speed limits, approaching taper beacons, and worker presence.
class WorkZoneComplianceCard extends StatelessWidget {
  final WorkZoneComplianceAudit audit;
  final WorkZoneGeometry zone;
  final VehicleWorkZoneTelemetry telemetry;
  final VoidCallback? onAcknowledgeAlert;

  const WorkZoneComplianceCard({
    super.key,
    required this.audit,
    required this.zone,
    required this.telemetry,
    this.onAcknowledgeAlert,
  });

  Color _getStatusColor() {
    switch (audit.status) {
      case WorkZoneComplianceStatus.compliantNormal:
        return Colors.teal.shade700;
      case WorkZoneComplianceStatus.cautionApproachingZone:
        return Colors.amber.shade800;
      case WorkZoneComplianceStatus.speedExceededAdvisory:
        return Colors.orange.shade800;
      case WorkZoneComplianceStatus.severeViolationEnforcementRisk:
        return Colors.red.shade700;
    }
  }

  String _getStatusLabel() {
    switch (audit.status) {
      case WorkZoneComplianceStatus.compliantNormal:
        return 'COMPLIANT';
      case WorkZoneComplianceStatus.cautionApproachingZone:
        return 'ZONE AHEAD';
      case WorkZoneComplianceStatus.speedExceededAdvisory:
        return 'OVERSPEED';
      case WorkZoneComplianceStatus.severeViolationEnforcementRisk:
        return 'SEVERE VIOLATION';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor();
    final isCritical = audit.status == WorkZoneComplianceStatus.severeViolationEnforcementRisk;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCritical ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: isCritical ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.traffic_rounded,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zone.zoneName,
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

            // Variable speed indicator badge & workers indicator
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
                    'Zone Limit',
                    '${zone.variableSpeedLimitKmh.toStringAsFixed(0)} km/h',
                    Icons.speed_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Current Speed',
                    '${telemetry.currentVehicleSpeedKmh.toStringAsFixed(0)} km/h',
                    Icons.directions_car_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Workers Present',
                    zone.workersPresentOnRoadway ? 'YES (2x)' : 'NO',
                    Icons.engineering_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Driver Alert Text
            Text(
              audit.driverAlertNotice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              audit.actionRequired,
              style: theme.textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (isCritical || onAcknowledgeAlert != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isCritical ? statusColor : theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onAcknowledgeAlert,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text(
                    'Acknowledge Speed Restriction',
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
