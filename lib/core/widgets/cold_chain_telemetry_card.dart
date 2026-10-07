import 'package:flutter/material.dart';
import '../services/cold_chain_monitor_service.dart';
import '../theme/app_colors.dart';

/// Cold chain monitoring and telemetry summary card for Loop 21.
class ColdChainTelemetryCard extends StatelessWidget {
  final ColdChainAuditResult audit;
  final VoidCallback? onExportLog;

  const ColdChainTelemetryCard({
    super.key,
    required this.audit,
    this.onExportLog,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = audit.isCompliant ? AppColors.success : AppColors.error;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.kitchen_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Cold Chain Integrity',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    audit.isCompliant ? 'PASS' : 'BREACH',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Avg Temperature',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: AppColors.secondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${audit.averageTemperature.toStringAsFixed(1)}°C',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${audit.minTemperature}°C – ${audit.maxTemperature}°C',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Excursions',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: AppColors.secondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${audit.totalExcursionMinutes} min',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: audit.totalExcursionMinutes > 0 ? AppColors.error : AppColors.onSurface,
                        ),
                      ),
                      Text(
                        '${audit.doorOpenEventCount} door events',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onExportLog != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onExportLog,
                  child: const Text('Export Reefer Log'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
