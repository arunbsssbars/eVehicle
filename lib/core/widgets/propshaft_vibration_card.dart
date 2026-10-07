import 'package:flutter/material.dart';
import '../services/propshaft_vibration_service.dart';

/// Card showing driveline propshaft vibration velocity, U-joint angle match, and carrier health.
class PropshaftVibrationCard extends StatelessWidget {
  final PropshaftHealthAudit audit;
  final double shaftRpm;
  final VoidCallback? onBookDrivelineService;

  const PropshaftVibrationCard({
    super.key,
    required this.audit,
    required this.shaftRpm,
    this.onBookDrivelineService,
  });

  Color _getStatusColor(DrivelineVibrationSeverity severity) {
    switch (severity) {
      case DrivelineVibrationSeverity.criticalPropshaftFailureRisk:
        return Colors.red.shade700;
      case DrivelineVibrationSeverity.uJointAngleMismatch:
      case DrivelineVibrationSeverity.minorCarrierWear:
        return Colors.orange.shade800;
      case DrivelineVibrationSeverity.smoothBalanced:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(DrivelineVibrationSeverity severity) {
    switch (severity) {
      case DrivelineVibrationSeverity.criticalPropshaftFailureRisk:
        return 'FAILURE RISK';
      case DrivelineVibrationSeverity.uJointAngleMismatch:
        return 'U-JOINT ANGLE';
      case DrivelineVibrationSeverity.minorCarrierWear:
        return 'CARRIER WEAR';
      case DrivelineVibrationSeverity.smoothBalanced:
        return 'BALANCED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(audit.severity);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: audit.immediateInspectionRequired ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: audit.immediateInspectionRequired ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_input_component_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Propshaft & U-Joint Harmonics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getStatusTitle(audit.severity),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    context,
                    'Propshaft RPM',
                    shaftRpm.toStringAsFixed(0),
                    Icons.sync_rounded,
                  ),
                  _buildMetric(
                    context,
                    'RMS Velocity',
                    '${audit.totalVibrationVelocityMmPerSec.toStringAsFixed(1)} mm/s',
                    Icons.vibration_rounded,
                  ),
                  _buildMetric(
                    context,
                    'ISO Class',
                    audit.severity == DrivelineVibrationSeverity.smoothBalanced ? 'Class A' : 'Class C/D',
                    Icons.verified_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              audit.primaryFaultDiagnosis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (audit.immediateInspectionRequired || onBookDrivelineService != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: audit.immediateInspectionRequired ? statusColor : theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onBookDrivelineService,
                  icon: const Icon(Icons.build_rounded, size: 18),
                  label: Text(
                    audit.immediateInspectionRequired ? 'Immediate Driveline Inspection' : 'Schedule Driveline Spin Balance',
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

  Widget _buildMetric(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Flexible(
      child: Column(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
