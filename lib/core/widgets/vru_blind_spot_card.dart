import 'package:flutter/material.dart';
import '../services/vru_blind_spot_service.dart';

/// Card alerting commercial drivers to cyclists and pedestrians in vehicle blind spots.
class VruBlindSpotCard extends StatelessWidget {
  final VruBlindSpotAudit audit;
  final double currentLateralDistanceMeters;
  final VoidCallback? onAcknowledgeAlert;

  const VruBlindSpotCard({
    super.key,
    required this.audit,
    required this.currentLateralDistanceMeters,
    this.onAcknowledgeAlert,
  });

  Color _getStatusColor(VruThreatLevel level) {
    switch (level) {
      case VruThreatLevel.imminentCollisionAlert:
        return Colors.red.shade700;
      case VruThreatLevel.vruDetectedAdvisory:
        return Colors.amber.shade800;
      case VruThreatLevel.clearNoHazard:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(VruThreatLevel level) {
    switch (level) {
      case VruThreatLevel.imminentCollisionAlert:
        return 'COLLISION HAZARD';
      case VruThreatLevel.vruDetectedAdvisory:
        return 'VRU DETECTED';
      case VruThreatLevel.clearNoHazard:
        return 'CORRIDOR CLEAR';
    }
  }

  IconData _getTargetIcon(VruTargetType type) {
    switch (type) {
      case VruTargetType.cyclistBicycle:
        return Icons.directions_bike_rounded;
      case VruTargetType.pedestrian:
        return Icons.directions_walk_rounded;
      case VruTargetType.electricScooter:
        return Icons.electric_scooter_rounded;
      case VruTargetType.none:
        return Icons.shield_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(audit.threatLevel);
    final isCritical = audit.threatLevel == VruThreatLevel.imminentCollisionAlert;

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
            Row(
              children: [
                Icon(
                  _getTargetIcon(audit.targetType),
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Blind Spot VRU & Cyclist Guard',
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
                    _getStatusTitle(audit.threatLevel),
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
                    'Target',
                    audit.targetType == VruTargetType.none ? 'None' : audit.targetType.name.toUpperCase(),
                    _getTargetIcon(audit.targetType),
                  ),
                  _buildMetric(
                    context,
                    'Distance',
                    audit.threatLevel == VruThreatLevel.clearNoHazard
                        ? '> 10 m'
                        : '${currentLateralDistanceMeters.toStringAsFixed(1)} m',
                    Icons.radar_rounded,
                  ),
                  _buildMetric(
                    context,
                    'TTC Window',
                    audit.timeToCollisionSeconds >= 90.0
                        ? 'SAFE'
                        : '${audit.timeToCollisionSeconds.toStringAsFixed(1)} s',
                    Icons.timer_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              audit.warningMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isCritical) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: statusColor,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onAcknowledgeAlert,
                  icon: const Icon(Icons.emergency_rounded, size: 18),
                  label: const Text(
                    'ABORT TURN - VRU IN PATH',
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
