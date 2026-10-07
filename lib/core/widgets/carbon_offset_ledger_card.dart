import 'package:flutter/material.dart';
import '../services/carbon_offset_ledger_service.dart';

/// Defensive AQIL Card displaying Scope 1 fleet emissions and ESG carbon offset ledger.
class CarbonOffsetLedgerCard extends StatelessWidget {
  final EsgCarbonLedgerAudit audit;
  final VoidCallback? onDownloadEsgCertificate;

  const CarbonOffsetLedgerCard({
    super.key,
    required this.audit,
    this.onDownloadEsgCertificate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNeutral = audit.isCarbonNeutralCertified;
    final statusColor = isNeutral ? const Color(0xFF10B981) : Colors.amber.shade900;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isNeutral ? Icons.eco : Icons.park_outlined,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESG Scope 1 Carbon Ledger',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${audit.grossEmissionsTonsCo2} tCO₂e gross • ${audit.offsetCoveragePercentage}% offset',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    isNeutral ? 'NET-ZERO' : 'PARTIAL',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Carbon Coverage Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Text(
                        'Offset Retirement: ${audit.totalOffsetTonsCo2} / ${audit.grossEmissionsTonsCo2} tCO₂',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 4,
                      child: Text(
                        'Net: ${audit.netEmissionsTonsCo2} tCO₂e',
                        style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (audit.offsetCoveragePercentage / 100.0).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Metrics Grid
            Row(
              children: [
                _buildMetricBox(
                  context,
                  label: 'Gross Footprint',
                  value: '${audit.grossEmissionsTonsCo2} t',
                  icon: Icons.cloud_queue,
                ),
                _buildMetricBox(
                  context,
                  label: 'Sequestered',
                  value: '${audit.totalOffsetTonsCo2} t',
                  icon: Icons.forest,
                  color: statusColor,
                ),
                _buildMetricBox(
                  context,
                  label: 'Offset Spend',
                  value: '\$${audit.totalOffsetExpenditureUsd.toInt()}',
                  icon: Icons.verified_user_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Hash Badge Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fingerprint, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Registry Hash: ${audit.certificateHash} • Verified under ISO 14064',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (onDownloadEsgCertificate != null)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: onDownloadEsgCertificate,
                  icon: const Icon(Icons.download_done, size: 18),
                  label: const Text(
                    'Export Corporate ESG Offset Certificate',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color ?? theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
