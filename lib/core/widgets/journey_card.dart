import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/journey.dart';
import '../theme/app_colors.dart';
import 'status_badge.dart';

/// A custom, vector-rendered car steering wheel icon for the driver affordance.
class SteeringWheelIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SteeringWheelIcon({
    super.key,
    this.size = 13,
    this.color = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SteeringWheelPainter(color: color),
    );
  }
}

class _SteeringWheelPainter extends CustomPainter {
  final Color color;
  const _SteeringWheelPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.15;

    final rimPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Outer rim
    canvas.drawCircle(center, radius - strokeWidth / 2, rimPaint);

    // Center hub
    final hubPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.30, hubPaint);

    // Three spokes: left, right, bottom
    final spokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.85
      ..strokeCap = StrokeCap.round;

    final hubOffset = radius * 0.28;
    final rimInner = radius - strokeWidth;

    // Left spoke
    canvas.drawLine(
      Offset(center.dx - hubOffset, center.dy),
      Offset(center.dx - rimInner, center.dy),
      spokePaint,
    );
    // Right spoke
    canvas.drawLine(
      Offset(center.dx + hubOffset, center.dy),
      Offset(center.dx + rimInner, center.dy),
      spokePaint,
    );
    // Bottom spoke
    canvas.drawLine(
      Offset(center.dx, center.dy + hubOffset),
      Offset(center.dx, center.dy + rimInner),
      spokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SteeringWheelPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A professionally designed, unified Journey Card representing an official
/// trip log. Features vehicle name placed between time and KM, route micro-timeline,
/// dedicated status indicator, full-width purpose text, and steering wheel driver icon.
class JourneyCard extends StatelessWidget {
  final Journey journey;
  final VoidCallback? onTap;
  final bool showDate;
  final bool showVehicle;
  final bool showOdometer;

  const JourneyCard({
    super.key,
    required this.journey,
    this.onTap,
    this.showDate = false,
    this.showVehicle = true,
    this.showOdometer = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDestinationEmpty = journey.destination.isEmpty;

    // Vehicle name to display between time and km
    final vehicleDisplayName = journey.vehicleModel.isNotEmpty
        ? journey.vehicleModel
        : (journey.vehicleRegistration.isNotEmpty
            ? journey.vehicleRegistration
            : 'Official Vehicle');

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap ?? () => context.push('/journeys/details', extra: journey.id),
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.03),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Row: Time (left) | Vehicle Name (between) | KM Badge (right)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: Time Pill (with optional date)
                  Flexible(
                    flex: showDate ? 6 : 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              showDate
                                  ? '${DateFormat('hh:mm a').format(journey.startTime)} • ${DateFormat('dd MMM').format(journey.journeyDate)}'
                                  : DateFormat('hh:mm a').format(journey.startTime),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Middle (In Between): Vehicle Name
                  Expanded(
                    flex: showDate ? 5 : 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.directions_car_rounded,
                            size: 11.5,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3.5),
                          Flexible(
                            child: Text(
                              vehicleDisplayName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Right: High-Contrast KM Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: AppColors.primaryFixedDim.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          journey.calculatedDistance.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(width: 2.5),
                        const Text(
                          'KM',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onPrimaryFixedVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 2. Route Micro-Timeline Section (Maximum width for Source & Destination)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Micro-Timeline
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Origin Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                journey.startLocation,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // Connecting track
                        Container(
                          margin: const EdgeInsets.only(left: 3.25),
                          width: 1.5,
                          height: 10,
                          color: AppColors.outlineVariant.withValues(alpha: 0.7),
                        ),

                        // Destination Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDestinationEmpty
                                      ? AppColors.warning
                                      : AppColors.error,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isDestinationEmpty ? 'In Progress' : journey.destination,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDestinationEmpty
                                      ? AppColors.primary
                                      : AppColors.onSurface,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Rightmost clickability indicator chevron
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ],
              ),

              // 3. Hairline Divider
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.surfaceContainerLow,
                ),
              ),

              // 4. Purpose of Travel (No prefix label for maximum space)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1.5),
                    child: Icon(
                      Icons.assignment_outlined,
                      size: 13,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      journey.purpose,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // 5. Driver, Odometer & Status Badge Row (Using full-width Wrap)
              const SizedBox(height: 7),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (journey.driverName.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SteeringWheelIcon(
                          size: 12.5,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          journey.driverName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  if (journey.driverName.isNotEmpty &&
                      showOdometer &&
                      journey.closingOdometer != null)
                    const Text(
                      '•',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.outline,
                      ),
                    ),
                  if (showOdometer && journey.closingOdometer != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.speed_rounded,
                          size: 12,
                          color: AppColors.outline,
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          '${journey.openingOdometer.toStringAsFixed(0)} → ${journey.closingOdometer!.toStringAsFixed(0)} KM',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  // Trip Category Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: journey.tripCategory == TripCategory.personal
                          ? AppColors.warningContainer.withValues(alpha: 0.4)
                          : journey.tripCategory == TripCategory.commute
                              ? AppColors.secondaryContainer.withValues(alpha: 0.4)
                              : AppColors.primaryFixed.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      journey.tripCategory.label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: journey.tripCategory == TripCategory.personal
                            ? const Color(0xFF9A3412)
                            : journey.tripCategory == TripCategory.commute
                                ? AppColors.secondary
                                : AppColors.primary,
                      ),
                    ),
                  ),
                  // Expense Tag
                  if (journey.expenseAmount != null && journey.expenseAmount! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.successContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_rounded, size: 10, color: Color(0xFF166534)),
                          const SizedBox(width: 2.5),
                          Text(
                            '₹${journey.expenseAmount!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ],
                      ),
                    ),
                  StatusBadge.fromJourneyStatus(journey.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
