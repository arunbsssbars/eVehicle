import 'package:flutter/material.dart';
import '../services/tyre_brake_health_service.dart';

/// Defensive AQIL Card displaying tyre tread depth and brake wear health.
class TyreBrakeHealthCard extends StatelessWidget {
  final ComponentHealthAudit health;
  final VoidCallback? onScheduleService;

  const TyreBrakeHealthCard({
    super.key,
    required this.health,
    this.onScheduleService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSafe = health.isRoadworthy;
    final statusColor = isSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444);

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
                    Icons.tire_repair,
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
                        'Tyre & Brake Telemetry',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Min Tread: ${health.minTreadDepthMm}mm • Pad Wear: ${health.maxBrakeWearPercent}%',
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
                    isSafe ? 'ROADWORTHY' : 'GROUNDED',
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

            // Per-Axle Grid (Front vs Rear)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildAxleRow(
                    context,
                    axleTitle: 'Front Axle',
                    leftTyre: health.tyres[AxlePosition.frontLeft]!,
                    rightTyre: health.tyres[AxlePosition.frontRight]!,
                  ),
                  const Divider(height: 14, thickness: 0.7),
                  _buildAxleRow(
                    context,
                    axleTitle: 'Rear Axle',
                    leftTyre: health.tyres[AxlePosition.rearLeft]!,
                    rightTyre: health.tyres[AxlePosition.rearRight]!,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Advisory Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSafe ? Colors.blue.withValues(alpha: 0.08) : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSafe ? Colors.blue.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSafe ? Icons.info_outline : Icons.warning_amber_rounded,
                    size: 16,
                    color: isSafe ? Colors.blue : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      health.safetyAdvisory,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSafe ? theme.textTheme.bodyMedium?.color : Colors.red.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (onScheduleService != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.tonalIcon(
                  onPressed: onScheduleService,
                  icon: const Icon(Icons.build_circle_outlined, size: 18),
                  label: const Text(
                    'Book Tyre / Brake Inspection',
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

  Widget _buildAxleRow(
    BuildContext context, {
    required String axleTitle,
    required TyreCondition leftTyre,
    required TyreCondition rightTyre,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            axleTitle,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Text(
            'L: ${leftTyre.treadDepthMm}mm (${leftTyre.currentPsi.toInt()} PSI)',
            style: const TextStyle(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Text(
            'R: ${rightTyre.treadDepthMm}mm (${rightTyre.currentPsi.toInt()} PSI)',
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
