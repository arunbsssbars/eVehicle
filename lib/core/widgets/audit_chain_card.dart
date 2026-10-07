import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/rbac_guard_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Card displaying immutable audit ledger integrity and recent chained events
class AuditChainCard extends StatelessWidget {
  final List<AuditLogEntry> auditChain;
  final VoidCallback? onVerifyLedgerPressed;

  const AuditChainCard({
    super.key,
    required this.auditChain,
    this.onVerifyLedgerPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isChainValid = RbacGuardService.verifyChainIntegrity(auditChain);
    final statusColor = isChainValid ? AppColors.success : AppColors.error;
    final statusText = isChainValid ? 'Ledger Verified (Tamper-Proof)' : 'Tamper Alert: Hash Mismatch!';

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
                  Icons.lock_clock_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cryptographic Audit Ledger',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Immutable Merkle Chain • SHA-256',
                      style: TextStyle(fontSize: 11, color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onVerifyLedgerPressed != null)
                TextButton(
                  onPressed: onVerifyLedgerPressed,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(44, 32),
                  ),
                  child: const Text('Verify', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Integrity Pill Banner
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
                  isChainValid ? Icons.check_circle_outline_rounded : Icons.gpp_bad_rounded,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${auditChain.length} blocks',
                  style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Recent Entries
          if (auditChain.isNotEmpty) ...[
            const Text(
              'Recent Chained Entries',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary),
            ),
            const SizedBox(height: 6),
            ...auditChain.reversed.take(3).map((entry) => _buildEntryRow(entry)),
          ],
        ],
      ),
    );
  }

  Widget _buildEntryRow(AuditLogEntry entry) {
    final timeFormat = DateFormat('dd MMM HH:mm:ss');
    final shortHash = entry.currentHash.length >= 10
        ? '${entry.currentHash.substring(0, 6)}...${entry.currentHash.substring(entry.currentHash.length - 4)}'
        : entry.currentHash;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.action} • ${entry.actorId}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  timeFormat.format(entry.timestamp),
                  style: const TextStyle(fontSize: 9, color: AppColors.secondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              shortHash,
              style: const TextStyle(
                fontSize: 9,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
