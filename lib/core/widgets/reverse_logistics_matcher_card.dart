import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/reverse_logistics_matcher_service.dart';

/// Responsive, AQIL-compliant Reverse Logistics & Empty-Mile Freight Matcher card.
class ReverseLogisticsMatcherCard extends StatelessWidget {
  final BackhaulMatchResult result;
  final VoidCallback? onAcceptBackhaulLoad;

  const ReverseLogisticsMatcherCard({
    super.key,
    required this.result,
    this.onAcceptBackhaulLoad,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = result.hasViableMatches ? AppColors.success : AppColors.secondary;

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
                  Icons.sync_alt_rounded,
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
                      result.registrationNumber,
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
                      'Reverse Logistics Backhaul • ${result.originalDeadheadKm.toStringAsFixed(0)} km Empty Return',
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

          // Yield & Carbon Abatement Banner
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
                      const Text('Backhaul Profit Gain', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      const SizedBox(height: 2),
                      Text(
                        '₹${result.potentialRevenueYield.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                      Text(result.hasViableMatches ? '${result.rankedOpportunities.where((o) => o.isFitApproved).length} Loads Matched' : 'No Active Backhauls', style: const TextStyle(fontSize: 9.5, color: AppColors.secondary)),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: AppColors.borderSubtle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CO2 Avoided', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${result.totalCarbonSavingsKg.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text('Deadhead Consolidation', style: TextStyle(fontSize: 9.5, color: AppColors.secondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Matched Opportunities List
          ...result.rankedOpportunities.take(2).map((opp) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: opp.isFitApproved ? AppColors.success.withValues(alpha: 0.3) : AppColors.borderSubtle,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            opp.cargo.shipperName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                          ),
                        ),
                        Text(
                          '₹${opp.netProfitGain.toStringAsFixed(0)} Profit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: opp.isFitApproved ? AppColors.success : AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${opp.cargo.pickupLocation.locationName} ➔ ${opp.cargo.dropoffLocation.locationName} • ${opp.cargo.weightKg.toStringAsFixed(0)} kg • ${opp.routeDeviationKm} km detour',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
            );
          }),

          if (onAcceptBackhaulLoad != null && result.hasViableMatches) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onAcceptBackhaulLoad,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text(
                  'Accept Best Backhaul & Assign Route',
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
