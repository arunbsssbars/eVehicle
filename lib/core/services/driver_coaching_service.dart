import 'dart:math';

/// Telematics driving event types.
enum TelematicsEventType {
  harshAcceleration,
  harshBraking,
  severeCornering,
  speeding,
  excessiveIdling,
}

/// A specific driving event recorded during a journey.
class DriverTelemetryEvent {
  final TelematicsEventType type;
  final DateTime timestamp;
  final double severity; // 0.0 to 1.0
  final String locationNote;

  const DriverTelemetryEvent({
    required this.type,
    required this.timestamp,
    required this.severity,
    this.locationNote = '',
  });
}

/// Coaching recommendation tip for the driver.
class CoachingTip {
  final String title;
  final String description;
  final String iconCode;
  final bool isPriority;

  const CoachingTip({
    required this.title,
    required this.description,
    required this.iconCode,
    this.isPriority = false,
  });
}

/// Comprehensive driving habit evaluation report.
class DriverHabitReport {
  final String driverId;
  final String driverName;
  final double score; // 0 to 100
  final String grade; // S, A, B, C, D
  final int harshBrakingCount;
  final int harshAccelCount;
  final int severeCorneringCount;
  final int speedingCount;
  final int idlingMinutes;
  final double fuelEfficiencyImpactPercent;
  final List<CoachingTip> tips;

  const DriverHabitReport({
    required this.driverId,
    required this.driverName,
    required this.score,
    required this.grade,
    required this.harshBrakingCount,
    required this.harshAccelCount,
    required this.severeCorneringCount,
    required this.speedingCount,
    required this.idlingMinutes,
    required this.fuelEfficiencyImpactPercent,
    required this.tips,
  });
}

/// Autonomous Fleet AI Driver Coaching & Telematics Habit Scoring Engine.
class DriverCoachingService {
  const DriverCoachingService();

  /// Calculates driving habit report and constructive coaching tips.
  DriverHabitReport evaluateDriverHabits({
    required String driverId,
    required String driverName,
    required List<DriverTelemetryEvent> events,
    required int totalJourneyMinutes,
    int totalIdlingMinutes = 0,
  }) {
    int harshBraking = 0;
    int harshAccel = 0;
    int severeCornering = 0;
    int speeding = 0;

    for (final event in events) {
      switch (event.type) {
        case TelematicsEventType.harshBraking:
          harshBraking++;
          break;
        case TelematicsEventType.harshAcceleration:
          harshAccel++;
          break;
        case TelematicsEventType.severeCornering:
          severeCornering++;
          break;
        case TelematicsEventType.speeding:
          speeding++;
          break;
        case TelematicsEventType.excessiveIdling:
          // Included in totalIdlingMinutes
          break;
      }
    }

    // Deductions calculation
    double penalty = 0.0;
    penalty += harshBraking * 3.0;
    penalty += harshAccel * 2.5;
    penalty += severeCornering * 3.5;
    penalty += speeding * 4.0;

    // Idling penalty beyond 10 allowable minutes
    if (totalIdlingMinutes > 10) {
      final excessIdling = totalIdlingMinutes - 10;
      penalty += (excessIdling / 5.0) * 1.0;
    }

    final double score = max(0.0, min(100.0, 100.0 - penalty));

    final String grade;
    if (score >= 95.0) {
      grade = 'S';
    } else if (score >= 85.0) {
      grade = 'A';
    } else if (score >= 75.0) {
      grade = 'B';
    } else if (score >= 65.0) {
      grade = 'C';
    } else {
      grade = 'D';
    }

    // Estimated fuel wasted due to aggressive driving & excess idling
    final double fuelPenaltyPercent = min(25.0, (harshAccel * 1.8) + (speeding * 2.2) + (totalIdlingMinutes * 0.15));

    final List<CoachingTip> tips = [];
    if (harshBraking > 2) {
      tips.add(const CoachingTip(
        title: 'Increase Following Distance',
        description: 'Anticipate traffic stops early to reduce brake pad wear and passenger discomfort.',
        iconCode: 'brake',
        isPriority: true,
      ));
    }
    if (harshAccel > 2) {
      tips.add(const CoachingTip(
        title: 'Smooth Throttle Application',
        description: 'Progressive acceleration saves up to 15% in fleet fuel consumption.',
        iconCode: 'throttle',
        isPriority: false,
      ));
    }
    if (speeding > 0) {
      tips.add(const CoachingTip(
        title: 'Adhere to Highway Speed Envelopes',
        description: 'Maintaining speed limits preserves vehicle warranty and eliminates safety citations.',
        iconCode: 'speed',
        isPriority: true,
      ));
    }
    if (severeCornering > 1) {
      tips.add(const CoachingTip(
        title: 'Gentle Cornering Speeds',
        description: 'Slow down prior to corner entry to maintain lateral vehicle stability.',
        iconCode: 'corner',
        isPriority: false,
      ));
    }
    if (totalIdlingMinutes > 15) {
      tips.add(const CoachingTip(
        title: 'Eliminate Unnecessary Engine Idling',
        description: 'Switch off ignition when parked longer than 2 minutes.',
        iconCode: 'idle',
        isPriority: false,
      ));
    }

    if (tips.isEmpty) {
      tips.add(const CoachingTip(
        title: 'Exemplary Driving Profile',
        description: 'Smooth, defensive, and highly fuel-efficient operation maintained.',
        iconCode: 'star',
        isPriority: false,
      ));
    }

    return DriverHabitReport(
      driverId: driverId,
      driverName: driverName,
      score: double.parse(score.toStringAsFixed(1)),
      grade: grade,
      harshBrakingCount: harshBraking,
      harshAccelCount: harshAccel,
      severeCorneringCount: severeCornering,
      speedingCount: speeding,
      idlingMinutes: totalIdlingMinutes,
      fuelEfficiencyImpactPercent: double.parse(fuelPenaltyPercent.toStringAsFixed(1)),
      tips: tips,
    );
  }
}
