import 'package:flutter/material.dart';
import '../services/fuel_siphon_detector_service.dart';

/// Defensive AQIL Card displaying fuel theft and siphoning anomaly alerts.
class FuelTheftAlertCard extends StatelessWidget {
  final FuelTheftAudit audit;
  final VoidCallback? onFlagTheftIncident;

  const FuelTheftAlertCard({
    super.key,
    required this.audit,
    this.onFlagTheftIncident,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTheft = audit.hasTheftOccurred;
    final isCritical = audit.threatLevel == 'CRITICAL';
    final alertColor = hasTheft
        ? (isCritical ? const Color(0xFFDC2626) : Colors.amber.shade900)
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
                    color: alertColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasTheft ? Icons.local_gas_station_outlined : Icons.shield_outlined,
                    color: alertColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fuel Siphon Anomaly Guard',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        hasTheft
                            ? '${audit.totalLitersLost}L drained • \$${audit.totalFinancialLossUsd} loss'
                            : 'No fuel drop anomalies detected',
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
                    color: alertColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: alertColor, width: 1),
                  ),
                  child: Text(
                    audit.threatLevel,
                    style: TextStyle(
                      color: alertColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Key Metrics Row
            Row(
              children: [
                _buildMetricBox(
                  context,
                  label: 'Suspected Loss',
                  value: '${audit.totalLitersLost} L',
                  icon: Icons.opacity,
                  color: hasTheft ? alertColor : null,
                ),
                _buildMetricBox(
                  context,
                  label: 'Financial Loss',
                  value: '\$${audit.totalFinancialLossUsd}',
                  icon: Icons.attach_money,
                  color: hasTheft ? alertColor : null,
                ),
                _buildMetricBox(
                  context,
                  label: 'Incidents',
                  value: '${audit.incidents.length}',
                  icon: Icons.event_note,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Advisory Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: alertColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: alertColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    hasTheft ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    size: 16,
                    color: alertColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      audit.advisory,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: hasTheft ? Colors.red.shade900 : theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (onFlagTheftIncident != null && hasTheft) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: onFlagTheftIncident,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.report_outlined, size: 18),
                  label: const Text(
                    'File Security & Fuel Siphon Report',
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
}
