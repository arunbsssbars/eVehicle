import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/multi_fuel_auditor_service.dart';

/// Responsive, AQIL-compliant Multi-Fuel & Alternative Energy Efficiency Auditor Card.
class MultiFuelAuditorCard extends StatelessWidget {
  final EnergyAuditResult result;
  final VoidCallback? onLogEnergyPurchase;

  const MultiFuelAuditorCard({
    super.key,
    required this.result,
    this.onLogEnergyPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = result.isAnomalousConsumption
        ? AppColors.error
        : (result.costSavingsPercentage > 0 ? AppColors.success : AppColors.primary);

    final unitLabel = result.fuelType == FleetFuelType.electric
        ? 'kWh'
        : (result.fuelType == FleetFuelType.cng ? 'kg' : 'L');

    final rateUnit = result.fuelType == FleetFuelType.electric
        ? 'km/kWh'
        : (result.fuelType == FleetFuelType.cng ? 'km/kg' : 'km/L');

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
                  result.fuelType == FleetFuelType.electric
                      ? Icons.electric_bolt_rounded
                      : (result.fuelType == FleetFuelType.cng ? Icons.eco_rounded : Icons.local_gas_station_rounded),
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
                      '${result.vehicleId} • ${result.fuelType.name.toUpperCase()}',
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
                      '${result.totalDistanceKm} km total • ${result.totalSpend} spend',
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
                  result.isAnomalousConsumption ? 'Anomaly' : 'Optimal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3 Metric Grid
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  label: 'Efficiency',
                  value: '${result.averageEfficiency} $rateUnit',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetric(
                  label: 'Cost / Km',
                  value: '\$${result.averageCostPerKm}',
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetric(
                  label: 'Savings',
                  value: '${result.costSavingsPercentage}%',
                  color: result.costSavingsPercentage >= 0 ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // CO2 and Consumption Detail
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Total Fuel: ${result.totalQuantity} $unitLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ),
                Text(
                  'CO₂: ${result.co2EmissionsKg} kg',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Recommendation Banner
          Text(
            result.recommendation,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.onSurfaceVariant,
            ),
          ),

          if (onLogEnergyPurchase != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onLogEnergyPurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text(
                  'Log Energy Purchase',
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
