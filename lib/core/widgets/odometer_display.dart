import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class OdometerDisplay extends StatelessWidget {
  final double reading;
  final String label;
  final double? previousReading;
  final bool isProminent;
  final bool isCompact;
  final bool isSlim;
  final Color? backgroundColor;

  const OdometerDisplay({
    super.key,
    required this.reading,
    this.label = 'ODOMETER READING',
    this.previousReading,
    this.isProminent = false,
    this.isCompact = false,
    this.isSlim = false,
    this.backgroundColor,
  });

  bool get isRollback =>
      previousReading != null && reading < previousReading!;

  @override
  Widget build(BuildContext context) {
    final formattedNumber = NumberFormat('#,##0.0').format(reading);
    final wholeAndDec = formattedNumber.split('.');
    final rawDigits = wholeAndDec[0].replaceAll(',', '');
    final wholeDigits =
        rawDigits.length >= 6 ? rawDigits : rawDigits.padLeft(5, '0');
    final decDigit = wholeAndDec.length > 1 ? wholeAndDec[1] : '0';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
            (isCompact || isSlim) ? AppDimensions.radiusMd : AppDimensions.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isRollback
              ? [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)]
              : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
        ),
        boxShadow: [
          BoxShadow(
            color: isRollback
                ? AppColors.error.withValues(alpha: 0.15)
                : const Color(0xFF0F172A).withValues(alpha: 0.2),
            blurRadius: (isCompact || isSlim) ? 6 : 12,
            offset: Offset(0, (isCompact || isSlim) ? 2 : 4),
          ),
        ],
        border: Border.all(
          color: isRollback ? AppColors.error : const Color(0xFF334155),
          width: isRollback ? 1.5 : 1,
        ),
      ),
      padding: isSlim
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
          : (isCompact
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 7)
              : EdgeInsets.all(isProminent ? 14 : 12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with HUD style typography
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: isCompact ? 5 : 7,
                      height: isCompact ? 5 : 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRollback
                            ? AppColors.error
                            : const Color(0xFF38BDF8),
                        boxShadow: [
                          BoxShadow(
                            color: isRollback
                                ? AppColors.error
                                : const Color(0xFF38BDF8),
                            blurRadius: isCompact ? 3 : 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isCompact ? 5 : 8),
                    Expanded(
                      child: Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: isCompact ? 8.5 : 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: isCompact ? 0.6 : 1.2,
                          color: isRollback
                              ? AppColors.error
                              : const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSlim) ...[
                if (isRollback)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ROLLBACK ALERT',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  )
                else if (previousReading != null)
                  Text(
                    '+${(reading - previousReading!).toStringAsFixed(1)} KM',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF38BDF8),
                    ),
                  )
                else
                  const Text(
                    'Verified Baseline',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
              ] else if (isProminent && !isCompact) ...[
                if (isRollback)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'ROLLBACK ALERT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified,
                            size: 11, color: Color(0xFF38BDF8)),
                        SizedBox(width: 4),
                        Text(
                          'DIGITAL HUD',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ] else if (isRollback)
                Icon(Icons.warning_amber_rounded,
                    size: isCompact ? 11 : 14, color: AppColors.error),
            ],
          ),
          SizedBox(height: (isCompact || isSlim) ? 6 : 10),

          // Modern Digit Drums Row
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Drum Cluster Container
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 4 : (isSlim ? 6 : 7),
                        vertical: isCompact ? 3 : (isSlim ? 4 : 5)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF020617),
                      borderRadius:
                          BorderRadius.circular(isCompact ? 6 : (isSlim ? 8 : 9)),
                      border: Border.all(
                        color: isRollback
                            ? AppColors.error.withValues(alpha: 0.5)
                            : const Color(0xFF1E293B),
                        width: isCompact ? 1 : 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Whole KM Digits
                        for (int i = 0; i < wholeDigits.length; i++) ...[
                          _buildModernDigit(
                            wholeDigits[i],
                            isDecimal: false,
                            isRollback: isRollback,
                          ),
                          if (i < wholeDigits.length - 1)
                            SizedBox(width: isCompact ? 2 : (isSlim ? 3 : 3.5)),
                        ],

                        // Decimal Separator
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: isCompact ? 2.5 : 4),
                          width: isCompact ? 3 : 4,
                          height: isCompact ? 3 : 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRollback
                                ? AppColors.error
                                : const Color(0xFF38BDF8),
                            boxShadow: [
                              BoxShadow(
                                color: isRollback
                                    ? AppColors.error
                                    : const Color(0xFF38BDF8),
                                blurRadius: isCompact ? 2 : 4,
                              ),
                            ],
                          ),
                        ),

                        // Tenths / Decimal Drum
                        _buildModernDigit(
                          decDigit,
                          isDecimal: true,
                          isRollback: isRollback,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: isCompact ? 5 : (isSlim ? 7 : 8)),

                  // Unit Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: (isCompact || isSlim) ? 7 : 9,
                        vertical: (isCompact || isSlim) ? 5 : 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isRollback
                            ? [AppColors.error, const Color(0xFFB91C1C)]
                            : [
                                const Color(0xFF004AC6),
                                const Color(0xFF2563EB)
                              ],
                      ),
                      borderRadius:
                          BorderRadius.circular((isCompact || isSlim) ? 4 : 6),
                      boxShadow: [
                        BoxShadow(
                          color: (isRollback
                                  ? AppColors.error
                                  : const Color(0xFF004AC6))
                              .withValues(alpha: 0.4),
                          blurRadius: isCompact ? 3 : 6,
                          offset: Offset(0, isCompact ? 1 : 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'KM',
                      style: TextStyle(
                        fontSize: isCompact ? 10.5 : (isSlim ? 12.0 : 13.0),
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: isCompact ? 0.5 : 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!isSlim) ...[
            SizedBox(height: isCompact ? 5 : 8),

            // Footer Metrics / Comparison
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (previousReading != null)
                  Expanded(
                    child: Text(
                      'Last: ${NumberFormat('#,##0.0').format(previousReading)} KM',
                      style: TextStyle(
                        fontSize: isCompact ? 8.5 : 10.5,
                        fontWeight: FontWeight.w600,
                        color: isRollback
                            ? AppColors.error
                            : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      'Verified Baseline',
                      style: TextStyle(
                        fontSize: isCompact ? 8.5 : 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (previousReading != null && !isRollback) ...[
                  const SizedBox(width: 4),
                  Text(
                    '+${(reading - previousReading!).toStringAsFixed(1)} KM',
                    style: TextStyle(
                      fontSize: isCompact ? 8.5 : 10.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernDigit(
    String digit, {
    required bool isDecimal,
    required bool isRollback,
  }) {
    final double digitWidth =
        isCompact ? 16.5 : (isSlim ? 21.0 : (isProminent ? 24.0 : 20.0));
    final double digitHeight =
        isCompact ? 26.0 : (isSlim ? 32.0 : (isProminent ? 36.0 : 30.0));
    final double digitFontSize =
        isCompact ? 14.5 : (isSlim ? 18.0 : (isProminent ? 20.0 : 17.0));
    final double digitRadius = isCompact ? 3.5 : (isSlim ? 4.5 : 5.0);

    return Container(
      width: digitWidth,
      height: digitHeight,
      decoration: BoxDecoration(
        color: isDecimal
            ? (isRollback
                ? const Color(0xFF450A0A)
                : const Color(0xFF1E293B))
            : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(digitRadius),
        border: Border.all(
          color: isDecimal
              ? (isRollback
                  ? AppColors.error.withValues(alpha: 0.6)
                  : const Color(0xFF38BDF8).withValues(alpha: 0.5))
              : const Color(0xFF1E293B),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          digit,
          style: TextStyle(
            fontSize: digitFontSize,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: isRollback
                ? AppColors.error
                : (isDecimal
                    ? const Color(0xFF38BDF8)
                    : const Color(0xFFF8FAFC)),
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
