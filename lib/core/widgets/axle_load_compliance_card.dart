import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/axle_load_compliance_service.dart';

/// Responsive, AQIL-compliant Axle Load & Bridge Formula Compliance Sentinel card.
class AxleLoadComplianceCard extends StatelessWidget {
  final AxleWeightAuditResult audit;
  final AxleConfiguration config;
  final VoidCallback? onRecalibratePayload;

  const AxleLoadComplianceCard({
    super.key,
    required this.audit,
    required this.config,
    this.onRecalibratePayload,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = audit.isFullyCompliant ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: audit.isFullyCompliant ? AppColors.borderSubtle : AppColors.error.withValues(alpha: 0.5),
        ),
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
                  Icons.scale_rounded,
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
                      config.registrationNumber,
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
                      'Axle Weight Sentinel • ${config.totalAxleCount}-Axle Chassis (${config.wheelbaseMeters.toStringAsFixed(1)}m Wheelbase)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total Gross Weight vs Bridge Formula Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Measured Gross GVW', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${audit.totalGrossWeightKg.toStringAsFixed(0)} kg',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: audit.isGvwrCompliant ? AppColors.onSurface : AppColors.error,
                        ),
                      ),
                      Text('Max GVWR: ${config.maxGvwrKg.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 9.5, color: AppColors.secondary)),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: AppColors.borderSubtle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Federal Bridge Limit', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${audit.maxAllowedBridgeWeightKg.toStringAsFixed(0)} kg',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: audit.isBridgeFormulaCompliant ? AppColors.primary : AppColors.error,
                        ),
                      ),
                      Text(audit.isFullyCompliant ? 'Zero Overload Citations' : 'Potential Fine: ₹${audit.overloadPenaltyEstimate.toStringAsFixed(0)}', style: TextStyle(fontSize: 9.5, color: audit.isFullyCompliant ? AppColors.success : AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Axle breakdown cards
          ...config.axles.map((axle) {
            final isOver = axle.isOverloaded;
            final pct = axle.legalMaxWeightKg > 0
                ? (axle.measuredWeightKg / axle.legalMaxWeightKg).clamp(0.0, 1.5)
                : 1.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          axle.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                        ),
                      ),
                      Text(
                        '${axle.measuredWeightKg.toStringAsFixed(0)} kg / ${axle.legalMaxWeightKg.toStringAsFixed(0)} kg',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isOver ? AppColors.error : AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: AppColors.borderSubtle,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOver ? AppColors.error : AppColors.primary,
                      ),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            );
          }),

          if (onRecalibratePayload != null && !audit.isFullyCompliant) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onRecalibratePayload,
                icon: const Icon(Icons.reorder_rounded, size: 16),
                label: const Text(
                  'Optimize Axle Payload Distribution',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
