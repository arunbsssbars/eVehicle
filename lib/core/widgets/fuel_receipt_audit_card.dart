import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/fuel_expense_audit_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Card displaying fuel expense metrics, Cost-Per-Kilometer (CPK), and receipt audit flags
class FuelReceiptAuditCard extends StatelessWidget {
  final FuelAnalyticsSummary summary;
  final List<FuelExpenseRecord> recentRecords;
  final VoidCallback? onLogRefuelPressed;

  const FuelReceiptAuditCard({
    super.key,
    required this.summary,
    this.recentRecords = const [],
    this.onLogRefuelPressed,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final hasAnomalies = summary.flaggedAnomaliesCount > 0;
    final statusColor = hasAnomalies ? AppColors.warning : AppColors.success;

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
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_gas_station_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fuel & Expense OCR Audit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'CPK Analytics • Receipt Anomaly Guard',
                      style: TextStyle(fontSize: 11, color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onLogRefuelPressed != null)
                TextButton(
                  onPressed: onLogRefuelPressed,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(44, 32),
                  ),
                  child: const Text('Add Refuel', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Total Spend',
                  value: currencyFormat.format(summary.totalSpend),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricTile(
                  label: 'Cost / KM',
                  value: summary.costPerKm != null
                      ? '₹${summary.costPerKm!.toStringAsFixed(2)}'
                      : '--',
                  color: const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricTile(
                  label: 'Economy',
                  value: summary.avgKmPerLiter != null
                      ? '${summary.avgKmPerLiter!.toStringAsFixed(1)} km/L'
                      : '--',
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Anomaly Indicator Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(
                  hasAnomalies ? Icons.report_problem_rounded : Icons.check_circle_outline_rounded,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasAnomalies
                        ? '${summary.flaggedAnomaliesCount} refuel anomaly(s) flagged for manager audit'
                        : 'All refuel logs and receipts verified within normal bounds',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.secondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
