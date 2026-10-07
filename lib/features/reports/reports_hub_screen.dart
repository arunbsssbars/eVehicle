import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/providers/vehicle_provider.dart';
import '../../core/widgets/usage_quota_card.dart';
import '../../core/services/ad_service.dart';
import '../../core/storage/local_database.dart';
import '../../core/models/journey.dart';

class ReportsHubScreen extends ConsumerWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleState = ref.watch(vehicleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports & Audit Registers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
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
                'Official Reports Hub',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Generate and export official compliance registers, log books, and fuel audits.',
                style: TextStyle(fontSize: 13, color: AppColors.secondary),
              ),
              const SizedBox(height: 14),

              // Free Tier Quota Indicator (Hidden for Pro / Enterprise)
              const UsageQuotaCard(),
              const SizedBox(height: 10),

              // Featured Report: Monthly Vehicle Log Book
              InkWell(
                onTap: () => context.push('/reports/monthly-log-book'),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Vehicle Log Book',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Standard Government Register format with signatures & certification.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Available Registers & Analytics',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              _buildReportCard(
                context,
                title: 'Daily Journey Log',
                subtitle:
                    'Chronological list of all daily official vehicle dispatches.',
                icon: Icons.today_outlined,
                iconColor: AppColors.primary,
                onTap: () => context.go('/journeys'),
              ),
              const SizedBox(height: 10),

              _buildReportCard(
                context,
                title: 'Vehicle-wise Distance & Utilization',
                subtitle:
                    'Detailed breakdown of KM traveled, idle time, and targets across fleet.',
                icon: Icons.directions_car_outlined,
                iconColor: AppColors.primaryContainer,
                onTap: () => context.push('/fleet-intelligence'),
              ),
              const SizedBox(height: 10),

              _buildReportCard(
                context,
                title: 'Fuel Expenditure & Economy Audit',
                subtitle:
                    'Fuel fill history, station receipts, and calculated KM/L averages.',
                icon: Icons.local_gas_station_outlined,
                iconColor: AppColors.warning,
                onTap: () {
                  if (vehicleState.vehicles.isNotEmpty) {
                    ref
                        .read(vehicleProvider.notifier)
                        .selectVehicle(vehicleState.vehicles.first);
                    context.push('/vehicles/details');
                  }
                },
              ),
              const SizedBox(height: 10),

              _buildReportCard(
                context,
                title: 'Service & Maintenance Register',
                subtitle:
                    'Parts replaced, service invoices, upcoming milestone alerts.',
                icon: Icons.build_outlined,
                iconColor: AppColors.tertiary,
                onTap: () {
                  if (vehicleState.vehicles.isNotEmpty) {
                    ref
                        .read(vehicleProvider.notifier)
                        .selectVehicle(vehicleState.vehicles.first);
                    context.push('/vehicles/details');
                  }
                },
              ),
              const SizedBox(height: 10),

              _buildReportCard(
                context,
                title: 'Compliance & Document Expiry Report',
                subtitle:
                    'Status of RC, Insurance, PUC, and Road Fitness certificates.',
                icon: Icons.verified_user_outlined,
                iconColor: AppColors.error,
                onTap: () => context.go('/vehicles'),
              ),
              const SizedBox(height: 10),

              _buildReportCard(
                context,
                title: 'Tax Deduction & Mileage Ledger',
                subtitle:
                    'Audit breakdown of Business vs. Personal trips with out-of-pocket expenses.',
                icon: Icons.calculate_outlined,
                iconColor: AppColors.success,
                onTap: () => _showTaxLedgerSheet(context),
              ),
              const SizedBox(height: 16),

              // Non-intrusive bottom sponsor banner for Free Tier
              const AdBannerWidget(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.secondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showTaxLedgerSheet(BuildContext context) {
    final journeys = LocalDatabase.instance.journeys;
    final businessKm = journeys
        .where((j) => j.tripCategory == TripCategory.business)
        .fold(0.0, (sum, j) => sum + j.calculatedDistance);
    final personalKm = journeys
        .where((j) => j.tripCategory == TripCategory.personal)
        .fold(0.0, (sum, j) => sum + j.calculatedDistance);
    final totalExpense = journeys.fold(0.0, (sum, j) => sum + (j.expenseAmount ?? 0.0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (c, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calculate_rounded, color: AppColors.success, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Tax & Mileage Ledger',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Comprehensive trip classification & out-of-pocket expense ledger for official audits and personal tax deduction filing.',
                style: TextStyle(fontSize: 12, color: AppColors.secondary),
              ),
              const SizedBox(height: 16),
              // Stats Summary Row
              Row(
                children: [
                  Expanded(
                    child: _statCard('Business KM', businessKm.toStringAsFixed(1), AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statCard('Personal KM', personalKm.toStringAsFixed(1), AppColors.warning),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statCard('Total Expense', '₹${totalExpense.toStringAsFixed(0)}', AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Classified Trip Breakdown',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              for (final j in journeys)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        j.tripCategory == TripCategory.business
                            ? Icons.business_center
                            : j.tripCategory == TripCategory.personal
                                ? Icons.person
                                : Icons.directions_bus,
                        size: 20,
                        color: j.tripCategory == TripCategory.business
                            ? AppColors.primary
                            : j.tripCategory == TripCategory.personal
                                ? AppColors.warning
                                : AppColors.secondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${j.startLocation} → ${j.destination.isEmpty ? "In Progress" : j.destination}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${j.tripCategory.label} • ${j.calculatedDistance.toStringAsFixed(1)} KM • ${j.vehicleRegistration}',
                              style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                      if (j.expenseAmount != null && j.expenseAmount! > 0)
                        Text(
                          '₹${j.expenseAmount!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF166534),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
