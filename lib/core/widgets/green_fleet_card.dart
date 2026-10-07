import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/carbon_emissions_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Reusable defensive AQIL responsive card showing Fleet Carbon Footprint & Eco-Rating.
class GreenFleetCard extends StatelessWidget {
  final double totalDistanceKm;
  final double totalEmissionsKg;
  final double carbonSavedKg;
  final VoidCallback? onTap;

  const GreenFleetCard({
    super.key,
    required this.totalDistanceKm,
    required this.totalEmissionsKg,
    required this.carbonSavedKg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ecoRating = CarbonEmissionsService.getEcoRating(
      totalDistanceKm: totalDistanceKm,
      totalEmissionsKg: totalEmissionsKg,
    );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(ecoRating.colorValue).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.eco_rounded,
                  color: Color(ecoRating.colorValue),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Green Fleet & Carbon Analytics',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'ESG Tracking • ${NumberFormat('#,##0').format(totalDistanceKm)} KM logged',
                      style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(ecoRating.colorValue).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Color(ecoRating.colorValue), width: 0.8),
                ),
                child: Text(
                  ecoRating.grade,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(ecoRating.colorValue),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metrics Grid (Defensive Wrap for narrow viewports)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricPill(
                label: 'Total Footprint',
                value: '${totalEmissionsKg.toStringAsFixed(1)} kg CO₂',
                icon: Icons.cloud_outlined,
                color: AppColors.primary,
              ),
              _buildMetricPill(
                label: 'Clean Saved',
                value: '${carbonSavedKg.toStringAsFixed(1)} kg CO₂',
                icon: Icons.energy_savings_leaf_rounded,
                color: const Color(0xFF16A34A),
              ),
              _buildMetricPill(
                label: 'Fleet Rating',
                value: ecoRating.label,
                icon: Icons.verified_outlined,
                color: Color(ecoRating.colorValue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
