import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/fifth_wheel_coupling_guard_service.dart';

/// Responsive, AQIL-compliant Fifth Wheel Coupler Lock Sentinel Card.
class FifthWheelCouplerCard extends StatelessWidget {
  final FifthWheelCouplingResult result;
  final VoidCallback? onPerformPullTest;

  const FifthWheelCouplerCard({
    super.key,
    required this.result,
    this.onPerformPullTest,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String badgeText;
    switch (result.status) {
      case FifthWheelSecurityStatus.securelyLocked:
        statusColor = AppColors.success;
        badgeText = 'SECURELY LOCKED';
        break;
      case FifthWheelSecurityStatus.warningImproperAlignment:
        statusColor = AppColors.warning;
        badgeText = 'INCOMPLETE LATCH';
        break;
      case FifthWheelSecurityStatus.criticalFalseLockRisk:
        statusColor = AppColors.error;
        badgeText = 'FALSE LOCK RISK';
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
          // Header Layout (Responsive for 320px & 1.5x font scale)
          LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 300;
              return Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      result.isSafeToDrive ? Icons.lock_rounded : Icons.lock_open_rounded,
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
                          'Fifth Wheel Coupler Guard',
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
                          '${result.vehicleId} • Semi-Trailer Articulation',
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
              );
            },
          ),
          const SizedBox(height: 14),

          // Metric Tiles
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 340) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Kingpin Depth',
                            value: '${result.kingpinDepthMm.toStringAsFixed(1)} mm',
                            isWarning: result.kingpinDepthMm < 45.0 || result.kingpinDepthMm > 58.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Jaw Pressure',
                            value: '${result.jawClampPressureBar.toStringAsFixed(0)} Bar',
                            isWarning: result.jawClampPressureBar < 100.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildMetricTile(
                      label: 'Secondary Lock Latch',
                      value: result.isSecondaryEngaged ? 'ENGAGED' : 'UNLATCHED',
                      isWarning: !result.isSecondaryEngaged,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Kingpin Depth',
                      value: '${result.kingpinDepthMm.toStringAsFixed(1)} mm',
                      isWarning: result.kingpinDepthMm < 45.0 || result.kingpinDepthMm > 58.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Jaw Pressure',
                      value: '${result.jawClampPressureBar.toStringAsFixed(0)} Bar',
                      isWarning: result.jawClampPressureBar < 100.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Secondary Lock',
                      value: result.isSecondaryEngaged ? 'ENGAGED' : 'UNLATCHED',
                      isWarning: !result.isSecondaryEngaged,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Integrity Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Coupler Lock Integrity Score',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${result.hitchIntegrityScorePercent.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: result.hitchIntegrityScorePercent / 100.0,
              backgroundColor: AppColors.surfaceContainerLow,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // Advisory Banner
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
                    result.safetyAdvisory,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: statusColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          if (onPerformPullTest != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onPerformPullTest,
                icon: const Icon(Icons.sync_problem_rounded, size: 18),
                label: const Text('Perform Trailer Tug / Pull Test', style: TextStyle(fontWeight: FontWeight.w700)),
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
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
