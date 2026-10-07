import 'package:flutter/material.dart';
import '../services/axle_load_leveler_service.dart';

/// Card showing ECAS air bellow pressures, axle weight distribution, and 5th-wheel slide notch.
class AxleLoadLevelerCard extends StatelessWidget {
  final AxleBalanceAudit audit;
  final int currentSlideNotch;
  final VoidCallback? onAdjustSlide;

  const AxleLoadLevelerCard({
    super.key,
    required this.audit,
    required this.currentSlideNotch,
    this.onAdjustSlide,
  });

  Color _getStatusColor(SuspensionBalanceStatus status) {
    switch (status) {
      case SuspensionBalanceStatus.driveAxleOverloaded:
      case SuspensionBalanceStatus.trailerBogieOverloaded:
        return Colors.red.shade700;
      case SuspensionBalanceStatus.dockLevelingActive:
        return Colors.blue.shade700;
      case SuspensionBalanceStatus.balancedOptimal:
        return Colors.teal.shade700;
    }
  }

  String _getStatusTitle(SuspensionBalanceStatus status) {
    switch (status) {
      case SuspensionBalanceStatus.driveAxleOverloaded:
        return 'DRIVE OVERWEIGHT';
      case SuspensionBalanceStatus.trailerBogieOverloaded:
        return 'TRAILER OVERWEIGHT';
      case SuspensionBalanceStatus.dockLevelingActive:
        return 'RAMP LEVELING';
      case SuspensionBalanceStatus.balancedOptimal:
        return 'BALANCED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(audit.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: audit.rebalancingRequired ? statusColor : theme.dividerColor.withValues(alpha: 0.2),
          width: audit.rebalancingRequired ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.scale_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Axle Load & 5th-Wheel Leveler',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getStatusTitle(audit.status),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    context,
                    'Drive Axle',
                    '${(audit.estimatedDriveAxleKg / 1000).toStringAsFixed(1)} t',
                    Icons.directions_bus_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Trailer Axles',
                    '${(audit.estimatedTrailerAxleKg / 1000).toStringAsFixed(1)} t',
                    Icons.rv_hookup_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Slide Position',
                    'Notch $currentSlideNotch',
                    Icons.tune_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              audit.statusSummary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (audit.rebalancingRequired && onAdjustSlide != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: statusColor,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onAdjustSlide,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text(
                    'Slide 5th Wheel ${audit.recommendedSlideAdjustmentNotches > 0 ? "+${audit.recommendedSlideAdjustmentNotches}" : audit.recommendedSlideAdjustmentNotches} Notches',
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
