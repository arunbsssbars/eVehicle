import '../models/journey.dart';

/// Driver fatigue compliance status according to Hours of Service regulations
enum HosStatus {
  compliant('Compliant', 'SAFE', 0xFF16A34A),
  warning('Break Approaching', 'WARN', 0xFFEA580C),
  violation('Fatigue Limit Exceeded', 'LIMIT', 0xFFDC2626);

  final String label;
  final String shortLabel;
  final int colorValue;
  const HosStatus(this.label, this.shortLabel, this.colorValue);
}

/// Comprehensive Hours of Service (HOS) shift calculation result
class HosShiftReport {
  final String driverId;
  final DateTime shiftDate;
  final Duration totalDrivingTime;
  final Duration currentContinuousDrivingTime;
  final Duration totalRestTime;
  final Duration remainingContinuousDriveTime;
  final Duration remainingDailyDriveTime;
  final HosStatus status;
  final List<String> warnings;

  const HosShiftReport({
    required this.driverId,
    required this.shiftDate,
    required this.totalDrivingTime,
    required this.currentContinuousDrivingTime,
    required this.totalRestTime,
    required this.remainingContinuousDriveTime,
    required this.remainingDailyDriveTime,
    required this.status,
    required this.warnings,
  });
}

/// Engine enforcing statutory driving limits (max 4.5h continuous, max 9.0h daily shift)
class HoursOfServiceEngine {
  /// Maximum continuous driving allowed before a mandatory 30-min break
  static const Duration maxContinuousDriving = Duration(minutes: 270); // 4.5 hours

  /// Maximum cumulative driving time allowed in a single 24-hour shift
  static const Duration maxDailyDriving = Duration(minutes: 540); // 9.0 hours

  /// Minimum rest gap required to reset continuous driving counter
  static const Duration minRestBreak = Duration(minutes: 30);

  /// Evaluate HOS compliance for a driver based on their logged journeys on a given date
  static HosShiftReport evaluateDriverShift({
    required String driverId,
    required DateTime date,
    required List<Journey> journeys,
  }) {
    // Filter journeys for this driver and day
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final shiftJourneys = journeys.where((j) {
      if (j.driverId != driverId) return false;
      return j.journeyDate.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          j.journeyDate.isBefore(dayEnd.add(const Duration(seconds: 1)));
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (shiftJourneys.isEmpty) {
      return HosShiftReport(
        driverId: driverId,
        shiftDate: date,
        totalDrivingTime: Duration.zero,
        currentContinuousDrivingTime: Duration.zero,
        totalRestTime: Duration.zero,
        remainingContinuousDriveTime: maxContinuousDriving,
        remainingDailyDriveTime: maxDailyDriving,
        status: HosStatus.compliant,
        warnings: const [],
      );
    }

    Duration totalDriving = Duration.zero;
    Duration currentContinuous = Duration.zero;
    Duration totalRest = Duration.zero;
    DateTime? lastTripEnd;
    final warnings = <String>[];

    for (final j in shiftJourneys) {
      final tripEnd = j.endTime ?? j.startTime.add(const Duration(hours: 1));
      final tripDuration = tripEnd.difference(j.startTime);
      final effectiveDuration = tripDuration > Duration.zero ? tripDuration : const Duration(minutes: 1);

      if (lastTripEnd != null) {
        final restGap = j.startTime.difference(lastTripEnd);
        if (restGap > Duration.zero) {
          totalRest += restGap;
          if (restGap >= minRestBreak) {
            // Full break taken -> resets continuous driving counter
            currentContinuous = Duration.zero;
          }
        }
      }

      totalDriving += effectiveDuration;
      currentContinuous += effectiveDuration;
      lastTripEnd = tripEnd;
    }

    // Determine status
    HosStatus status = HosStatus.compliant;

    if (currentContinuous > maxContinuousDriving) {
      status = HosStatus.violation;
      warnings.add(
        'Continuous driving (${_formatHours(currentContinuous)}) exceeds mandatory 4.5h limit without rest',
      );
    } else if (currentContinuous >= const Duration(minutes: 240)) {
      status = HosStatus.warning;
      warnings.add('Mandatory 30-min break required within 30 minutes');
    }

    if (totalDriving > maxDailyDriving) {
      status = HosStatus.violation;
      warnings.add(
        'Daily driving limit (${_formatHours(totalDriving)}) exceeds maximum allowed 9.0h shift limit',
      );
    }

    final remContinuous = currentContinuous < maxContinuousDriving
        ? (maxContinuousDriving - currentContinuous)
        : Duration.zero;

    final remDaily = totalDriving < maxDailyDriving
        ? (maxDailyDriving - totalDriving)
        : Duration.zero;

    return HosShiftReport(
      driverId: driverId,
      shiftDate: date,
      totalDrivingTime: totalDriving,
      currentContinuousDrivingTime: currentContinuous,
      totalRestTime: totalRest,
      remainingContinuousDriveTime: remContinuous,
      remainingDailyDriveTime: remDaily,
      status: status,
      warnings: warnings,
    );
  }

  static String _formatHours(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60);
    return '${hours}h ${mins}m';
  }
}
