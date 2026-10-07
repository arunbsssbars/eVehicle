import 'package:flutter/material.dart';
import '../services/trailer_coupling_service.dart';

/// Card displaying fifth-wheel kingpin engagement, safety wedge, and air line status.
class TrailerCouplingCard extends StatelessWidget {
  final TrailerCouplingAudit audit;
  final VoidCallback? onPerformPullTest;

  const TrailerCouplingCard({
    super.key,
    required this.audit,
    this.onPerformPullTest,
  });

  Color _getStatusColor(CouplingSafetyStatus status) {
    switch (status) {
      case CouplingSafetyStatus.unlatchedCriticalHazard:
        return Colors.red.shade700;
      case CouplingSafetyStatus.secondaryLatchOpen:
      case CouplingSafetyStatus.pressureMismatchWarning:
        return Colors.orange.shade800;
      case CouplingSafetyStatus.secureLocked:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(CouplingSafetyStatus status) {
    switch (status) {
      case CouplingSafetyStatus.unlatchedCriticalHazard:
        return 'CRITICAL HAZARD';
      case CouplingSafetyStatus.secondaryLatchOpen:
        return 'LATCH OPEN';
      case CouplingSafetyStatus.pressureMismatchWarning:
        return 'CHECK AIR / EBS';
      case CouplingSafetyStatus.secureLocked:
        return 'LOCKED & READY';
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
          color: audit.safeToDepart ? Colors.teal.withValues(alpha: 0.5) : statusColor,
          width: audit.requiresEmergencyStop ? 1.5 : 1.0,
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
                  Icons.link_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fifth Wheel & Kingpin Lock',
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
                    'Departure',
                    audit.safeToDepart ? 'CLEARED' : 'BLOCKED',
                    audit.safeToDepart ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Pneumatics',
                    audit.pneumaticPressureAdequate ? 'PRESSURIZED' : 'LOW AIR',
                    Icons.compress_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Coupling Jaw',
                    audit.status == CouplingSafetyStatus.secureLocked ? 'LATCHED' : 'ALERT',
                    Icons.security_rounded,
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
            if (onPerformPullTest != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onPerformPullTest,
                  icon: const Icon(Icons.car_crash_outlined, size: 18),
                  label: const Text(
                    'Log Pre-Trip Trailer Tug / Pull Test',
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
