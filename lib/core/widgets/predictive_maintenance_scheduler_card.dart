import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/predictive_maintenance_scheduler_service.dart';

/// Responsive, AQIL-compliant Predictive Maintenance Forecast card.
class PredictiveMaintenanceSchedulerCard extends StatelessWidget {
  final MaintenanceScheduleForecast forecast;
  final String registrationNumber;
  final VoidCallback? onBookServiceSlot;

  const PredictiveMaintenanceSchedulerCard({
    super.key,
    required this.forecast,
    required this.registrationNumber,
    this.onBookServiceSlot,
  });

  @override
  Widget build(BuildContext context) {
    final urgentColor = forecast.isImmediateServiceRequired ? AppColors.error : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: forecast.isImmediateServiceRequired
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.borderSubtle,
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
                  color: urgentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.build_circle_rounded,
                  color: urgentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registrationNumber,
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
                      'Predictive Maintenance • Health: ${forecast.overallVehicleHealthScore.toStringAsFixed(0)}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: forecast.isImmediateServiceRequired ? AppColors.error : AppColors.secondary,
                        fontWeight: forecast.isImmediateServiceRequired ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Forecast Countdown Banner
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
                      const Text('Service Horizon', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${forecast.daysUntilNextService} Days Left',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: forecast.daysUntilNextService < 10 ? AppColors.error : AppColors.primary,
                        ),
                      ),
                      Text('Est: ${forecast.estimatedNextServiceDate.day}/${forecast.estimatedNextServiceDate.month}/${forecast.estimatedNextServiceDate.year}', style: const TextStyle(fontSize: 9.5, color: AppColors.secondary)),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: AppColors.borderSubtle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estimated Cost', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      const SizedBox(height: 2),
                      Text(
                        '₹${forecast.totalEstimatedServiceCost.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(forecast.isImmediateServiceRequired ? 'Immediate Service Due' : 'Preventive Routine', style: TextStyle(fontSize: 9.5, color: forecast.isImmediateServiceRequired ? AppColors.error : AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Component wear degradation progress list
          ...forecast.componentStatuses.take(4).map((c) {
            final isCritical = c.isReplacementUrgent;
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
                          c.componentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                        ),
                      ),
                      Text(
                        '${c.remainingHealthPercent.toStringAsFixed(0)}% • ${c.remainingSafeKm} km',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isCritical ? AppColors.error : AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: c.remainingHealthPercent / 100.0,
                      backgroundColor: AppColors.borderSubtle,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        c.remainingHealthPercent < 20 ? AppColors.error : AppColors.primary,
                      ),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            );
          }),

          if (onBookServiceSlot != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onBookServiceSlot,
                icon: const Icon(Icons.calendar_month_rounded, size: 16),
                label: const Text(
                  'Book Preventive Workshop Service',
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
