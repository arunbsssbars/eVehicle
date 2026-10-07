import 'package:flutter/material.dart';
import '../services/ubi_insurance_service.dart';

/// Defensive AQIL Card displaying UBI insurance telematics risk and policy adjustments.
class UbiInsuranceCard extends StatelessWidget {
  final UbiPremiumAudit audit;
  final VoidCallback? onDownloadCertificate;

  const UbiInsuranceCard({
    super.key,
    required this.audit,
    this.onDownloadCertificate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDiscount = audit.premiumAdjustmentPercent < 0;
    final isSurcharge = audit.premiumAdjustmentPercent > 0;
    final statusColor = isDiscount
        ? const Color(0xFF10B981)
        : (isSurcharge ? const Color(0xFFDC2626) : Colors.blueGrey);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.security,
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
                        'Telematics Insurance Rating',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Risk Score: ${audit.compositeRiskScore}/100 • ${isDiscount ? "Saving \$${audit.netMonthlySavingsUsd}/mo" : "Standard Rating"}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    _tierLabel(audit.tier),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Premium Comparison Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Book Premium', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                        Text('\$${audit.baseMonthlyPremiumUsd}/mo', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${audit.premiumAdjustmentPercent > 0 ? "+" : ""}${audit.premiumAdjustmentPercent}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('UBI Premium', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                        Text(
                          '\$${audit.adjustedMonthlyPremiumUsd}/mo',
                          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Summary Notice
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
                    isDiscount ? Icons.verified : Icons.info_outline,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      audit.actuarialSummary,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSurcharge ? Colors.red.shade900 : theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (onDownloadCertificate != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: onDownloadCertificate,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text(
                    'Download Underwriter Telematics Endorsement',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _tierLabel(InsuranceTier tier) {
    switch (tier) {
      case InsuranceTier.platinumPreferred:
        return 'PLATINUM -25%';
      case InsuranceTier.goldStandard:
        return 'GOLD -15%';
      case InsuranceTier.silverBaseline:
        return 'STANDARD';
      case InsuranceTier.elevatedRisk:
        return 'SURCHARGE +15%';
      case InsuranceTier.highRiskProvisional:
        return 'HIGH RISK';
    }
  }
}
