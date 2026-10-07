import 'package:flutter/material.dart';
import '../services/emergency_vehicle_detector_service.dart';

/// Card alerting drivers to sirens and approaching emergency vehicles for Move-Over safety.
class EmergencyVehicleDetectorCard extends StatelessWidget {
  final MoveOverSafetyAudit audit;
  final double currentDistanceMeters;
  final VoidCallback? onAcknowledgeYield;

  const EmergencyVehicleDetectorCard({
    super.key,
    required this.audit,
    required this.currentDistanceMeters,
    this.onAcknowledgeYield,
  });

  Color _getStatusColor(EmergencyYieldStatus status) {
    switch (status) {
      case EmergencyYieldStatus.imminentYieldRequired:
        return Colors.red.shade700;
      case EmergencyYieldStatus.distantSirenAdvisory:
        return Colors.orange.shade800;
      case EmergencyYieldStatus.noEmergencyVehicleDetected:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(EmergencyYieldStatus status) {
    switch (status) {
      case EmergencyYieldStatus.imminentYieldRequired:
        return 'MOVE OVER NOW';
      case EmergencyYieldStatus.distantSirenAdvisory:
        return 'SIREN ADVISORY';
      case EmergencyYieldStatus.noEmergencyVehicleDetected:
        return 'NORMAL TRAFFIC';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(audit.status);
    final isEmergency = audit.status == EmergencyYieldStatus.imminentYieldRequired;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEmergency ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: isEmergency ? 1.5 : 1.0,
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
                  Icons.notifications_active_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Acoustic Siren & Move-Over Guard',
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
                    'Responder',
                    audit.estimatedServiceType == EmergencyServiceType.none
                        ? 'None'
                        : audit.estimatedServiceType.name.toUpperCase(),
                    Icons.local_hospital_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Distance',
                    audit.status == EmergencyYieldStatus.noEmergencyVehicleDetected
                        ? '> 500 m'
                        : '${currentDistanceMeters.toStringAsFixed(0)} m',
                    Icons.radar_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Overtake In',
                    audit.timeToOvertakeSeconds >= 90.0
                        ? 'CLEAR'
                        : '${audit.timeToOvertakeSeconds.toStringAsFixed(0)} s',
                    Icons.timer_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              audit.yieldAdvisory,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isEmergency) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: statusColor,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onAcknowledgeYield,
                  icon: const Icon(Icons.turn_right_rounded, size: 18),
                  label: const Text(
                    'MOVE RIGHT & YIELD CORRIDOR',
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
