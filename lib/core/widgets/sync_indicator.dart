import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SyncIndicator extends StatelessWidget {
  final bool isOffline;
  final int pendingCount;
  final VoidCallback? onSyncTap;
  final bool isSyncing;

  const SyncIndicator({
    super.key,
    required this.isOffline,
    required this.pendingCount,
    this.onSyncTap,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && pendingCount == 0 && !isSyncing) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isOffline
          ? const Color(0xFFFEF3C7)
          : (pendingCount > 0
              ? AppColors.warningContainer
              : AppColors.secondaryContainer),
      child: Row(
        children: [
          Icon(
            isOffline
                ? Icons.wifi_off_rounded
                : (isSyncing ? Icons.sync : Icons.cloud_upload_outlined),
            size: 16,
            color: isOffline
                ? const Color(0xFFB45309)
                : (pendingCount > 0 ? AppColors.warning : AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOffline
                  ? 'Offline Mode Active • Records stored securely on device'
                  : (isSyncing
                      ? 'Syncing records with server...'
                      : '$pendingCount pending record(s) to synchronize'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOffline
                    ? const Color(0xFF92400E)
                    : (pendingCount > 0
                        ? AppColors.onWarningContainer
                        : AppColors.primary),
              ),
            ),
          ),
          if (!isOffline && pendingCount > 0)
            InkWell(
              onTap: isSyncing ? null : onSyncTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSyncing
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Sync Now',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
