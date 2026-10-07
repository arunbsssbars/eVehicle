import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/geofence_breach_engine_service.dart';

/// Responsive, AQIL-compliant Geofence Breach & Curfew Alarm Sentinel card.
class GeofenceBreachEngineCard extends StatelessWidget {
  final GeofenceAuditResult audit;
  final String registrationNumber;
  final VoidCallback? onAcknowledgeAlerts;

  const GeofenceBreachEngineCard({
    super.key,
    required this.audit,
    required this.registrationNumber,
    this.onAcknowledgeAlerts,
  });

  bool get _hasBreach =>
      audit.isBreachingRestrictedZone ||
      audit.isCurfewViolated ||
      audit.activeAlerts.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final statusColor = _hasBreach ? AppColors.error : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasBreach ? AppColors.error.withValues(alpha: 0.5) : AppColors.borderSubtle,
        ),
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
                  _hasBreach ? Icons.fmd_bad_rounded : Icons.shield_rounded,
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
                      registrationNumber,
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
                      'Geofence & Curfew Sentinel • ${_hasBreach ? "${audit.activeAlerts.length} Active Alarms" : "Normal Perimeter"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: _hasBreach ? AppColors.error : AppColors.secondary,
                        fontWeight: _hasBreach ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Status Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusPill(
                label: audit.isInsideDepot ? 'Inside Depot' : 'Outside Depot',
                isSuccess: audit.isInsideDepot,
              ),
              _buildStatusPill(
                label: audit.isInsideOperatingArea ? 'In Authorized Bounds' : 'Operating Out-of-Bounds',
                isSuccess: audit.isInsideOperatingArea,
              ),
              if (audit.isBreachingRestrictedZone)
                _buildStatusPill(
                  label: 'Restricted Zone Incursion',
                  isSuccess: false,
                ),
              if (audit.isCurfewViolated)
                _buildStatusPill(
                  label: 'Curfew Breached',
                  isSuccess: false,
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Active Breach Alerts list
          if (audit.activeAlerts.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: audit.activeAlerts.map((alert) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 15,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${alert.zoneName}: ${alert.reason}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.error,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (onAcknowledgeAlerts != null && _hasBreach) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: onAcknowledgeAlerts,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Acknowledge & Notify Dispatch Supervisor',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusPill({required String label, required bool isSuccess}) {
    final color = isSuccess ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
