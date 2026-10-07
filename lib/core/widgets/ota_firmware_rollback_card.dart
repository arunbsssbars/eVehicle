import 'package:flutter/material.dart';
import '../services/ota_firmware_rollback_service.dart';

/// Card managing automotive dual-bank OTA firmware updates, A/B slot integrity, and watchdog rollback protection.
class OtaFirmwareRollbackCard extends StatelessWidget {
  final OtaRollbackAudit audit;
  final EcuPartitionState partition;
  final OtaCampaignPayload? payload;
  final VoidCallback? onExecuteFlash;
  final VoidCallback? onManualRollback;

  const OtaFirmwareRollbackCard({
    super.key,
    required this.audit,
    required this.partition,
    this.payload,
    this.onExecuteFlash,
    this.onManualRollback,
  });

  Color _getStatusColor() {
    switch (audit.stage) {
      case OtaUpdateStage.idleNoUpdatePending:
      case OtaUpdateStage.committedStable:
        return Colors.teal.shade700;
      case OtaUpdateStage.downloadingPayload:
      case OtaUpdateStage.stagedSlotInactiveVerifyingSha256:
        return Colors.amber.shade800;
      case OtaUpdateStage.rebootTestingSlotActive:
        return Colors.indigo.shade600;
      case OtaUpdateStage.rollbackTriggeredToPreviousSlot:
        return Colors.red.shade700;
    }
  }

  String _getStatusLabel() {
    switch (audit.stage) {
      case OtaUpdateStage.idleNoUpdatePending:
        return 'UP TO DATE';
      case OtaUpdateStage.downloadingPayload:
        return 'DOWNLOADING';
      case OtaUpdateStage.stagedSlotInactiveVerifyingSha256:
        return 'STAGED (SLOT B)';
      case OtaUpdateStage.rebootTestingSlotActive:
        return 'READY TO FLASH';
      case OtaUpdateStage.committedStable:
        return 'COMMITTED';
      case OtaUpdateStage.rollbackTriggeredToPreviousSlot:
        return 'ROLLBACK ACTIVE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor();
    final isRollback = audit.stage == OtaUpdateStage.rollbackTriggeredToPreviousSlot;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRollback ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: isRollback ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.system_update_alt_rounded,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    payload != null ? '${payload!.targetEcuName} Firmware OTA' : 'ECU Firmware Status',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getStatusLabel(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // A/B Partition Slot Visualizer
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    context,
                    'Active Slot',
                    partition.activeSlot,
                    Icons.storage_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Current Version',
                    partition.currentVersion,
                    Icons.tag_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Safe Fallback',
                    partition.fallbackSafeVersion,
                    Icons.restore_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Message and action feedback
            Text(
              audit.executionActionMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            if (audit.flashPreconditionsSatisfied && onExecuteFlash != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onExecuteFlash,
                  icon: const Icon(Icons.flash_on_rounded, size: 18),
                  label: Text(
                    'Install & Flash to ${partition.inactiveSlot}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ] else if (isRollback && onManualRollback != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: statusColor,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onManualRollback,
                  icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
                  label: const Text(
                    'Confirm Safe Slot Fallback',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Flexible(
      child: Column(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
