import 'package:flutter/material.dart';
import '../services/hazmat_compliance_service.dart';

/// Defensive AQIL Card displaying HAZMAT placarding and tunnel restriction compliance.
class HazmatComplianceCard extends StatelessWidget {
  final HazmatRouteAudit audit;
  final VoidCallback? onViewErgGuide;

  const HazmatComplianceCard({
    super.key,
    required this.audit,
    this.onViewErgGuide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHazmat = audit.consignments.isNotEmpty;
    final statusColor = hasHazmat
        ? (audit.hasExplosivesOrToxics ? const Color(0xFFDC2626) : Colors.orange.shade900)
        : const Color(0xFF10B981);

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
                    hasHazmat ? Icons.warning_rounded : Icons.check_circle_outline,
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
                        'HAZMAT & Tunnel Guard',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        hasHazmat
                            ? '${audit.totalHazmatWeightKg.toInt()} kg dangerous goods • ${audit.consignments.length} consignments'
                            : 'General non-hazardous freight',
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
                    hasHazmat ? 'HAZMAT' : 'STANDARD',
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

            // Mandatory Placards Row
            if (hasHazmat) ...[
              Text(
                'Mandatory Placard Requirements',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: audit.requiredPlacards.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.orange.shade800, width: 1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '⚠️ $p',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Metrics Grid
            Row(
              children: [
                _buildMetricBox(
                  context,
                  label: 'Tunnel Limit',
                  value: _tunnelCode(audit.strictestTunnelAllowed),
                  icon: Icons.alt_route,
                  color: hasHazmat ? statusColor : null,
                ),
                _buildMetricBox(
                  context,
                  label: 'Total Mass',
                  value: '${audit.totalHazmatWeightKg.toInt()} kg',
                  icon: Icons.scale,
                ),
                _buildMetricBox(
                  context,
                  label: 'Hazmat Items',
                  value: '${audit.consignments.length}',
                  icon: Icons.inventory_2_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Emergency Guide Notice
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    hasHazmat ? Icons.shield : Icons.check_circle,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      audit.emergencyResponseGuideSummary,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: hasHazmat ? Colors.red.shade900 : theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (onViewErgGuide != null && hasHazmat) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.tonalIcon(
                  onPressed: onViewErgGuide,
                  icon: const Icon(Icons.menu_book, size: 18),
                  label: const Text(
                    'Open DOT Emergency Response Guidebook',
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

  String _tunnelCode(TunnelCategory c) {
    switch (c) {
      case TunnelCategory.categoryA:
        return 'CAT A';
      case TunnelCategory.categoryB:
        return 'CAT B BAN';
      case TunnelCategory.categoryC:
        return 'CAT C BAN';
      case TunnelCategory.categoryD:
        return 'CAT D BAN';
      case TunnelCategory.categoryE:
        return 'ALL TUNNELS';
    }
  }
}
