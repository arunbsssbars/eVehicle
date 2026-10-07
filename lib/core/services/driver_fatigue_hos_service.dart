import 'dart:math';

/// Hours of Service (HOS) duty status states.
enum DutyStatus {
  offDuty,
  sleeperBerth,
  driving,
  onDutyNotDriving,
}

/// A specific duty log period.
class DutyPeriod {
  final DutyStatus status;
  final DateTime startTime;
  final DateTime endTime;

  const DutyPeriod({
    required this.status,
    required this.startTime,
    required this.endTime,
  });

  int get durationMinutes => endTime.difference(startTime).inMinutes;
}

/// Comprehensive fatigue and HOS audit result.
class FatigueAuditResult {
  final String driverId;
  final String driverName;
  final int totalDrivingMinutes; // Max 660 (11h)
  final int totalDutyMinutes; // Max 840 (14h)
  final int continuousDrivingMinutes; // Max 480 (8h without break)
  final int minutesUntilMandatoryBreak;
  final double fatigueRiskScore; // 0 (Well rested) to 100 (Extreme Danger)
  final bool isHosViolated;
  final bool isInCircadianHighRiskWindow;
  final List<String> warnings;

  const FatigueAuditResult({
    required this.driverId,
    required this.driverName,
    required this.totalDrivingMinutes,
    required this.totalDutyMinutes,
    required this.continuousDrivingMinutes,
    required this.minutesUntilMandatoryBreak,
    required this.fatigueRiskScore,
    required this.isHosViolated,
    required this.isInCircadianHighRiskWindow,
    required this.warnings,
  });

  bool get requiresImmediateStop => isHosViolated || fatigueRiskScore >= 75.0;
}

/// Fleet Driver Fatigue, Circadian Rhythm & Hours of Service (HOS) Compliance Sentinel.
class DriverFatigueHosService {
  const DriverFatigueHosService();

  static const int maxDailyDrivingMinutes = 660; // 11 hours
  static const int maxShiftDutyMinutes = 840; // 14 hours
  static const int maxContinuousDrivingBeforeBreak = 480; // 8 hours (30-min break required)

  /// Audits driver shift duty logs for fatigue risks and statutory HOS limits.
  FatigueAuditResult evaluateDriverShift({
    required String driverId,
    required String driverName,
    required List<DutyPeriod> periods,
    DateTime? currentTime,
  }) {
    int totalDriving = 0;
    int totalDuty = 0;
    int continuousDriving = 0;
    final List<String> warnings = [];

    // Sort periods chronologically
    final sorted = List<DutyPeriod>.from(periods)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final p in sorted) {
      final duration = p.durationMinutes;

      if (p.status == DutyStatus.driving) {
        totalDriving += duration;
        continuousDriving += duration;
        totalDuty += duration;
      } else if (p.status == DutyStatus.onDutyNotDriving) {
        totalDuty += duration;
      } else if (p.status == DutyStatus.offDuty || p.status == DutyStatus.sleeperBerth) {
        // A break >= 30 minutes resets continuous driving counter
        if (duration >= 30) {
          continuousDriving = 0;
        }
      }
    }

    final now = currentTime ?? (sorted.isNotEmpty ? sorted.last.endTime : DateTime.now());
    final currentHour = now.hour;

    // Circadian high risk window: 02:00 - 05:59 (Primary biological nadir)
    final bool isCircadianPeak = currentHour >= 2 && currentHour < 6;
    if (isCircadianPeak) {
      warnings.add('Circadian Biological Nadir: Maximum drowsiness window (02:00 - 06:00).');
    }

    bool hosViolated = false;
    if (totalDriving > maxDailyDrivingMinutes) {
      hosViolated = true;
      warnings.add('HOS Violation: Exceeded 11-hour statutory driving limit (${(totalDriving / 60.0).toStringAsFixed(1)}h logged).');
    }
    if (totalDuty > maxShiftDutyMinutes) {
      hosViolated = true;
      warnings.add('HOS Violation: Exceeded 14-hour maximum on-duty shift window.');
    }
    if (continuousDriving > maxContinuousDrivingBeforeBreak) {
      hosViolated = true;
      warnings.add('HOS Violation: Continuous driving exceeded 8 hours without 30-min rest break.');
    }

    final minutesToBreak = max(0, maxContinuousDrivingBeforeBreak - continuousDriving);

    // Calculate Fatigue Risk Score (0-100)
    double fatigueScore = 10.0; // baseline
    fatigueScore += (totalDriving / maxDailyDrivingMinutes) * 45.0;
    fatigueScore += (continuousDriving / maxContinuousDrivingBeforeBreak) * 25.0;

    if (isCircadianPeak) {
      fatigueScore += 20.0;
    } else if (currentHour >= 14 && currentHour < 16) {
      // Secondary post-lunch dip
      fatigueScore += 8.0;
    }

    fatigueScore = fatigueScore.clamp(0.0, 100.0);

    return FatigueAuditResult(
      driverId: driverId,
      driverName: driverName,
      totalDrivingMinutes: totalDriving,
      totalDutyMinutes: totalDuty,
      continuousDrivingMinutes: continuousDriving,
      minutesUntilMandatoryBreak: minutesToBreak,
      fatigueRiskScore: double.parse(fatigueScore.toStringAsFixed(1)),
      isHosViolated: hosViolated,
      isInCircadianHighRiskWindow: isCircadianPeak,
      warnings: warnings,
    );
  }
}
