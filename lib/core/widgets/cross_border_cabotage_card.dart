import 'package:flutter/material.dart';
import '../services/cross_border_compliance_service.dart';

/// Defensive AQIL Card displaying cross-border international cabotage quotas and customs seals.
class CrossBorderCabotageCard extends StatelessWidget {
  final CabotageAuditResult audit;
  final VoidCallback? onVerifyCustomsSeal;

  const CrossBorderCabotageCard({
    super.key,
    required this.audit,
    this.onVerifyCustomsSeal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLegal = audit.isLegallyCompliant;
    final statusColor = isLegal ? const Color(0xFF10B981) : const Color(0xFFDC2626);

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
                    isLegal ? Icons.flag_outlined : Icons.report_problem_outlined,
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
                        'Cabotage & Customs Guard',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Host: ${audit.hostCountry} • ${audit.completedOperationsCount} of ${audit.maxAllowedOperations} operations used',
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
                    isLegal ? 'PERMITTED' : 'PROHIBITED',
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

            // Operations Quota Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Text(
                        'Quota: ${audit.completedOperationsCount} / ${audit.maxAllowedOperations} trips completed',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 4,
                      child: Text(
                        '${audit.remainingAllowedOperations} remaining',
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
                    value: (audit.completedOperationsCount / audit.maxAllowedOperations).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      audit.completedOperationsCount >= audit.maxAllowedOperations
                          ? Colors.red
                          : (audit.completedOperationsCount >= 2 ? Colors.amber.shade900 : const Color(0xFF10B981)),
                    ),
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
                  label: 'Customs Seal',
                  value: audit.isCustomsSealVerified ? 'VERIFIED' : 'TAMPERED',
                  icon: Icons.lock_outline,
                  color: audit.isCustomsSealVerified ? const Color(0xFF10B981) : Colors.red,
                ),
                _buildMetricBox(
                  context,
                  label: '7-Day Window',
                  value: audit.isWithin7DayWindow ? 'ACTIVE' : 'EXPIRED',
                  icon: Icons.calendar_today,
                  color: audit.isWithin7DayWindow ? null : Colors.red,
                ),
                _buildMetricBox(
                  context,
                  label: 'Cooling-Off',
                  value: audit.isCoolingOffPeriodActive ? 'MANDATORY' : 'NONE',
                  icon: Icons.pause_circle_outline,
                  color: audit.isCoolingOffPeriodActive ? Colors.amber.shade900 : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Advisory Banner
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
                    isLegal ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      audit.complianceAdvisory,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isLegal ? theme.textTheme.bodyMedium?.color : Colors.red.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (onVerifyCustomsSeal != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: onVerifyCustomsSeal,
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text(
                    'Scan & Authenticate Customs Cargo Seal',
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
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
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
