import 'package:flutter/material.dart';
import '../services/gps_spoof_detector_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Card showing GPS telemetry authenticity and spoofing risk audit
class TelemetrySecurityCard extends StatelessWidget {
  final GpsAuditResult auditResult;
  final VoidCallback? onInspectTelemetry;

  const TelemetrySecurityCard({
    super.key,
    required this.auditResult,
    this.onInspectTelemetry,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = auditResult.isSuspicious ? AppColors.error : AppColors.success;
    final statusText = auditResult.isSuspicious
        ? 'MOCK LOCATION SUSPECTED'
        : 'GENUINE HARDWARE GPS VERIFIED';

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
                  auditResult.isSuspicious ? Icons.satellite_alt_outlined : Icons.verified_user_rounded,
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
                      'Telemetry & GPS Authenticity',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Anti-Spoofing Guard • Teleportation Audit',
                      style: TextStyle(fontSize: 11, color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onInspectTelemetry != null)
                TextButton(
                  onPressed: onInspectTelemetry,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(44, 32),
                  ),
                  child: const Text('Inspect', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Status Banner
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
                  auditResult.isSuspicious ? Icons.gpp_maybe_rounded : Icons.check_circle_rounded,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Risk: ${auditResult.anomalyScore.toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Flagged reasons list
          if (auditResult.flaggedReasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...auditResult.flaggedReasons.map((reason) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_right_rounded, size: 14, color: AppColors.error),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(fontSize: 10, color: AppColors.error),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
