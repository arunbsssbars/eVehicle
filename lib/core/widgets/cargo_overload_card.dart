import 'package:flutter/material.dart';
import '../services/cargo_manifest_service.dart';

/// Defensive AQIL Card displaying cargo manifest payload and axle overload compliance.
class CargoOverloadCard extends StatelessWidget {
  final WeightComplianceAudit audit;
  final VoidCallback? onViewManifest;

  const CargoOverloadCard({
    super.key,
    required this.audit,
    this.onViewManifest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverloaded = audit.status == WeightComplianceStatus.overloaded;
    final isNearCap = audit.status == WeightComplianceStatus.nearCapacity;
    final statusColor = isOverloaded
        ? const Color(0xFFDC2626)
        : (isNearCap ? Colors.orange.shade800 : const Color(0xFF10B981));

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
                    Icons.inventory_2_outlined,
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
                        'Cargo Manifest & Weight',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'GVW: ${audit.grossVehicleWeightKg.toInt()} kg / ${audit.gvwrLimitKg.toInt()} kg limit',
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
                    _statusLabel(audit.status),
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

            // Payload Utilization Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Payload: ${audit.totalCargoWeightKg.toInt()} kg (${audit.utilizationPercentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (audit.hazardousItemCount > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '⚠️ ${audit.hazardousItemCount} Hazmat Units',
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (audit.utilizationPercentage / 100.0).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Axle Distribution Grid
            Row(
              children: [
                _buildMetricBox(
                  context,
                  label: 'Front Steering Axle',
                  value: '${audit.frontAxleWeightKg.toInt()} kg',
                  icon: Icons.front_hand,
                ),
                _buildMetricBox(
                  context,
                  label: 'Rear Drive Axle',
                  value: '${audit.rearAxleWeightKg.toInt()} kg',
                  icon: Icons.airport_shuttle,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Overweight Warning / Fine Notice
            if (isOverloaded) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade700, width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.report_problem, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OVERLOAD RISK: Est. regulatory fine \$${audit.finePenaltyUsd.toStringAsFixed(2)}. Offload cargo before departure.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
            ],

            if (onViewManifest != null)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: onViewManifest,
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: const Text(
                    'Inspect Bill of Lading & Manifest',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
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
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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

  String _statusLabel(WeightComplianceStatus s) {
    switch (s) {
      case WeightComplianceStatus.legal:
        return 'COMPLIANT';
      case WeightComplianceStatus.nearCapacity:
        return 'NEAR CAP';
      case WeightComplianceStatus.overloaded:
        return 'OVERWEIGHT';
    }
  }
}
