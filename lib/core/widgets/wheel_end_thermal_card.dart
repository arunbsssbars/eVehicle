import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/wheel_end_thermal_service.dart';

/// Responsive, AQIL-compliant Wheel-End Thermal & Bearing Hub Health Monitor Card.
class WheelEndThermalCard extends StatelessWidget {
  final WheelEndThermalResult result;
  final VoidCallback? onInspectHubs;

  const WheelEndThermalCard({
    super.key,
    required this.result,
    this.onInspectHubs,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = result.hasCriticalBearingAlert
        ? AppColors.error
        : (result.anomalies.isNotEmpty ? AppColors.warning : AppColors.success);

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
                  result.hasCriticalBearingAlert
                      ? Icons.warning_amber_rounded
                      : Icons.tire_repair_rounded,
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
                      '${result.vehicleId} • Wheel Hub Health',
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
                      'Max ${result.maxTemperatureCelsius.toStringAsFixed(1)}°C • Min ${result.minPressurePsi.toStringAsFixed(0)} PSI',
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
                  result.isSafe ? 'Normal' : (result.hasCriticalBearingAlert ? 'Critical' : 'Advisory'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Summary status box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: result.hasCriticalBearingAlert
                  ? AppColors.error.withValues(alpha: 0.08)
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              result.summaryStatus,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: result.hasCriticalBearingAlert ? AppColors.error : AppColors.onSurface,
              ),
            ),
          ),

          if (result.anomalies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Wheel End Diagnostic Alerts (${result.anomalies.length}):',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            ...result.anomalies.take(2).map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        a.severity == WheelEndAlertSeverity.critical
                            ? Icons.error_outline_rounded
                            : Icons.info_outline_rounded,
                        size: 16,
                        color: a.severity == WheelEndAlertSeverity.critical
                            ? AppColors.error
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${a.title}: ${a.currentTemp.toStringAsFixed(1)}°C / ${a.currentPressure.toStringAsFixed(0)} PSI',
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

          if (onInspectHubs != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: onInspectHubs,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: statusColor),
                  foregroundColor: statusColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.build_circle_outlined, size: 18),
                label: const Text(
                  'Perform Hub Inspection',
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
}
