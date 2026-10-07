import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/battery_pyrofuse_venting_service.dart';

/// Responsive, AQIL-compliant EV Battery Thermal Runaway Venting & Pyrofuse Sentry Card.
class BatteryPyrofuseVentingCard extends StatelessWidget {
  final BatteryThermalRunawayResult result;
  final VoidCallback? onTriggerEmergencyDisconnect;

  const BatteryPyrofuseVentingCard({
    super.key,
    required this.result,
    this.onTriggerEmergencyDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String badgeText;
    switch (result.status) {
      case PyrofuseVentingStatus.sealedAndIntact:
        statusColor = AppColors.success;
        badgeText = 'SEALED & SAFE';
        break;
      case PyrofuseVentingStatus.pressureWarningVentingInitiated:
        statusColor = AppColors.warning;
        badgeText = 'VENTING WARNING';
        break;
      case PyrofuseVentingStatus.emergencyPyrofuseDetonated:
        statusColor = AppColors.error;
        badgeText = 'PYROFUSE DETONATED';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.isEvacuationMandatory ? AppColors.error : AppColors.borderSubtle,
          width: result.isEvacuationMandatory ? 1.5 : 1.0,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  result.isSafeToOperate ? Icons.battery_charging_full_rounded : Icons.local_fire_department_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EV Battery Thermal Runaway Sentry',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${result.vehicleId} • Pyrofuse & Vent Port Sentinel',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Metric Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Pack Pressure',
                  value: '${result.enclosurePressureKPa.toStringAsFixed(1)} kPa',
                  isWarning: result.enclosurePressureKPa >= 118.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'H2 Gas Level',
                  value: '${result.hydrogenPpm.toStringAsFixed(0)} ppm',
                  isWarning: result.hydrogenPpm > 350.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Peak Cell Temp',
                  value: '${result.maxCellTempCelsius.toStringAsFixed(1)} °C',
                  isWarning: result.maxCellTempCelsius >= 55.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // High Voltage Circuit State Alert Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: result.isHighVoltageSevered
                  ? AppColors.error.withValues(alpha: 0.08)
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: result.isHighVoltageSevered
                    ? AppColors.error.withValues(alpha: 0.4)
                    : AppColors.borderSubtle,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  result.isHighVoltageSevered ? Icons.power_off_rounded : Icons.bolt_rounded,
                  size: 16,
                  color: result.isHighVoltageSevered ? AppColors.error : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.isHighVoltageSevered
                        ? 'HV Pyrofuse Blown: Traction Bus Electrically Isolated'
                        : 'HV Traction Bus: Continuous Pyro Squib Ready & Armed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: result.isHighVoltageSevered ? AppColors.error : AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Advisory message container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: statusColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.safetyAdvisory,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          if (onTriggerEmergencyDisconnect != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onTriggerEmergencyDisconnect,
                icon: const Icon(Icons.flash_off_rounded, size: 18),
                label: const Text('Initiate Pyrofuse High-Voltage Disconnect', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({required String label, required String value, required bool isWarning}) {
    final color = isWarning ? AppColors.error : AppColors.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isWarning ? AppColors.error.withValues(alpha: 0.4) : AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.secondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
