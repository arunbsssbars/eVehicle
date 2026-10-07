import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/landing_gear_load_splay_service.dart';

/// Responsive, AQIL-compliant Semi-Trailer Landing Gear Leg Load & Splay Sentry Card.
class LandingGearLoadSplayCard extends StatelessWidget {
  final LandingGearAuditResult result;
  final VoidCallback? onDeployGroundSupports;

  const LandingGearLoadSplayCard({
    super.key,
    required this.result,
    this.onDeployGroundSupports,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String badgeText;
    switch (result.status) {
      case LandingGearLoadSplayStatus.plumbAndStable:
        statusColor = AppColors.success;
        badgeText = 'LEGS PLUMB & FIRM';
        break;
      case LandingGearLoadSplayStatus.splaySettlementWarning:
        statusColor = AppColors.warning;
        badgeText = 'SINKING WARNING';
        break;
      case LandingGearLoadSplayStatus.criticalBucklingCollapseHazard:
        statusColor = AppColors.error;
        badgeText = 'BUCKLING COLLAPSE';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.isImminentTipoverRisk ? AppColors.error : AppColors.borderSubtle,
          width: result.isImminentTipoverRisk ? 1.5 : 1.0,
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
                  result.isLegPlumbAndSound ? Icons.straighten_rounded : Icons.warning_amber_rounded,
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
                      'Trailer Landing Gear Sentry',
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
                      '${result.vehicleId} • Dolly Leg Load & Plumb Splay',
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
                  label: 'Total Load',
                  value: '${result.totalLoadTonnes.toStringAsFixed(1)} T',
                  isWarning: result.totalLoadTonnes >= 40.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Splay Angle',
                  value: '${result.splayDegrees.toStringAsFixed(1)}°',
                  isWarning: result.splayDegrees >= 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Settlement',
                  value: '${result.groundSettlementMm.toStringAsFixed(0)} mm',
                  isWarning: result.groundSettlementMm >= 25.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Leg Load Asymmetry Progress Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Curbside / Roadside Leg Imbalance',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${result.loadAsymmetryTonnes.toStringAsFixed(1)} T delta',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: result.loadAsymmetryTonnes >= 4.5 ? AppColors.warning : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (result.loadAsymmetryTonnes / 8.0).clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceContainerLow,
              valueColor: AlwaysStoppedAnimation<Color>(
                result.loadAsymmetryTonnes >= 6.0
                    ? AppColors.error
                    : (result.loadAsymmetryTonnes >= 4.0 ? AppColors.warning : AppColors.success),
              ),
              minHeight: 6,
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
                Icon(Icons.fence_rounded, color: statusColor, size: 16),
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

          if (onDeployGroundSupports != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onDeployGroundSupports,
                icon: const Icon(Icons.support_rounded, size: 18),
                label: const Text('Deploy Landing Gear Ground Outriggers', style: TextStyle(fontWeight: FontWeight.w700)),
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
