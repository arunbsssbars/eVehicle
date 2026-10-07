import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/toll_auditor_service.dart';

/// Responsive, AQIL-compliant Electronic Toll & ERP Auditor card.
class TollAuditorCard extends StatelessWidget {
  final TollAuditSummary summary;
  final VoidCallback? onFileDisputeClaim;

  const TollAuditorCard({
    super.key,
    required this.summary,
    this.onFileDisputeClaim,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = summary.hasOverchargeDiscrepancies ? AppColors.warning : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: summary.hasOverchargeDiscrepancies
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.borderSubtle,
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
                  Icons.toll_rounded,
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
                      summary.registrationNumber,
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
                      'Toll & FASTag Auditor • ${summary.totalPlazasPassed} Plazas Reconciled',
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

          // Total Debited vs Legitimate Amount KPI Banner
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
                      const Text('Total Toll Billed', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      const SizedBox(height: 2),
                      Text(
                        '₹${summary.totalBilledAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                      ),
                      Text('Legitimate: ₹${summary.legitimateExpectedAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 9.5, color: AppColors.secondary)),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: AppColors.borderSubtle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Refund Entitlement', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      const SizedBox(height: 2),
                      Text(
                        '₹${summary.totalRefundEntitlement.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: summary.hasOverchargeDiscrepancies ? AppColors.warning : AppColors.success,
                        ),
                      ),
                      Text(summary.hasOverchargeDiscrepancies ? '${summary.discrepancies.length} Overcharges Found' : 'Clean Statement', style: TextStyle(fontSize: 9.5, color: summary.hasOverchargeDiscrepancies ? AppColors.warning : AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Discrepancy Items list
          if (summary.hasOverchargeDiscrepancies) ...[
            const Text(
              'Identified Toll Plaza Discrepancies',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onSurface),
            ),
            const SizedBox(height: 6),
            ...summary.discrepancies.take(3).map((d) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${d.plazaName} • Refund: ₹${d.refundEntitlement.toStringAsFixed(0)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                            ),
                            Text(
                              d.issueDescription,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],

          if (onFileDisputeClaim != null && summary.hasOverchargeDiscrepancies) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onFileDisputeClaim,
                icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                label: const Text(
                  'Submit Auto-Dispute Claim Packet',
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
