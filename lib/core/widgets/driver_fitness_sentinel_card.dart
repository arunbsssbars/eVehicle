import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/driver_fitness_sentinel_service.dart';

/// Responsive, AQIL-compliant Driver Pre-Trip Fitness Sentinel Card.
class DriverFitnessSentinelCard extends StatelessWidget {
  final FitnessEvaluationResult result;
  final VoidCallback? onAuthorizeDispatch;
  final VoidCallback? onAssignReliefDriver;

  const DriverFitnessSentinelCard({
    super.key,
    required this.result,
    this.onAuthorizeDispatch,
    this.onAssignReliefDriver,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusBadge;
    switch (result.status) {
      case FitnessStatus.fitForDuty:
        statusColor = AppColors.success;
        statusBadge = 'FIT FOR DUTY';
        break;
      case FitnessStatus.requiresSecondaryReview:
        statusColor = AppColors.warning;
        statusBadge = 'SUPERVISOR REVIEW';
        break;
      case FitnessStatus.unfitForDuty:
        statusColor = AppColors.error;
        statusBadge = 'GROUNDED / UNFIT';
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
                  result.isDispatchApproved ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
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
                      result.driverName,
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
                      'ID: ${result.driverId} • ${result.clearanceCertificateId}',
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
                  statusBadge,
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

          // Recommendation Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: result.isDispatchApproved
                  ? AppColors.surfaceContainerLow
                  : AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              result.recommendation,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: result.isDispatchApproved ? AppColors.onSurface : AppColors.error,
              ),
            ),
          ),

          if (result.disqualifyingFactors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Disqualifying Factors (${result.disqualifyingFactors.length}):',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            ...result.disqualifyingFactors.take(2).map((factor) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_rounded, size: 14, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          factor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          const SizedBox(height: 14),

          // Action Buttons
          if (result.isDispatchApproved && onAuthorizeDispatch != null)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onAuthorizeDispatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.key_rounded, size: 18),
                label: const Text(
                  'Authorize Ignition / Key Dispatch',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            )
          else if (!result.isDispatchApproved && onAssignReliefDriver != null)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: onAssignReliefDriver,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  foregroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text(
                  'Assign Certified Relief Driver',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
