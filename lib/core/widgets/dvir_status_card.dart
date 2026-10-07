import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dvir_inspection.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Card showing latest DVIR inspection status, defects, and vehicle roadworthiness
class DvirStatusCard extends StatelessWidget {
  final DvirInspection? latestInspection;
  final VoidCallback onStartInspection;

  const DvirStatusCard({
    super.key,
    this.latestInspection,
    required this.onStartInspection,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, HH:mm');
    final isSafe = latestInspection?.isSafeToOperate ?? true;
    final statusColor = isSafe ? AppColors.success : AppColors.error;
    final statusText = isSafe ? 'ROADWORTHY & VERIFIED' : 'GROUNDED: CRITICAL DEFECT';

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
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSafe ? Icons.fact_check_outlined : Icons.dangerous_outlined,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Vehicle Inspection (DVIR)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Pre-Trip Safety • Brake & Tire Check',
                      style: TextStyle(fontSize: 11, color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onStartInspection,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(44, 32),
                ),
                child: const Text('Inspect', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Status Banner
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
                  isSafe ? Icons.check_circle_rounded : Icons.report_problem_rounded,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (latestInspection != null)
                  Text(
                    dateFormat.format(latestInspection!.timestamp),
                    style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                  ),
              ],
            ),
          ),

          // Defects list if any
          if (latestInspection != null && latestInspection!.hasDefects) ...[
            const SizedBox(height: 10),
            Text(
              'Identified Defects (${latestInspection!.defects.length})',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary),
            ),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxChipWidth = (constraints.maxWidth - 8).clamp(100.0, double.infinity);
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: latestInspection!.defects.map((d) {
                    final color = Color(d.severity.colorValue);
                    return Container(
                      constraints: BoxConstraints(maxWidth: maxChipWidth),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.build_circle_outlined, size: 12, color: color),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${d.component}: ${d.description}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
