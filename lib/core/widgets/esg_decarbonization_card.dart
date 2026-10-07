import 'package:flutter/material.dart';
import '../services/esg_decarbonization_service.dart';

/// Card showing corporate ESG sustainability ratings, GHG Scope 1/2/3 breakdown, and carbon exposure cost.
class EsgDecarbonizationCard extends StatelessWidget {
  final EsgDecarbonizationScorecard scorecard;
  final FleetEnergyConsumptionTelemetry telemetry;
  final VoidCallback? onDownloadEsgAuditReport;

  const EsgDecarbonizationCard({
    super.key,
    required this.scorecard,
    required this.telemetry,
    this.onDownloadEsgAuditReport,
  });

  Color _getRatingColor() {
    switch (scorecard.ratingTier) {
      case EsgRatingTier.leaderNetZeroAligned:
        return Colors.green.shade700;
      case EsgRatingTier.transitionalCompliant:
        return Colors.teal.shade700;
      case EsgRatingTier.laggingHighEmissions:
        return Colors.amber.shade800;
      case EsgRatingTier.nonCompliantCarbonPenalty:
        return Colors.red.shade700;
    }
  }

  String _getRatingLabel() {
    switch (scorecard.ratingTier) {
      case EsgRatingTier.leaderNetZeroAligned:
        return 'NET-ZERO LEADER';
      case EsgRatingTier.transitionalCompliant:
        return 'TRANSITIONAL';
      case EsgRatingTier.laggingHighEmissions:
        return 'HIGH EMISSIONS';
      case EsgRatingTier.nonCompliantCarbonPenalty:
        return 'CARBON PENALTY';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getRatingColor();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                Icon(
                  Icons.eco_rounded,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Corporate ESG Decarbonization',
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
                    _getRatingLabel(),
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

            // Carbon Intensity Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Fleet Intensity (${telemetry.totalActiveFleetVehicles} Vehicles)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${scorecard.fleetAverageGramsCo2PerKm.toStringAsFixed(0)} g CO₂/km',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (scorecard.fleetAverageGramsCo2PerKm / 800.0).clamp(0.0, 1.0),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),

            // Scope 1, 2, 3 Breakdown Grid
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
                    'Scope 1 (Tailpipe)',
                    '${scorecard.scope1DirectCo2Tons.toStringAsFixed(1)} t',
                    Icons.local_gas_station_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Scope 2 (Grid)',
                    '${scorecard.scope2IndirectGridCo2Tons.toStringAsFixed(1)} t',
                    Icons.electric_bolt_rounded,
                  ),
                  _buildMetric(
                    context,
                    'Scope 3 (Logistics)',
                    '${scorecard.scope3ValueChainCo2Tons.toStringAsFixed(1)} t',
                    Icons.local_shipping_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Advisory Message
            Text(
              scorecard.sustainabilityAdvisory,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Key Lever: ${scorecard.keyDecarbonizationLever}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (onDownloadEsgAuditReport != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: onDownloadEsgAuditReport,
                  icon: const Icon(Icons.document_scanner_rounded, size: 18),
                  label: const Text(
                    'Export ISO 14064 ESG Audit Certificate',
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
