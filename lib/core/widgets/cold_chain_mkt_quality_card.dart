import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/cold_chain_telemetry_service.dart';

/// Responsive, AQIL-compliant Cold-Chain Mean Kinetic Temperature (MKT) Quality Sentinel card.
class ColdChainMktQualityCard extends StatelessWidget {
  final ColdChainAuditReport report;
  final String consignmentBatchNumber;
  final VoidCallback? onExportCertificate;

  const ColdChainMktQualityCard({
    super.key,
    required this.report,
    required this.consignmentBatchNumber,
    this.onExportCertificate,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = report.isCompliant ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: report.isCompliant ? AppColors.borderSubtle : AppColors.error.withValues(alpha: 0.5),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.ac_unit_rounded,
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
                      'Batch: $consignmentBatchNumber',
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
                      'Cold-Chain Telemetry • ${report.complianceVerdict}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: report.isCompliant ? AppColors.secondary : AppColors.error,
                        fontWeight: report.isCompliant ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Temperature Metrics Grid
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
                      const Text('Mean / MKT Temp', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${report.meanTemperatureC}°C / ${report.meanKineticTemperatureC}°C',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                      ),
                      Text('Range: ${report.minRecordedTempC}°C to ${report.maxRecordedTempC}°C', style: const TextStyle(fontSize: 9.5, color: AppColors.secondary)),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: AppColors.borderSubtle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Spoilage Risk Score', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${report.spoilageRiskScore.toStringAsFixed(1)} / 100',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: report.spoilageRiskScore > 30 ? AppColors.error : AppColors.success,
                        ),
                      ),
                      Text('Excursions: ${report.totalExcursionMinutes} min', style: const TextStyle(fontSize: 9.5, color: AppColors.secondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quality Indicator Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAuditChip(
                label: 'Excursions: ${report.totalExcursionMinutes} mins',
                isAlert: report.totalExcursionMinutes > 0,
              ),
              _buildAuditChip(
                label: 'Door Openings: ${report.doorOpeningsCount}',
                isAlert: report.doorOpeningsCount > 4,
              ),
              _buildAuditChip(
                label: report.isCompliant ? 'WHO / GDP Validated' : 'Audit Flagged',
                isAlert: !report.isCompliant,
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (onExportCertificate != null) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: onExportCertificate,
                icon: const Icon(Icons.verified_rounded, size: 16),
                label: const Text(
                  'Generate Pharma Cold-Chain CoA Certificate',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.borderSubtle),
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

  Widget _buildAuditChip({required String label, required bool isAlert}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAlert
            ? AppColors.errorContainer.withValues(alpha: 0.4)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAlert ? AppColors.error : AppColors.borderSubtle,
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isAlert ? AppColors.error : AppColors.onSurface,
        ),
      ),
    );
  }
}
