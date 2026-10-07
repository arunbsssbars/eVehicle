import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/tenant_backup_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Card providing multi-tenant backup snapshot creation and verified restore controls
class TenantBackupPortalCard extends StatelessWidget {
  final TenantDataSnapshot? lastSnapshot;
  final VoidCallback onExportSnapshot;
  final VoidCallback onImportSnapshot;

  const TenantBackupPortalCard({
    super.key,
    this.lastSnapshot,
    required this.onExportSnapshot,
    required this.onImportSnapshot,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

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
          const Row(
            children: [
              Icon(Icons.cloud_sync_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tenant Data Backup & Migration',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Encrypted Snapshots • SHA-256 Manifest',
                      style: TextStyle(fontSize: 11, color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Last Snapshot Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(
                  lastSnapshot != null ? Icons.verified_user_outlined : Icons.info_outline_rounded,
                  size: 16,
                  color: lastSnapshot != null ? AppColors.success : AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lastSnapshot != null
                        ? 'Last Snapshot: ${dateFormat.format(lastSnapshot!.exportedAt)} • ${lastSnapshot!.vehicles.length} veh, ${lastSnapshot!.journeys.length} trips'
                        : 'No offline snapshot exported yet for this tenant',
                    style: TextStyle(
                      fontSize: 11,
                      color: lastSnapshot != null ? AppColors.onSurface : AppColors.secondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onImportSnapshot,
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('Restore', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onExportSnapshot,
                  icon: const Icon(Icons.file_upload_outlined, size: 16),
                  label: const Text('Backup Now', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surfaceWhite,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
