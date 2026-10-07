import 'package:flutter/material.dart';
import '../models/sync_conflict_record.dart';
import '../services/sync_conflict_matrix_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Interactive UI card for reviewing and resolving offline synchronization conflicts
class SyncConflictResolverCard extends StatelessWidget {
  final SyncConflictRecord conflict;
  final VoidCallback? onAutoMerge;
  final VoidCallback? onKeepLocal;
  final VoidCallback? onKeepServer;

  const SyncConflictResolverCard({
    super.key,
    required this.conflict,
    this.onAutoMerge,
    this.onKeepLocal,
    this.onKeepServer,
  });

  @override
  Widget build(BuildContext context) {
    final isResolved = conflict.status == SyncConflictStatus.autoResolved;
    final statusColor = isResolved ? AppColors.success : AppColors.warning;
    final statusLabel = isResolved ? 'RESOLVED' : 'CONFLICT';

    final conflictingKeys = SyncConflictMatrixService.identifyConflictingKeys(
      conflict.localData,
      conflict.serverData,
    );

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
                  isResolved ? Icons.check_circle_outline : Icons.sync_problem_rounded,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${conflict.entityType} • ${conflict.entityId}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Local v${conflict.localVersion} vs Server v${conflict.serverVersion}',
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
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Conflicting fields summary
          if (conflictingKeys.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${conflictingKeys.length} Divergent Field(s)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...conflictingKeys.take(3).map((key) {
                    final localVal = conflict.localData[key];
                    final serverVal = conflict.serverData[key];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$key: ',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Device "$localVal" ↔ Cloud "$serverVal"',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          if (conflict.resolutionSummary != null) ...[
            const SizedBox(height: 6),
            Text(
              conflict.resolutionSummary!,
              style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Resolution Action Buttons
          if (!isResolved) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAutoMerge,
                    icon: const Icon(Icons.merge_type_rounded, size: 14),
                    label: const Text('Auto-Merge', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
                if (onKeepLocal != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onKeepLocal,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('Keep Local', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
