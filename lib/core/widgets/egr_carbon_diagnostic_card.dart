import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/egr_flow_carbon_diagnostic_service.dart';

/// Responsive, AQIL-compliant EGR Carbon Fouling & Cooler Diagnostic Card.
class EgrCarbonDiagnosticCard extends StatelessWidget {
  final EgrHealthResult result;
  final VoidCallback? onScheduleDecarbonization;

  const EgrCarbonDiagnosticCard({
    super.key,
    required this.result,
    this.onScheduleDecarbonization,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String badgeText;
    switch (result.status) {
      case EgrHealthStatus.normalRecirculation:
        statusColor = AppColors.success;
        badgeText = 'CLEAN FLOW';
        break;
      case EgrHealthStatus.moderateSootClogging:
        statusColor = AppColors.warning;
        badgeText = 'CARBON FOULING';
        break;
      case EgrHealthStatus.criticalValveStuckOrCoolerClogged:
        statusColor = AppColors.error;
        badgeText = 'VALVE STUCK';
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  result.isHealthy ? Icons.eco_rounded : Icons.warning_amber_rounded,
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
                      'EGR Valve & Cooler Sentinel',
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
                      '${result.vehicleId} • NOx Recirculation Diagnostics',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor, width: 0.8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Responsive Metric Tiles
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Soot Accumulation',
                  value: '${result.sootAccumulationIndexPercent.toStringAsFixed(0)}%',
                  isWarning: result.sootAccumulationIndexPercent >= 35.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Tracking Error',
                  value: '${result.positionTrackingErrorPercent.toStringAsFixed(1)}%',
                  isWarning: result.positionTrackingErrorPercent >= 7.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Cooler Temp',
                  value: result.isCoolerThermalEfficiencyDegraded ? 'HOT / CHOKED' : 'NOMINAL',
                  isWarning: result.isCoolerThermalEfficiencyDegraded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Soot Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'EGR Gas Pathway Decarbonization Index',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${result.sootAccumulationIndexPercent.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (result.sootAccumulationIndexPercent / 100.0).clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceContainerLow,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // Advisory Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.diagnosticAction,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: statusColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          if (onScheduleDecarbonization != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onScheduleDecarbonization,
                icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                label: const Text('Schedule EGR Decarbonization Service', style: TextStyle(fontWeight: FontWeight.w700)),
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
