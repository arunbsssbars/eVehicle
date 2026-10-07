import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../models/journey.dart';
import '../models/vehicle.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    this.icon,
  });

  factory StatusBadge.fromJourneyStatus(JourneyStatus status) {
    switch (status) {
      case JourneyStatus.draft:
        return const StatusBadge(
          label: 'DRAFT',
          textColor: AppColors.gray600,
          backgroundColor: AppColors.gray100,
          icon: Icons.edit_note,
        );
      case JourneyStatus.active:
        return const StatusBadge(
          label: 'ACTIVE',
          textColor: AppColors.primary,
          backgroundColor: AppColors.primaryFixed,
          icon: Icons.navigation,
        );
      case JourneyStatus.completed:
        return const StatusBadge(
          label: 'COMPLETED',
          textColor: AppColors.primaryContainer,
          backgroundColor: AppColors.secondaryContainer,
          icon: Icons.check_circle_outline,
        );
      case JourneyStatus.submitted:
      case JourneyStatus.pendingApproval:
        return const StatusBadge(
          label: 'PENDING APPROVAL',
          textColor: AppColors.warning,
          backgroundColor: AppColors.warningContainer,
          icon: Icons.hourglass_top,
        );
      case JourneyStatus.approved:
        return const StatusBadge(
          label: 'APPROVED',
          textColor: AppColors.success,
          backgroundColor: AppColors.successContainer,
          icon: Icons.verified,
        );
      case JourneyStatus.rejected:
        return const StatusBadge(
          label: 'REJECTED',
          textColor: AppColors.error,
          backgroundColor: AppColors.errorContainer,
          icon: Icons.cancel_outlined,
        );
      case JourneyStatus.cancelled:
        return const StatusBadge(
          label: 'CANCELLED',
          textColor: AppColors.gray500,
          backgroundColor: AppColors.gray100,
          icon: Icons.block,
        );
      case JourneyStatus.pendingDeletion:
        return const StatusBadge(
          label: 'PENDING DELETION',
          textColor: AppColors.error,
          backgroundColor: AppColors.errorContainer,
          icon: Icons.delete_sweep_outlined,
        );
      case JourneyStatus.locked:
        return const StatusBadge(
          label: 'LOCKED',
          textColor: AppColors.gray700,
          backgroundColor: AppColors.gray200,
          icon: Icons.lock,
        );
    }
  }

  factory StatusBadge.fromVehicleStatus(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active:
        return const StatusBadge(
          label: 'ACTIVE',
          textColor: AppColors.success,
          backgroundColor: AppColors.successContainer,
          icon: Icons.check_circle,
        );
      case VehicleStatus.underRepair:
        return const StatusBadge(
          label: 'UNDER REPAIR',
          textColor: AppColors.warning,
          backgroundColor: AppColors.warningContainer,
          icon: Icons.build_circle,
        );
      case VehicleStatus.inactive:
        return const StatusBadge(
          label: 'INACTIVE',
          textColor: AppColors.gray600,
          backgroundColor: AppColors.gray100,
          icon: Icons.pause_circle_outline,
        );
      case VehicleStatus.sold:
      case VehicleStatus.retired:
        return const StatusBadge(
          label: 'RETIRED',
          textColor: AppColors.error,
          backgroundColor: AppColors.errorContainer,
          icon: Icons.archive,
        );
    }
  }

  factory StatusBadge.fromSyncStatus(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return const StatusBadge(
          label: 'SYNCED',
          textColor: AppColors.success,
          backgroundColor: AppColors.successContainer,
          icon: Icons.cloud_done,
        );
      case SyncStatus.pending:
        return const StatusBadge(
          label: 'SYNC PENDING',
          textColor: AppColors.warning,
          backgroundColor: AppColors.warningContainer,
          icon: Icons.cloud_upload_outlined,
        );
      case SyncStatus.syncing:
        return const StatusBadge(
          label: 'SYNCING',
          textColor: AppColors.primary,
          backgroundColor: AppColors.primaryFixed,
          icon: Icons.sync,
        );
      case SyncStatus.conflict:
        return const StatusBadge(
          label: 'CONFLICT',
          textColor: AppColors.error,
          backgroundColor: AppColors.errorContainer,
          icon: Icons.warning,
        );
      case SyncStatus.failed:
        return const StatusBadge(
          label: 'FAILED',
          textColor: AppColors.error,
          backgroundColor: AppColors.errorContainer,
          icon: Icons.error_outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
