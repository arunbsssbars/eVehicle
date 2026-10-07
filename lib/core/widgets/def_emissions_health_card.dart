import 'package:flutter/material.dart';
import '../services/def_emissions_health_service.dart';

/// Card presenting AdBlue / DEF level, SCR conversion efficiency, and derate risk.
class DefEmissionsHealthCard extends StatelessWidget {
  final DefComplianceAudit audit;
  final VoidCallback? onLogDefRefill;

  const DefEmissionsHealthCard({
    super.key,
    required this.audit,
    this.onLogDefRefill,
  });

  Color _getStatusColor(DefSystemStatus status) {
    switch (status) {
      case DefSystemStatus.inducementDerated:
      case DefSystemStatus.criticalDepleted:
        return Colors.red.shade700;
      case DefSystemStatus.qualityMalfunction:
      case DefSystemStatus.lowRefillRequired:
        return Colors.orange.shade800;
      case DefSystemStatus.optimal:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(DefSystemStatus status) {
    switch (status) {
      case DefSystemStatus.inducementDerated:
        return 'ENGINE DERATED';
      case DefSystemStatus.criticalDepleted:
        return 'CRITICAL LOW';
      case DefSystemStatus.qualityMalfunction:
        return 'QUALITY ERROR';
      case DefSystemStatus.lowRefillRequired:
        return 'REFILL SOON';
      case DefSystemStatus.optimal:
        return 'OPTIMAL';
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
          color: audit.requiresImmediateAction ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: audit.requiresImmediateAction ? 1.5 : 1.0,
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
                  Icons.water_drop_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AdBlue / DEF SCR Health',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (audit.heaterActive) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.ac_unit_rounded, size: 12, color: Colors.blue.shade700),
                        const SizedBox(width: 2),
                        Text(
                          'HEATER',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.blue.shade700,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    'Remaining Fluid',
                    '${audit.remainingDefLiters.toStringAsFixed(1)} L',
                    Icons.local_gas_station_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Range Remaining',
                    '${audit.estimatedRemainingKm.toStringAsFixed(0)} km',
                    Icons.route_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Derate In',
                    audit.inducementCountdownKm == 0
                        ? 'ACTIVE'
                        : '${audit.inducementCountdownKm} km',
                    Icons.timer_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              audit.complianceMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (audit.requiresImmediateAction || onLogDefRefill != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: audit.requiresImmediateAction ? statusColor : theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onLogDefRefill,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text(
                    'Log DEF / AdBlue Refill',
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
