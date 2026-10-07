import 'package:flutter/material.dart';
import '../services/fleet_tco_forecaster_service.dart';

/// Defensive AQIL Card displaying lifetime Total Cost of Ownership (TCO) and residual value.
class FleetTcoForecasterCard extends StatelessWidget {
  final FleetTcoAudit audit;
  final VoidCallback? onInitiateReplacementRfQ;

  const FleetTcoForecasterCard({
    super.key,
    required this.audit,
    this.onInitiateReplacementRfQ,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReplaceNow = audit.lifecyclePhase == 'REPLACE_NOW';
    final isInWindow = audit.isInReplacementWindow;
    final statusColor = isReplaceNow
        ? const Color(0xFFDC2626)
        : (isInWindow ? Colors.amber.shade900 : const Color(0xFF10B981));

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
                    Icons.account_balance_wallet_outlined,
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
                        'Lifetime Asset TCO & Residuals',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'TCO: \$${audit.totalCostOfOwnershipUsd.toInt()} • CPK: \$${audit.costPerKilometerUsd}/km',
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
                    _phaseBadge(audit.lifecyclePhase),
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

            // Cost per km & OpEx Summary
            Row(
              children: [
                _buildMetricBox(
                  context,
                  label: 'Cost / Km (CPK)',
                  value: '\$${audit.costPerKilometerUsd}',
                  icon: Icons.trending_up,
                ),
                _buildMetricBox(
                  context,
                  label: 'Residual Value',
                  value: '\$${audit.estimatedResidualValueUsd.toInt()}',
                  icon: Icons.sell_outlined,
                  color: const Color(0xFF10B981),
                ),
                _buildMetricBox(
                  context,
                  label: 'Cumulative OpEx',
                  value: '\$${audit.cumulativeOpexUsd.toInt()}',
                  icon: Icons.receipt_long,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Strategic Advisory Banner
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
                    isInWindow ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      audit.strategicAdvisory,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isReplaceNow ? Colors.red.shade900 : theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (onInitiateReplacementRfQ != null && isInWindow) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: onInitiateReplacementRfQ,
                  style: FilledButton.styleFrom(
                    backgroundColor: isReplaceNow ? Colors.red.shade700 : theme.colorScheme.primary,
                  ),
                  icon: const Icon(Icons.swap_horizontal_circle_outlined, size: 18),
                  label: const Text(
                    'Initiate Asset Replacement Tender (RfQ)',
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

  String _phaseBadge(String phase) {
    switch (phase) {
      case 'NEW':
        return 'NEW';
      case 'OPTIMAL_SERVICE':
        return 'PRIME ROI';
      case 'REPLACEMENT_WINDOW':
        return 'REPLACE SOON';
      case 'REPLACE_NOW':
        return 'DISPOSE NOW';
      default:
        return 'ACTIVE';
    }
  }
}
