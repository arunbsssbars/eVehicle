import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/turbo_boost_diagnoser_service.dart';

/// Responsive, AQIL-compliant Turbocharger Boost Pressure & Intake Restriction Card.
class TurboBoostDiagnoserCard extends StatelessWidget {
  final TurboBoostAuditResult result;
  final VoidCallback? onPerformSmokeTest;

  const TurboBoostDiagnoserCard({
    super.key,
    required this.result,
    this.onPerformSmokeTest,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String badgeText;
    switch (result.status) {
      case IntakeHealthStatus.normal:
        statusColor = AppColors.success;
        badgeText = 'OPTIMAL BOOST';
        break;
      case IntakeHealthStatus.airFilterRestrictionWarning:
        statusColor = AppColors.warning;
        badgeText = 'FILTER CLOGGED';
        break;
      case IntakeHealthStatus.boostLeakOrUnderboostCritical:
        statusColor = AppColors.error;
        badgeText = 'UNDERBOOST LEAK';
        break;
    }

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
                  result.isSafe ? Icons.speed_rounded : Icons.warning_amber_rounded,
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
                      '${result.vehicleId} • Turbocharger Boost',
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
                      'Boost: ${result.gaugeBoostBar} Bar • Filter Drop: ${result.filterRestrictionMbar} mbar',
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
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
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
                  label: 'Manifold Boost',
                  value: '${result.gaugeBoostBar} Bar',
                  color: result.gaugeBoostBar < 1.0 ? AppColors.error : AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetric(
                  label: 'Volumetric Eff.',
                  value: '${result.volumetricEfficiencyPercent}%',
                  color: result.volumetricEfficiencyPercent < 80.0 ? AppColors.warning : AppColors.success,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Diagnostic Advice Box
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
              result.diagnosticAdvice,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: result.isSafe ? AppColors.onSurface : AppColors.error,
              ),
            ),
          ),

          if (!result.isSafe && onPerformSmokeTest != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onPerformSmokeTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.build_circle_rounded, size: 18),
                label: const Text(
                  'Perform Charge-Air Smoke Pressure Test',
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
