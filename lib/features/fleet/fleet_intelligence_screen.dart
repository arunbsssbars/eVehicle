import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/providers/journey_provider.dart';
import '../../core/providers/vehicle_provider.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/services/carbon_emissions_service.dart';
import '../../core/services/driver_safety_service.dart';
import '../../core/widgets/green_fleet_card.dart';
import '../../core/widgets/driver_leaderboard_card.dart';

class FleetIntelligenceScreen extends ConsumerWidget {
  const FleetIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleState = ref.watch(vehicleProvider);
    final journeyState = ref.watch(journeyProvider);
    final appState = ref.watch(appStateProvider);

    final vehicles = vehicleState.vehicles;
    final totalFleetKm =
        vehicles.fold(0.0, (sum, v) => sum + v.currentOdometer);
    final serviceDueCount = vehicleState.serviceDueCount;
    final expiringDocsCount = vehicleState.expiringDocsCount;

    // Detect anomalies from journeys
    final journeysWithDiscrepancy =
        journeyState.journeys.where((j) => j.hasDistanceDiscrepancy).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fleet Intelligence & Audit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.marginMobile,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fleet Operations Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Department-wide telemetry, utilization analytics, and fraud anomaly detection.',
                style: TextStyle(fontSize: 13, color: AppColors.secondary),
              ),
              const SizedBox(height: 16),

              // KPI Stats Grid (2x2)
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Fleet Vehicles',
                      value: '${vehicles.length}',
                      subtitle: '100% Assigned',
                      icon: Icons.local_shipping_outlined,
                      iconColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Total Fleet Distance',
                      value: NumberFormat('#,##0').format(totalFleetKm),
                      unit: 'KM',
                      subtitle: 'Cumulative log',
                      icon: Icons.speed,
                      iconColor: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Maintenance Due',
                      value: '$serviceDueCount',
                      subtitle: serviceDueCount > 0
                          ? 'Action required'
                          : 'All serviced',
                      icon: Icons.build_circle_outlined,
                      iconColor: AppColors.warning,
                      iconBgColor: AppColors.warningContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Document Alerts',
                      value: '$expiringDocsCount',
                      subtitle: 'RC / Insurance / PUC',
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppColors.error,
                      iconBgColor: AppColors.errorContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Green Fleet & Carbon Emissions Analytics Card
              GreenFleetCard(
                totalDistanceKm: totalFleetKm,
                totalEmissionsKg: CarbonEmissionsService.calculateFleetEmissionsKg(
                  journeys: journeyState.journeys,
                  vehicles: vehicles,
                ),
                carbonSavedKg: CarbonEmissionsService.calculateCarbonSavedKg(
                  journeys: journeyState.journeys,
                  vehicles: vehicles,
                ),
              ),
              const SizedBox(height: 18),

              // Driver Safety & Performance Leaderboard Card
              DriverLeaderboardCard(
                leaderboard: DriverSafetyService.rankDrivers(
                  journeys: journeyState.journeys,
                  vehicles: vehicles,
                ),
              ),
              const SizedBox(height: 24),

              // Monthly Distance Trend Chart (fl_chart)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Monthly Utilization Trend',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Distance (KM)',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 160,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 6000,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final months = [
                                    'Apr',
                                    'May',
                                    'Jun',
                                    'Jul',
                                    'Aug'
                                  ];
                                  final idx = val.toInt();
                                  if (idx >= 0 && idx < months.length) {
                                    return Text(months[idx],
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (val, meta) {
                                  if (val == 0 ||
                                      val == 3000 ||
                                      val == 6000) {
                                    return Text('${(val / 1000).toInt()}k',
                                        style: const TextStyle(fontSize: 9));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            _makeBarGroup(0, 3800),
                            _makeBarGroup(1, 4200),
                            _makeBarGroup(2, 3950),
                            _makeBarGroup(3, 4600),
                            _makeBarGroup(4, 4850, isCurrent: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Fraud / Anomaly Detection Section (PRD Section 14)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Automated Anomaly & Fraud Audit',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildAuditRuleItem(
                      title: 'Odometer Rollback Guard',
                      description:
                          'Flags and blocks submissions where new opening odometer < previous accepted vehicle reading.',
                      status: 'ACTIVE & ENFORCING',
                      statusColor: AppColors.success,
                    ),
                    const Divider(height: 16),
                    _buildAuditRuleItem(
                      title: 'GPS Distance Cross-Verification',
                      description:
                          'Compares odometer delta against recorded GPS trajectory with discrepancy alerts.',
                      status: '${journeysWithDiscrepancy.length} Flags Detected',
                      statusColor: journeysWithDiscrepancy.isEmpty
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const Divider(height: 16),
                    _buildAuditRuleItem(
                      title: 'Duplicate Trip Prevention',
                      description:
                          'Prevents concurrent or identical start times for the same assigned vehicle.',
                      status: 'PROTECTED',
                      statusColor: AppColors.success,
                    ),
                    const Divider(height: 16),
                    _buildAuditRuleItem(
                      title: 'Locked Record Tamper Proofing',
                      description:
                          'Approved and locked monthly records cannot be modified without Super Admin audit override.',
                      status: 'IMMUTABLE',
                      statusColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Audit Logs Preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Recent System Audit Trail',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${appState.auditLogs.length} events',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (appState.auditLogs.isEmpty)
                      const Text('No audit events logged yet.')
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: appState.auditLogs.take(5).length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, i) {
                          final a = appState.auditLogs[i];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.history,
                                    size: 14, color: AppColors.secondary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${a.action} (${a.entityId})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    if (a.reason != null)
                                      Text(
                                        a.reason!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    Text(
                                      '${a.userName} • ${DateFormat('dd MMM, hh:mm a').format(a.timestamp)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, {bool isCurrent = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isCurrent ? AppColors.primary : AppColors.primaryFixedDim,
          width: 24,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildAuditRuleItem({
    required String title,
    required String description,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
