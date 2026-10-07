import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/container_seal_chain_auditor_service.dart';

/// Responsive, AQIL-compliant ISO 17712 Cargo Container Seal Custody Card.
class ContainerSealChainAuditorCard extends StatelessWidget {
  final SealCustodyAuditResult result;
  final VoidCallback? onLogSealScan;

  const ContainerSealChainAuditorCard({
    super.key,
    required this.result,
    this.onLogSealScan,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String badgeText;
    switch (result.status) {
      case SealCustodyStatus.secureAndVerified:
        statusColor = AppColors.success;
        badgeText = 'VERIFIED';
        break;
      case SealCustodyStatus.breachSuspected:
        statusColor = AppColors.warning;
        badgeText = 'MISMATCH';
        break;
      case SealCustodyStatus.tamperedOrBroken:
        statusColor = AppColors.error;
        badgeText = 'TAMPERED';
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
                  result.isClean ? Icons.security_rounded : Icons.gpp_maybe_rounded,
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
                      '${result.containerNumber} • Seal Audit',
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
                      '${result.chainHash} • ${result.verifiedCheckpointsCount} checkpoints',
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
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2 Metric Gauge Row
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  label: 'Custody Chain',
                  value: result.isChainOfCustodyContinuous ? 'Continuous' : 'Broken',
                  color: result.isChainOfCustodyContinuous ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetric(
                  label: 'ISO 17712 Rating',
                  value: result.isIso17712Compliant ? 'High Security' : 'Standard',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Alert Message Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: result.isClean
                  ? AppColors.surfaceContainerLow
                  : AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              result.securityAlertMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: result.isClean ? AppColors.onSurface : AppColors.error,
              ),
            ),
          ),

          if (onLogSealScan != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onLogSealScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.nfc_rounded, size: 18),
                label: const Text(
                  'Scan Electronic NFC / RFID Seal',
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
