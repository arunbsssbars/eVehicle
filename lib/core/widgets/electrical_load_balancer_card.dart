import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/electrical_load_balancer_service.dart';

/// Responsive, AQIL-compliant 24V Electrical Load Balancer & Alternator Card.
class ElectricalLoadBalancerCard extends StatelessWidget {
  final ElectricalLoadBalanceResult result;
  final VoidCallback? onShedAuxiliaryLoads;

  const ElectricalLoadBalancerCard({
    super.key,
    required this.result,
    this.onShedAuxiliaryLoads,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String badgeText;
    switch (result.status) {
      case ElectricalBalanceStatus.netPositiveCharging:
        statusColor = AppColors.success;
        badgeText = 'NET POSITIVE';
        break;
      case ElectricalBalanceStatus.neutralLoadBalance:
        statusColor = AppColors.warning;
        badgeText = 'HIGH LOAD';
        break;
      case ElectricalBalanceStatus.netDeficitDischargingCritical:
        statusColor = AppColors.error;
        badgeText = 'DEFICIT DRAIN';
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
                  result.isHealthy ? Icons.battery_charging_full_rounded : Icons.battery_alert_rounded,
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
                      '${result.vehicleId} • 24V Electrical Bus',
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
                      'Demand: ${result.totalDemandAmperes} A • Alternator: ${result.alternatorUtilizationPercent}%',
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
                  label: 'Alternator Load',
                  value: '${result.alternatorUtilizationPercent}%',
                  color: result.alternatorUtilizationPercent >= 90.0 ? AppColors.error : AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetric(
                  label: 'Battery Runway',
                  value: result.isBatteryDepletingUnderLoad ? '${result.estimatedBatteryRunwayMinutes} min' : 'Charging',
                  color: result.isBatteryDepletingUnderLoad ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Recommendation Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: result.isHealthy
                  ? AppColors.surfaceContainerLow
                  : AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              result.powerRecommendation,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: result.isHealthy ? AppColors.onSurface : AppColors.error,
              ),
            ),
          ),

          if (result.isBatteryDepletingUnderLoad && onShedAuxiliaryLoads != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onShedAuxiliaryLoads,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.flash_off_rounded, size: 18),
                label: const Text(
                  'Automated Load Shedding: Non-Essential Loads',
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
