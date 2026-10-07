import 'package:flutter/material.dart';
import '../services/noise_ergonomics_service.dart';

/// Defensive AQIL Card displaying cabin acoustic noise levels and OSHA dose compliance.
class CabinNoiseCard extends StatelessWidget {
  final NoiseExposureAudit audit;
  final VoidCallback? onScheduleAcousticCheck;

  const CabinNoiseCard({
    super.key,
    required this.audit,
    this.onScheduleAcousticCheck,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHazard = audit.acousticRating == 'HAZARDOUS';
    final isElevated = audit.acousticRating == 'ELEVATED';
    final statusColor = isHazard
        ? const Color(0xFFDC2626)
        : (isElevated ? Colors.amber.shade900 : const Color(0xFF10B981));

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
                    Icons.volume_up_outlined,
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
                        'Cabin Noise Ergonomics',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Avg: ${audit.averageDecibelsDba} dB(A) • Peak: ${audit.peakDecibelsDba} dB(A)',
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
                    audit.acousticRating,
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

            // OSHA Noise Dose Meter
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Text(
                        'OSHA Dose Exposure: ${audit.oshaDosePercentage}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 4,
                      child: Text(
                        'TWA: ${audit.twa8HourDba} dB(A)',
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
                    value: (audit.oshaDosePercentage / 100.0).clamp(0.0, 1.0),
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
                  label: 'Average Leq',
                  value: '${audit.averageDecibelsDba} dB',
                  icon: Icons.equalizer,
                ),
                _buildMetricBox(
                  context,
                  label: 'Peak Sound',
                  value: '${audit.peakDecibelsDba} dB',
                  icon: Icons.graphic_eq,
                  color: audit.peakDecibelsDba >= 90.0 ? Colors.red : null,
                ),
                _buildMetricBox(
                  context,
                  label: 'Action Level',
                  value: '85 dB Limit',
                  icon: Icons.health_and_safety_outlined,
                  color: audit.isExceedingSafetyThreshold ? Colors.red : null,
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
                    isHazard ? Icons.hearing_disabled : Icons.check_circle_outline,
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
                        color: isHazard ? Colors.red.shade900 : theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (onScheduleAcousticCheck != null && (isHazard || isElevated)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.tonalIcon(
                  onPressed: onScheduleAcousticCheck,
                  icon: const Icon(Icons.build_circle_outlined, size: 18),
                  label: const Text(
                    'Book Exhaust & Acoustic Vibration Inspection',
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
