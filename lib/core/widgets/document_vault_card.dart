import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehicle_document.dart';
import '../services/document_vault_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Card displaying vehicle statutory document compliance and upcoming expirations
class DocumentVaultCard extends StatelessWidget {
  final List<VehicleDocument> documents;
  final VoidCallback? onManagePressed;

  const DocumentVaultCard({
    super.key,
    required this.documents,
    this.onManagePressed,
  });

  @override
  Widget build(BuildContext context) {
    final summary = DocumentVaultService.evaluateCompliance(documents);
    final expiringSoon = DocumentVaultService.getExpiringDocuments(documents, daysAhead: 45);

    final statusColor = summary.isFullyCompliant ? AppColors.success : AppColors.warning;

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
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  summary.isFullyCompliant ? Icons.verified_rounded : Icons.pending_actions_rounded,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statutory Document Vault',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'RC • Insurance • PUC • SHA-256 Vault',
                      style: TextStyle(fontSize: 11, color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onManagePressed != null)
                TextButton(
                  onPressed: onManagePressed,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(44, 32),
                  ),
                  child: const Text('Manage', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Compliance Summary Chips
          Row(
            children: [
              Expanded(
                child: _buildMetricMini(
                  label: 'Valid',
                  count: summary.validCount,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricMini(
                  label: 'Expiring',
                  count: summary.expiringSoonCount,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricMini(
                  label: 'Expired',
                  count: summary.expiredCount,
                  color: AppColors.error,
                ),
              ),
            ],
          ),

          if (expiringSoon.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 8),
            Text(
              'Urgent Expiry Alerts (${expiringSoon.length})',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onSurface),
            ),
            const SizedBox(height: 6),
            ...expiringSoon.take(3).map((doc) => _buildExpiringDocRow(doc)),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricMini({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
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

  Widget _buildExpiringDocRow(VehicleDocument doc) {
    final urgencyColor = Color(doc.urgencyColorValue);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.description_outlined, size: 14, color: urgencyColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.type.label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${doc.documentNumber} • Exp: ${dateFormat.format(doc.expiryDate)}',
                  style: const TextStyle(fontSize: 10, color: AppColors.secondary),
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
              color: urgencyColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              doc.expiryStatusLabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: urgencyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
