import 'package:flutter/material.dart';
import '../services/fuel_aero_efficiency_service.dart';

/// Defensive AQIL Card displaying aerodynamic efficiency and cruising speed optimization.
class AeroEfficiencyCard extends StatelessWidget {
  final AeroEfficiencyAudit audit;
  final VoidCallback? onConfigureSpeedGovernor;

  const AeroEfficiencyCard({
    super.key,
    required this.audit,
    this.onConfigureSpeedGovernor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPoor = audit.efficiencyGrade == 'C' || audit.efficiencyGrade == 'D';
    final isModerate = audit.efficiencyGrade == 'B';
    final gradeColor = isPoor
        ? const Color(0xFFDC2626)
        : (isModerate ? Colors.amber.shade900 : const Color(0xFF10B981));

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
                    color: gradeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.air,
                    color: gradeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aerodynamic Efficiency',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Sweet spot: ${audit.optimalSpeedKmph.toInt()} km/h • \$${audit.monthlyCostSavingsUsd}/mo potential savings',
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
                    color: gradeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: gradeColor, width: 1),
                  ),
                  child: Text(
                    'GRADE ${audit.efficiencyGrade}',
                    style: TextStyle(
                      color: gradeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // High Drag Speed Ratio Indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Text(
                        'High-Drag Speed (>90km/h): ${audit.percentageTimeHighDrag}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 4,
                      child: Text(
                        '+${audit.excessFuelBurnL100Km} L/100km',
                        style: TextStyle(fontSize: 11, color: gradeColor, fontWeight: FontWeight.w600),
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
                    value: (audit.percentageTimeHighDrag / 100.0).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
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
                  label: 'Average Speed',
                  value: '${audit.averageSpeedKmph} km/h',
                  icon: Icons.speed,
                ),
                _buildMetricBox(
                  context,
                  label: 'Optimal Target',
                  value: '${audit.optimalSpeedKmph.toInt()} km/h',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF10B981),
                ),
                _buildMetricBox(
                  context,
                  label: 'Monthly Savings',
                  value: '\$${audit.monthlyCostSavingsUsd}',
                  icon: Icons.savings_outlined,
                  color: audit.monthlyCostSavingsUsd > 10.0 ? const Color(0xFF10B981) : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Advisory Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: gradeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    isPoor ? Icons.warning_amber_rounded : Icons.eco_outlined,
                    size: 16,
                    color: gradeColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      audit.aeroAdvisory,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isPoor ? Colors.red.shade900 : theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (onConfigureSpeedGovernor != null && isPoor) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.tonalIcon(
                  onPressed: onConfigureSpeedGovernor,
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text(
                    'Enable Telematics Cruising Governor',
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
