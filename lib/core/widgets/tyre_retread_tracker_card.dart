import 'package:flutter/material.dart';
import '../services/tyre_retread_tracker_service.dart';

/// Card displaying commercial tyre retread count, casing integrity %, and axle compliance.
class TyreRetreadTrackerCard extends StatelessWidget {
  final TyreRetreadAudit audit;
  final String casingSerial;
  final int retreadCount;
  final VoidCallback? onLogShearographyScan;

  const TyreRetreadTrackerCard({
    super.key,
    required this.audit,
    required this.casingSerial,
    required this.retreadCount,
    this.onLogShearographyScan,
  });

  Color _getStatusColor(CasingIntegrityStatus status) {
    switch (status) {
      case CasingIntegrityStatus.steerAxleViolation:
      case CasingIntegrityStatus.condemnedScrap:
        return Colors.red.shade700;
      case CasingIntegrityStatus.casingFatigueWarning:
        return Colors.orange.shade800;
      case CasingIntegrityStatus.certifiedSound:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(CasingIntegrityStatus status) {
    switch (status) {
      case CasingIntegrityStatus.steerAxleViolation:
        return 'ILLEGAL AXLE';
      case CasingIntegrityStatus.condemnedScrap:
        return 'SCRAP CONDEMNED';
      case CasingIntegrityStatus.casingFatigueWarning:
        return 'FATIGUE';
      case CasingIntegrityStatus.certifiedSound:
        return 'CERTIFIED';
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
          color: audit.requiresImmediateReplacement ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: audit.requiresImmediateReplacement ? 1.5 : 1.0,
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
                  Icons.album_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tyre Casing & Retread Tracker',
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
                    'Retread Stage',
                    retreadCount == 0 ? 'Virgin' : 'R-$retreadCount',
                    Icons.history_toggle_off_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Remaining',
                    '${audit.remainingRetreadCycles} cycles',
                    Icons.autorenew_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Casing ID',
                    casingSerial.length > 8 ? casingSerial.substring(0, 8) : casingSerial,
                    Icons.tag_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              audit.complianceSummary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (audit.requiresImmediateReplacement || onLogShearographyScan != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: audit.requiresImmediateReplacement ? statusColor : theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onLogShearographyScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: Text(
                    audit.requiresImmediateReplacement ? 'Order Mandatory Casing Replacement' : 'Log Shearography Casing Scan',
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
