import 'package:flutter/material.dart';
import '../services/cng_cryogenic_service.dart';

/// Card showing CNG/LNG cylinder pressure, boil-off venting risk, and methane detection.
class CngCryogenicCard extends StatelessWidget {
  final GasSystemSafetyAudit audit;
  final double currentPressureBar;
  final VoidCallback? onEmergencyVentAction;

  const CngCryogenicCard({
    super.key,
    required this.audit,
    required this.currentPressureBar,
    this.onEmergencyVentAction,
  });

  Color _getStatusColor(CngSystemStatus status) {
    switch (status) {
      case CngSystemStatus.methaneLeakAlarm:
      case CngSystemStatus.ventingPressureWarning:
        return Colors.red.shade700;
      case CngSystemStatus.recertificationExpired:
        return Colors.orange.shade800;
      case CngSystemStatus.normalOperational:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(CngSystemStatus status) {
    switch (status) {
      case CngSystemStatus.methaneLeakAlarm:
        return 'GAS LEAK ALARM';
      case CngSystemStatus.ventingPressureWarning:
        return 'VENTING RISK';
      case CngSystemStatus.recertificationExpired:
        return 'CERT EXPIRED';
      case CngSystemStatus.normalOperational:
        return 'PRESSURE OK';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(audit.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: audit.requiresEmergencyVentOrShutoff ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: audit.requiresEmergencyVentOrShutoff ? 1.5 : 1.0,
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
                  Icons.propane_tank_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'CNG/LNG Pressure & BOG Guard',
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
                    _getStatusTitle(audit.status),
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
                    'Pressure',
                    '${currentPressureBar.toStringAsFixed(0)} bar',
                    Icons.speed_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Vessel Capacity',
                    '${audit.pressureFillPercent.toStringAsFixed(0)}%',
                    Icons.pie_chart_outline_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Hydro Test',
                    audit.daysUntilCertExpiry <= 0
                        ? 'EXPIRED'
                        : '${audit.daysUntilCertExpiry}d',
                    Icons.verified_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              audit.statusSummary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (audit.requiresEmergencyVentOrShutoff && onEmergencyVentAction != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: statusColor,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onEmergencyVentAction,
                  icon: const Icon(Icons.warning_rounded, size: 18),
                  label: const Text(
                    'Trigger Emergency Solenoid Valve Shutoff',
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
