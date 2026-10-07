import 'package:flutter/material.dart';
import '../models/emergency_broadcast_message.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Dismissible / Actionable banner for displaying emergency fleet alerts to drivers
class EmergencyBroadcastBanner extends StatelessWidget {
  final EmergencyBroadcastMessage message;
  final bool isAcknowledged;
  final VoidCallback? onAcknowledge;

  const EmergencyBroadcastBanner({
    super.key,
    required this.message,
    required this.isAcknowledged,
    this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(message.priority.colorValue);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Icon(
                message.priority == BroadcastPriority.critical
                    ? Icons.warning_rounded
                    : Icons.notifications_active_outlined,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  message.priority.shortLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Message Body
          Text(
            message.body,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.onSurface,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Issued by: ${message.issuedBy}',
                  style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isAcknowledged && onAcknowledge != null)
                ElevatedButton(
                  onPressed: onAcknowledge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: AppColors.surfaceWhite,
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Acknowledge', style: TextStyle(fontSize: 11)),
                )
              else if (isAcknowledged)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Acknowledged',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
