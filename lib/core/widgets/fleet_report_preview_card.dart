import 'package:flutter/material.dart';
import '../models/fleet_executive_report.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Responsive card displaying executive fleet briefing summaries and download triggers
class FleetReportPreviewCard extends StatelessWidget {
  final FleetExecutiveReport report;
  final VoidCallback? onDownloadPdf;
  final VoidCallback? onShareReport;

  const FleetReportPreviewCard({
    super.key,
    required this.report,
    this.onDownloadPdf,
    this.onShareReport,
  });

  @override
  Widget build(BuildContext context) {
    final complianceColor = report.complianceScore >= 80.0
        ? AppColors.success
        : (report.complianceScore >= 60.0 ? AppColors.warning : AppColors.error);

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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assessment_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.type.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Period: ${report.dateRangeLabel}',
                      style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: complianceColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${report.complianceScore.toInt()}% SCORE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: complianceColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // KPI Grid (2x2 with wrap/clamping)
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMetricTile(
                    width: itemWidth,
                    label: 'Distance',
                    value: '${report.totalDistanceKm.toStringAsFixed(0)} km',
                    icon: Icons.route_outlined,
                  ),
                  _buildMetricTile(
                    width: itemWidth,
                    label: 'Fuel Spend',
                    value: '₹${report.totalFuelSpend.toStringAsFixed(0)}',
                    icon: Icons.local_gas_station_outlined,
                  ),
                  _buildMetricTile(
                    width: itemWidth,
                    label: 'Avg CPK',
                    value: '₹${report.averageCpk.toStringAsFixed(2)}/km',
                    icon: Icons.price_change_outlined,
                  ),
                  _buildMetricTile(
                    width: itemWidth,
                    label: 'Active Fleet',
                    value: '${report.activeVehicles} / ${report.totalVehicles}',
                    icon: Icons.directions_car_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Highlights Section
          const Text(
            'Executive Highlights',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          ...report.highlights.take(3).map((highlight) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                  Expanded(
                    child: Text(
                      highlight,
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),

          // Action Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDownloadPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                  label: const Text('Download PDF', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ),
              if (onShareReport != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onShareReport,
                    icon: const Icon(Icons.share_outlined, size: 14),
                    label: const Text('Share Brief', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required double width,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.secondary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 9, color: AppColors.secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
