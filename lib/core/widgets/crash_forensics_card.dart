import 'package:flutter/material.dart';
import '../services/crash_reconstruction_service.dart';

/// Defensive AQIL Card displaying accident impact forensics and emergency dispatch alerts.
class CrashForensicsCard extends StatelessWidget {
  final CrashReconstructionReport report;
  final VoidCallback? onTriggerEmergencyDispatch;

  const CrashForensicsCard({
    super.key,
    required this.report,
    this.onTriggerEmergencyDispatch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCrash = report.hasCrashOccurred;
    final alertColor = isCrash
        ? (report.emergencyDispatchRecommended ? const Color(0xFFDC2626) : Colors.orange)
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
                    isCrash ? Icons.car_crash_outlined : Icons.verified_user_outlined,
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
                        'Impact Forensics',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isCrash
                            ? 'Peak: ${report.peakGForce}G • Delta-V: ${report.deltaVKmph} km/h'
                            : 'No high-g collision anomalies detected',
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
                    _severityLabel(report.severity),
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
                  label: 'Peak G-Force',
                  value: '${report.peakGForce}G',
                  icon: Icons.speed,
                  color: report.peakGForce >= 3.0 ? alertColor : null,
                ),
                _buildMetricBox(
                  context,
                  label: 'Delta-V',
                  value: '${report.deltaVKmph} km/h',
                  icon: Icons.compress,
                ),
                _buildMetricBox(
                  context,
                  label: 'Rollover',
                  value: report.isRollover ? 'YES' : 'NO',
                  icon: Icons.screen_rotation,
                  color: report.isRollover ? const Color(0xFFDC2626) : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Emergency Banner / Dispatch
            if (report.emergencyDispatchRecommended) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade700, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emergency_outlined, color: Colors.red, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'HIGH IMPACT EVENT: Automatic emergency dispatch alert triggered.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (onTriggerEmergencyDispatch != null)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: onTriggerEmergencyDispatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text(
                      'Dispatch SOS & Fleet Safety Escort',
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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

  String _severityLabel(CrashSeverity s) {
    switch (s) {
      case CrashSeverity.none:
        return 'NORMAL';
      case CrashSeverity.minorFenderBender:
        return 'MINOR';
      case CrashSeverity.moderateCollision:
        return 'MODERATE';
      case CrashSeverity.severeImpact:
        return 'CRITICAL';
      case CrashSeverity.rollover:
        return 'ROLLOVER';
    }
  }
}
