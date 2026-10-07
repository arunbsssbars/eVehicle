import 'package:flutter/material.dart';
import '../services/winterization_health_service.dart';

/// Defensive AQIL Card displaying sub-zero fleet winterization and coolant protection.
class WinterizationHealthCard extends StatelessWidget {
  final WinterizationAudit audit;
  final VoidCallback? onScheduleCoolantFlush;

  const WinterizationHealthCard({
    super.key,
    required this.audit,
    this.onScheduleCoolantFlush,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDanger = audit.readinessRating == 'CRITICAL-FREEZE-RISK';
    final isMarginal = audit.readinessRating == 'MARGINAL';
    final statusColor = isDanger
        ? const Color(0xFFDC2626)
        : (isMarginal ? Colors.amber.shade900 : const Color(0xFF10B981));

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
                    Icons.severe_cold,
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
                        'Winterization & Antifreeze',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Protection: ${audit.freezeProtectionTempCelsius}°C • Forecast Low: ${audit.forecastMinAmbientTempCelsius}°C',
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
                    isDanger ? 'FREEZE RISK' : 'PROTECTED',
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

            // Glycol Concentration Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Text(
                        'Glycol Mix: ${audit.glycolConcentrationPercent.toInt()}% (Target: 50%)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 4,
                      child: Text(
                        'Safety Margin: +${audit.safetyMarginCelsius}°C',
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
                    value: (audit.glycolConcentrationPercent / 70.0).clamp(0.0, 1.0),
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
                  label: 'Freeze Point',
                  value: '${audit.freezeProtectionTempCelsius}°C',
                  icon: Icons.ac_unit,
                  color: isDanger ? Colors.red : null,
                ),
                _buildMetricBox(
                  context,
                  label: 'Anti-Gel Fuel',
                  value: audit.isFuelAntiGelRequired ? 'REQUIRED' : 'NO',
                  icon: Icons.local_gas_station_outlined,
                  color: audit.isFuelAntiGelRequired ? Colors.amber.shade900 : null,
                ),
                _buildMetricBox(
                  context,
                  label: 'Block Heater',
                  value: audit.isBlockHeaterRecommended ? 'PLUG IN' : 'OPTIONAL',
                  icon: Icons.power,
                  color: audit.isBlockHeaterRecommended ? Colors.blue : null,
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
                    isDanger ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      audit.advisory,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDanger ? Colors.red.shade900 : theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (onScheduleCoolantFlush != null && isDanger) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.tonalIcon(
                  onPressed: onScheduleCoolantFlush,
                  icon: const Icon(Icons.water_drop_outlined, size: 18),
                  label: const Text(
                    'Book Emergency Coolant Antifreeze Flush',
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
