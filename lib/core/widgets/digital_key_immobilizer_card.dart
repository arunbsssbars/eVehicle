import 'package:flutter/material.dart';
import '../services/digital_key_service.dart';

/// Card displaying vehicle keyless access status and remote immobilizer guard.
class DigitalKeyImmobilizerCard extends StatelessWidget {
  final DigitalKeyAccessAudit audit;
  final String tokenId;
  final VoidCallback? onRefreshKey;
  final VoidCallback? onToggleImmobilizer;

  const DigitalKeyImmobilizerCard({
    super.key,
    required this.audit,
    required this.tokenId,
    this.onRefreshKey,
    this.onToggleImmobilizer,
  });

  Color _getStatusColor(ImmobilizerState state) {
    switch (state) {
      case ImmobilizerState.disarmedActive:
        return Colors.teal.shade700;
      case ImmobilizerState.armedStandby:
        return Colors.blueGrey.shade700;
      case ImmobilizerState.tokenExpired:
        return Colors.amber.shade800;
      case ImmobilizerState.emergencyLockdown:
        return Colors.red.shade700;
    }
  }

  String _getStatusTitle(ImmobilizerState state) {
    switch (state) {
      case ImmobilizerState.disarmedActive:
        return 'DISARMED';
      case ImmobilizerState.armedStandby:
        return 'ARMED';
      case ImmobilizerState.tokenExpired:
        return 'EXPIRED';
      case ImmobilizerState.emergencyLockdown:
        return 'SOS LOCKDOWN';
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
          color: audit.ignitionAllowed ? Colors.teal.withValues(alpha: 0.5) : statusColor,
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
                  audit.ignitionAllowed ? Icons.key_rounded : Icons.lock_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Digital Key & Immobilizer',
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
                    'Ignition Auth',
                    audit.ignitionAllowed ? 'PERMITTED' : 'BLOCKED',
                    audit.ignitionAllowed ? Icons.check_circle_rounded : Icons.block_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Token Window',
                    audit.remainingSecondsValid > 0
                        ? '${(audit.remainingSecondsValid / 60).ceil()} min'
                        : '0 min',
                    Icons.timer_outlined,
                  ),
                  _buildMetric(
                    context,
                    'Key Token',
                    tokenId.length > 8 ? tokenId.substring(0, 8) : tokenId,
                    Icons.fingerprint_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              audit.statusDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (audit.requiresReauthorization) ...[
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: onRefreshKey,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text(
                        'Re-authenticate',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: onToggleImmobilizer,
                      icon: const Icon(Icons.lock_outline_rounded, size: 18),
                      label: const Text(
                        'Arm Immobilizer',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
