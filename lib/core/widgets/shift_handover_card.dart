import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/shift_handover_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Card showing vehicle handover condition between incoming and outgoing drivers
class ShiftHandoverCard extends StatelessWidget {
  final ShiftHandoverRecord record;
  final VoidCallback? onAccept;
  final VoidCallback? onDispute;

  const ShiftHandoverCard({
    super.key,
    required this.record,
    this.onAccept,
    this.onDispute,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(record.status.colorValue);
    final dateFormat = DateFormat('dd MMM, HH:mm');

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
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_horizontal_circle_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shift Handover • ${record.vehicleRegistration}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'From: ${record.outgoingDriverName} → To: ${record.incomingDriverName}',
                      style: const TextStyle(fontSize: 11, color: AppColors.secondary),
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
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  record.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Condition Details
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Handover KM', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      Text(
                        '${record.odometerReading.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fuel Level', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      Text(
                        '${record.fuelLevelPercent}% Tank',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cleanliness', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFEAB308)),
                          const SizedBox(width: 2),
                          Text(
                            '${record.cleanlinessRating}/5',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Action row if pending
          if (record.status == HandoverStatus.pendingAcceptance && onAccept != null) ...[
            Row(
              children: [
                if (onDispute != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDispute,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(double.infinity, 36),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('Dispute', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surfaceWhite,
                      minimumSize: const Size(double.infinity, 36),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Accept Vehicle', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Handover logged on ${dateFormat.format(record.timestamp)}',
              style: const TextStyle(fontSize: 10, color: AppColors.secondary),
            ),
          ],
        ],
      ),
    );
  }
}
