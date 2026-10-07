import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/models/journey.dart';
import '../../core/widgets/app_buttons.dart';

class JourneySuccessScreen extends StatelessWidget {
  final Journey? journey;

  const JourneySuccessScreen({super.key, this.journey});

  @override
  Widget build(BuildContext context) {
    final j = journey;

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.marginMobile,
            vertical: 24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success Icon Badge
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.successContainer,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 56,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Journey Submitted',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your official vehicle log record has been recorded securely and forwarded for approval.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Summary Card
              if (j != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      _buildRow('Official Journey ID', j.id),
                      const Divider(height: 16),
                      _buildRow('Vehicle', '${j.vehicleRegistration} (${j.vehicleModel})'),
                      const Divider(height: 16),
                      _buildRow('Total Official Distance',
                          '${j.calculatedDistance.toStringAsFixed(1)} KM',
                          isBold: true),
                      const Divider(height: 16),
                      _buildRow('Date & Time',
                          DateFormat('dd MMM yyyy, hh:mm a').format(j.startTime)),
                    ],
                  ),
                ),
              const Spacer(),

              // Actions
              PrimaryButton(
                label: 'Submit for Official Approval',
                icon: Icons.send_rounded,
                onPressed: () {
                  if (j != null) {
                    context.pushReplacement('/journeys/details', extra: j.id);
                  } else {
                    context.go('/journeys');
                  }
                },
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'View Full Journey Record',
                icon: Icons.receipt_long_rounded,
                onPressed: () {
                  if (j != null) {
                    context.pushReplacement('/journeys/details', extra: j.id);
                  } else {
                    context.go('/journeys');
                  }
                },
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Back to Dashboard',
                icon: Icons.home_outlined,
                onPressed: () => context.go('/dashboard'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.secondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? AppColors.primary : AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
