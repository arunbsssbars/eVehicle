import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/ultrasonic_fuel_theft_guard_service.dart';

/// Responsive, AQIL-compliant Ultrasonic Fuel Theft & Siphon Guard Card.
class UltrasonicFuelTheftGuardCard extends StatelessWidget {
  final FuelSiphonTheftResult result;
  final VoidCallback? onDispatchSecurityAlert;

  const UltrasonicFuelTheftGuardCard({
    super.key,
    required this.result,
    this.onDispatchSecurityAlert,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String badgeText;
    switch (result.classification) {
      case FuelEventClassification.normalConsumption:
      case FuelEventClassification.sloshTransient:
        statusColor = AppColors.success;
        badgeText = 'SECURE';
        break;
      case FuelEventClassification.legitimateRefueling:
        statusColor = AppColors.primary;
        badgeText = 'REFUELED';
        break;
      case FuelEventClassification.illicitSiphonTheft:
        statusColor = AppColors.error;
        badgeText = 'THEFT ALARM';
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
                  result.isTheftAlarmTriggered
                      ? Icons.warning_amber_rounded
                      : Icons.local_gas_station_rounded,
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
                      '${result.vehicleId} • Fuel Siphon Guard',
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
                      'Volume: ${result.currentVolumeLitres} L • Delta: ${result.volumeDeltaLitres} L',
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
                  label: 'Current Fuel Level',
                  value: '${result.currentVolumeLitres} L',
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetric(
                  label: 'Volume Variance',
                  value: '${result.volumeDeltaLitres > 0 ? "+" : ""}${result.volumeDeltaLitres} L',
                  color: result.volumeDeltaLitres < -15.0 ? AppColors.error : AppColors.primary,
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
              color: result.isTheftAlarmTriggered
                  ? AppColors.error.withValues(alpha: 0.08)
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              result.alarmSummary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: result.isTheftAlarmTriggered ? AppColors.error : AppColors.onSurface,
              ),
            ),
          ),

          if (result.isTheftAlarmTriggered && onDispatchSecurityAlert != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onDispatchSecurityAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.security_rounded, size: 18),
                label: const Text(
                  'Dispatch Immediate Security Response',
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
