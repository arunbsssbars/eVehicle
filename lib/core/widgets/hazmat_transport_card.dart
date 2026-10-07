import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/hazmat_transport_service.dart';

/// Responsive, AQIL-compliant Dangerous Goods & HAZMAT Emergency Response card.
class HazmatTransportCard extends StatelessWidget {
  final HazmatAuditResult audit;
  final VoidCallback? onDispatchEmergencySms;

  const HazmatTransportCard({
    super.key,
    required this.audit,
    this.onDispatchEmergencySms,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = audit.isDispatchAuthorized ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: audit.isDispatchAuthorized ? AppColors.borderSubtle : AppColors.error.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row with Hazard Diamond
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
                  Icons.warning_rounded,
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
                      '${audit.consignment.unNumber} • ${audit.consignment.properShippingName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ERG Guide #${audit.emergencyProtocol.ergGuideNumber} • Class ${audit.consignment.primaryClass.name.replaceFirst('class', '')} (PG ${audit.consignment.packingGroup})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ERG Evacuation Radius Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Initial Isolation Radius', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${audit.emergencyProtocol.initialIsolationRadiusMeters} meters',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.error,
                        ),
                      ),
                      Text('Day: ${audit.emergencyProtocol.downwindEvacuationDayMeters}m • Night: ${audit.emergencyProtocol.downwindEvacuationNightMeters}m', style: const TextStyle(fontSize: 9.5, color: AppColors.secondary)),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: AppColors.borderSubtle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Consignment Payload', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${audit.consignment.netQuantityKg.toStringAsFixed(0)} kg',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                      ),
                      Text(audit.isDispatchAuthorized ? 'Manifest Verified' : 'Compliance Hold', style: TextStyle(fontSize: 9.5, color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Spill & First-Responder Guidelines
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Action: ${audit.emergencyProtocol.immediateSpillAction}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.onSurface,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (onDispatchEmergencySms != null) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onDispatchEmergencySms,
                icon: const Icon(Icons.sos_rounded, size: 16),
                label: const Text(
                  'Transmit First-Responder ERG Manifest',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
