import 'package:flutter/material.dart';
import '../services/fleet_platooning_service.dart';

/// Card showing V2V convoy platooning status, headway gap, and aerodynamic fuel savings.
class FleetPlatooningCard extends StatelessWidget {
  final PlatoonSafetyAudit audit;
  final String platoonId;
  final PlatoonRole role;
  final VoidCallback? onDecouplePlatoon;

  const FleetPlatooningCard({
    super.key,
    required this.audit,
    required this.platoonId,
    required this.role,
    this.onDecouplePlatoon,
  });

  Color _getStatusColor(PlatoonCouplingState state) {
    switch (state) {
      case PlatoonCouplingState.emergencyDecouple:
        return Colors.red.shade700;
      case PlatoonCouplingState.v2vLatencyDegraded:
        return Colors.orange.shade800;
      case PlatoonCouplingState.safeCruisingGap:
        return Colors.blue.shade700;
      case PlatoonCouplingState.tightAerodynamicLock:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(PlatoonCouplingState state) {
    switch (state) {
      case PlatoonCouplingState.emergencyDecouple:
        return 'DECOUPLED';
      case PlatoonCouplingState.v2vLatencyDegraded:
        return 'LATENCY HIGH';
      case PlatoonCouplingState.safeCruisingGap:
        return 'CRUISING';
      case PlatoonCouplingState.tightAerodynamicLock:
        return 'AERO LOCKED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(audit.state);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: audit.requiresEmergencyDecouple ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: audit.requiresEmergencyDecouple ? 1.5 : 1.0,
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
                  Icons.airline_stops_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'V2V Autonomous Platooning',
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
                    _getStatusTitle(audit.state),
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
                    'Platoon Role',
                    role.name.replaceAll('Vehicle', '').toUpperCase(),
                    Icons.directions_car_filled_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Headway',
                    '${audit.timeHeadwaySeconds.toStringAsFixed(1)}s',
                    Icons.space_bar_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Aero Saving',
                    '+${audit.aerodynamicFuelSavingsPercent.toStringAsFixed(1)}%',
                    Icons.air_rounded,
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
            if (onDecouplePlatoon != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onDecouplePlatoon,
                  icon: const Icon(Icons.link_off_rounded, size: 18),
                  label: const Text(
                    'Manually Decouple from Platoon Convoy',
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
