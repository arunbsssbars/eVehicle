import 'package:flutter/material.dart';
import '../models/fleet_scorecard_index.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Grand responsive scorecard card for enterprise fleet managers and executives
class ExecutiveFleetScorecardCard extends StatelessWidget {
  final FleetScorecardIndex scorecard;
  final VoidCallback? onViewDetails;

  const ExecutiveFleetScorecardCard({
    super.key,
    required this.scorecard,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final gradeColor = Color(scorecard.grade.colorValue);

    return Container(
      padding: const EdgeInsets.all(12),
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
                  color: gradeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.stars_rounded,
                  color: gradeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Executive Fleet Scorecard',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Multi-Pillar Operational Health Index',
                      style: TextStyle(fontSize: 11, color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      scorecard.grade.letter,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: gradeColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${scorecard.compositeScore.toStringAsFixed(0)}/100',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: gradeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4-Pillar Metric Bars
          _buildPillarRow('Safety & Fatigue', scorecard.safetyScore, AppColors.primary),
          const SizedBox(height: 6),
          _buildPillarRow('Maintenance Health', scorecard.maintenanceReliabilityScore, AppColors.success),
          const SizedBox(height: 6),
          _buildPillarRow('Regulatory Compliance', scorecard.regulatoryComplianceScore, AppColors.warning),
          const SizedBox(height: 6),
          _buildPillarRow('ESG & Fuel Efficiency', scorecard.esgGreenScore, const Color(0xFF10B981)),
          const SizedBox(height: 12),

          // Strategic Recommendations
          const Text(
            'Strategic Guidance',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          ...scorecard.strategicRecommendations.take(2).map((rec) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('→ ', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                  Expanded(
                    child: Text(
                      rec,
                      style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),

          if (onViewDetails != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.analytics_outlined, size: 14),
                label: const Text('View Detailed Analytics', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 36),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPillarRow(String title, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${score.toInt()}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: score / 100.0,
            minHeight: 4,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
