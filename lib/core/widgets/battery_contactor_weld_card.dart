import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/battery_contactor_weld_auditor_service.dart';

/// Responsive, AQIL-compliant EV High-Voltage Contactor Weld & Pre-Charge Sentry Card.
class BatteryContactorWeldCard extends StatelessWidget {
  final BatteryContactorWeldAuditResult result;
  final VoidCallback? onTriggerEmergencyIsolation;

  const BatteryContactorWeldCard({
    super.key,
    required this.result,
    this.onTriggerEmergencyIsolation,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String badgeText;
    switch (result.status) {
      case BatteryContactorWeldStatus.contactorsNominalCycleSound:
        statusColor = AppColors.success;
        badgeText = 'CONTACTORS CLEAN';
        break;
      case BatteryContactorWeldStatus.preChargeThermalStressWarning:
        statusColor = AppColors.warning;
        badgeText = 'PRE-CHARGE HOT';
        break;
      case BatteryContactorWeldStatus.criticalMainContactorWeldHazard:
        statusColor = AppColors.error;
        badgeText = 'CONTACTOR WELD';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.isWeldedCriticalFault ? AppColors.error : AppColors.borderSubtle,
          width: result.isWeldedCriticalFault ? 1.5 : 1.0,
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
                  result.isIsolationSound ? Icons.power_rounded : Icons.flash_on_rounded,
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
                      'HV Contactor Weld Sentry',
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
                      '${result.vehicleId} • Main Contactors & Pre-Charge',
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
                  label: 'Link Voltage',
                  value: '${result.linkVoltageVolts.toStringAsFixed(0)} V',
                  isWarning: result.isWeldedCriticalFault,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Pre-Charge Temp',
                  value: '${result.preChargeTempCelsius.toStringAsFixed(1)} °C',
                  isWarning: result.preChargeTempCelsius >= 95.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Weld Status',
                  value: result.isWeldedCriticalFault ? 'FUSED' : 'HEALTHY',
                  isWarning: result.isWeldedCriticalFault,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Contactor State Indicator Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: result.isWeldedCriticalFault
                  ? AppColors.error.withValues(alpha: 0.08)
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: result.isWeldedCriticalFault
                    ? AppColors.error.withValues(alpha: 0.4)
                    : AppColors.borderSubtle,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  result.isWeldedCriticalFault ? Icons.report_problem_rounded : Icons.check_circle_rounded,
                  size: 16,
                  color: result.isWeldedCriticalFault ? AppColors.error : AppColors.success,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.isWeldedCriticalFault
                        ? 'Dangerous HV Contact Fusion: Inverter Terminals Energized'
                        : 'Contactor Galvanic Isolation Sound: 0V Residual on Link Bus',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: result.isWeldedCriticalFault ? AppColors.error : AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Advisory banner
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
                Icon(Icons.shield_outlined, color: statusColor, size: 16),
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

          if (onTriggerEmergencyIsolation != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onTriggerEmergencyIsolation,
                icon: const Icon(Icons.flash_off_rounded, size: 18),
                label: const Text('Execute Pyrofuse Galvanic Isolation', style: TextStyle(fontWeight: FontWeight.w700)),
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
