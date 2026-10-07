import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/hazmat_segregation_auditor_service.dart';

/// Responsive, AQIL-compliant Dangerous Goods Co-Loading Segregation Card.
class HazmatSegregationAuditorCard extends StatelessWidget {
  final HazmatSegregationAuditResult result;
  final VoidCallback? onSeparateShipments;

  const HazmatSegregationAuditorCard({
    super.key,
    required this.result,
    this.onSeparateShipments,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = result.isSafe ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  result.isSafe ? Icons.check_circle_rounded : Icons.warning_rounded,
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
                      '${result.vehicleOrTrailerId} • DG Segregation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hazmat: ${result.totalHazmatWeightKg} kg • Placards: ${result.isPlacardingMandatory ? "REQUIRED" : "EXEMPT"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.isSafe ? 'COMPLIANT' : 'PROHIBITED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2 Metric Gauge Row
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  label: 'Co-Load Status',
                  value: result.isCoLoadingPermitted ? 'Permitted' : 'Violations Found',
                  color: result.isCoLoadingPermitted ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetric(
                  label: 'Incompatibilities',
                  value: '${result.segregationConflicts.length} Conflicts',
                  color: result.segregationConflicts.isEmpty ? AppColors.primary : AppColors.error,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Summary Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: result.isSafe
                  ? AppColors.surfaceContainerLow
                  : AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              result.segregationSummary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: result.isSafe ? AppColors.onSurface : AppColors.error,
              ),
            ),
          ),

          if (result.segregationConflicts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Conflicting UN Pairings (${result.segregationConflicts.length}):',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            ...result.segregationConflicts.take(2).map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${c.unNumberA} ❌ ${c.unNumberB}: ${c.reason}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          if (!result.isSafe && onSeparateShipments != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onSeparateShipments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.call_split_rounded, size: 18),
                label: const Text(
                  'Segregate onto Separate Vehicle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
