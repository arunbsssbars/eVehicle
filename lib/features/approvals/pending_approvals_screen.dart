import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/models/journey.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/providers/journey_provider.dart';
import '../../core/providers/auth_provider.dart';

class PendingApprovalsScreen extends ConsumerStatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  ConsumerState<PendingApprovalsScreen> createState() =>
      _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState
    extends ConsumerState<PendingApprovalsScreen> {
  void _approve(Journey j) async {
    final auth = ref.read(authProvider);
    final approverName = auth.currentUser?.name ?? 'Approving Officer';
    await ref.read(journeyProvider.notifier).approveJourney(j.id, approverName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approved ${j.id} successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _approveDeletion(Journey j) async {
    final auth = ref.read(authProvider);
    final approverName = auth.currentUser?.name ?? 'Approving Officer';
    await ref
        .read(journeyProvider.notifier)
        .confirmDeletionApproval(j.id, approverName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approved deletion for ${j.id}. Record removed.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _rejectDeletion(Journey j) async {
    final auth = ref.read(authProvider);
    final approverName = auth.currentUser?.name ?? 'Approving Officer';
    // Rejecting deletion restores it back to approved status
    await ref.read(journeyProvider.notifier).approveJourney(j.id, approverName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deletion request rejected. Journey ${j.id} retained as Approved.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showRejectDialog(Journey j) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Journey Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a reason for rejection (required):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'e.g. Discrepancy in opening odometer or non-official travel route...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final auth = ref.read(authProvider);
              final name = auth.currentUser?.name ?? 'Approver';
              await ref.read(journeyProvider.notifier).rejectJourney(
                    j.id,
                    name,
                    reasonController.text.trim(),
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Journey rejected.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  void _approveAll(List<Journey> pendingList) async {
    final auth = ref.read(authProvider);
    final approverName = auth.currentUser?.name ?? 'Approving Officer';
    for (var j in pendingList) {
      if (j.status == JourneyStatus.pendingDeletion) {
        await ref
            .read(journeyProvider.notifier)
            .confirmDeletionApproval(j.id, approverName);
      } else {
        await ref
            .read(journeyProvider.notifier)
            .approveJourney(j.id, approverName);
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Processed all ${pendingList.length} approval requests.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final journeyState = ref.watch(journeyProvider);
    final pendingJourneys = journeyState.journeys.where((j) {
      return j.status == JourneyStatus.pendingApproval ||
          j.status == JourneyStatus.submitted ||
          j.status == JourneyStatus.pendingDeletion;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pending Approvals Queue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (pendingJourneys.isNotEmpty)
            TextButton(
              onPressed: () => _approveAll(pendingJourneys),
              child: const Text(
                'Approve All',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surfaceContainerLow,
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${pendingJourneys.length} official journey logs require your verification.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: pendingJourneys.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 48, color: AppColors.success),
                          SizedBox(height: 12),
                          Text(
                            'All caught up!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'No pending journey records to approve.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: pendingJourneys.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final j = pendingJourneys[index];
                        return _buildApprovalCard(context, j);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context, Journey j) {
    final isDeletionRequest = j.status == JourneyStatus.pendingDeletion;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDeletionRequest
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.borderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDeletionRequest) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.delete_sweep_rounded,
                      size: 16, color: AppColors.error),
                  SizedBox(width: 6),
                  Text(
                    '⚠️ Deletion Approval Requested by Officer',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
          InkWell(
            onTap: () => context.push('/journeys/details', extra: j.id),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            j.id,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.open_in_new,
                            size: 13, color: AppColors.primary),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge.fromJourneyStatus(j.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${j.vehicleRegistration} • ${j.driverName}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Route: ${j.startLocation} to ${j.destination}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Purpose: ${j.purpose}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.outline,
            ),
          ),
          if (j.remarks != null && j.remarks!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Remarks: ${j.remarks}',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDeletionRequest ? AppColors.error : AppColors.secondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Distance Bar with interactive affordance
          InkWell(
            onTap: () => context.push('/journeys/details', extra: j.id),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${j.openingOdometer.toStringAsFixed(0)} to ${j.closingOdometer?.toStringAsFixed(0) ?? "?"} KM',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${j.calculatedDistance.toStringAsFixed(1)} KM',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Action Buttons
          Row(
            children: [
              if (isDeletionRequest) ...[
                Expanded(
                  child: PrimaryButton(
                    label: 'Approve Deletion',
                    icon: Icons.delete_forever_rounded,
                    backgroundColor: AppColors.error,
                    height: 40,
                    onPressed: () => _approveDeletion(j),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    label: 'Reject Deletion',
                    icon: Icons.restore_rounded,
                    height: 40,
                    onPressed: () => _rejectDeletion(j),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: PrimaryButton(
                    label: 'Approve',
                    icon: Icons.check,
                    backgroundColor: AppColors.success,
                    height: 40,
                    onPressed: () => _approve(j),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    label: 'Reject',
                    icon: Icons.close,
                    textColor: AppColors.error,
                    borderColor: AppColors.error,
                    height: 40,
                    onPressed: () => _showRejectDialog(j),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 20),
                color: AppColors.secondary,
                onPressed: () => context.push('/journeys/details', extra: j.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
