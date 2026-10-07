import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/fleet_charging_optimizer_service.dart';

/// Responsive, AQIL-compliant EV smart grid charging optimizer card.
class FleetChargingOptimizerCard extends StatelessWidget {
  final ChargingOptimizationPlan plan;
  final String registrationNumber;
  final VoidCallback? onScheduleCharging;

  const FleetChargingOptimizerCard({
    super.key,
    required this.plan,
    required this.registrationNumber,
    this.onScheduleCharging,
  });

  @override
  Widget build(BuildContext context) {
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
          // Header row with Icon & Vehicle Reg
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.electric_bolt_rounded,
                  color: AppColors.success,
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
                      'Smart Grid Charging Optimizer • Energy: ${plan.energyNeededKwh} kWh',
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

          // Savings & Cost KPI Banner
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
                      const Text(
                        'Optimized Cost',
                        style: TextStyle(fontSize: 10.5, color: AppColors.secondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${plan.optimalCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        'Peak: ₹${plan.unmanagedPeakCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.secondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: AppColors.borderSubtle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOU Cost Savings',
                        style: TextStyle(fontSize: 10.5, color: AppColors.secondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${plan.costSavingsPercent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Est. ${plan.estimatedDurationHours} hrs',
                        style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Parity Index vs Diesel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.compare_arrows_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'EV: ₹${plan.parityCostPerKmEv}/km vs Diesel: ₹${plan.parityCostPerKmDiesel}/km • Save ₹${plan.evSavingsPer100Km.toStringAsFixed(0)}/100km',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Schedule allocation blocks
          if (plan.scheduleBlocks.isNotEmpty) ...[
            const Text(
              'Off-Peak Charging Schedule Allocations',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: plan.scheduleBlocks.take(4).map((b) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${b.hour}:00 • ${b.tariffLabel} • ${b.energyDeliveredKwh} kWh',
                    style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          if (onScheduleCharging != null) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onScheduleCharging,
                icon: const Icon(Icons.alarm_on_rounded, size: 16),
                label: const Text(
                  'Authorize Smart Charging Schedule',
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
