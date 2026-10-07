import 'dart:math';

/// A discrete forward radar / camera ADAS telemetry sample.
class RadarSample {
  final DateTime timestamp;
  final double distanceToLeadMeters;
  final double ownSpeedKmph;
  final double leadSpeedKmph;

  const RadarSample({
    required this.timestamp,
    required this.distanceToLeadMeters,
    required this.ownSpeedKmph,
    required this.leadSpeedKmph,
  });

  /// Time headway in seconds (distance / speed).
  double get timeHeadwaySeconds {
    final speedMps = ownSpeedKmph / 3.6;
    if (speedMps <= 1.0) return 99.0; // Stationary / walking pace
    return distanceToLeadMeters / speedMps;
  }

  /// Time-to-collision (TTC) in seconds if approaching faster than lead vehicle.
  double? get timeToCollisionSeconds {
    final closingSpeedMps = (ownSpeedKmph - leadSpeedKmph) / 3.6;
    if (closingSpeedMps <= 0.1) return null; // Not closing in
    return distanceToLeadMeters / closingSpeedMps;
  }
}

/// Severity classification of a tailgating or collision warning.
enum AdasEventSeverity {
  warning,
  critical,
}

/// An identified tailgating or close-following incident.
class AdasHeadwayEvent {
  final DateTime timestamp;
  final double durationSeconds;
  final double minHeadwaySeconds;
  final double? minTtcSeconds;
  final AdasEventSeverity severity;

  const AdasHeadwayEvent({
    required this.timestamp,
    required this.durationSeconds,
    required this.minHeadwaySeconds,
    this.minTtcSeconds,
    required this.severity,
  });
}

/// Consolidated audit of driver forward collision prevention and following distance.
class AdasSafetyAudit {
  final double averageHeadwaySeconds;
  final double minObservedHeadwaySeconds;
  final int tailgatingEventsCount;
  final int forwardCollisionWarningCount;
  final double tailgatingDurationTotalSeconds;
  final double adasSafetyScore; // 0 (extreme hazard) to 100 (flawless)
  final bool isHighCollisionRisk;
  final String safetyAdvisory;

  const AdasSafetyAudit({
    required this.averageHeadwaySeconds,
    required this.minObservedHeadwaySeconds,
    required this.tailgatingEventsCount,
    required this.forwardCollisionWarningCount,
    required this.tailgatingDurationTotalSeconds,
    required this.adasSafetyScore,
    required this.isHighCollisionRisk,
    required this.safetyAdvisory,
  });
}

/// Enterprise ADAS Forward Collision & Tailgating Profiler Engine.
class AdasSafetyService {
  const AdasSafetyService();

  /// Analyzes ADAS forward sensor telemetry and computes following distance compliance.
  AdasSafetyAudit evaluateAdasTelemetry(List<RadarSample> samples) {
    if (samples.isEmpty) {
      return const AdasSafetyAudit(
        averageHeadwaySeconds: 99.0,
        minObservedHeadwaySeconds: 99.0,
        tailgatingEventsCount: 0,
        forwardCollisionWarningCount: 0,
        tailgatingDurationTotalSeconds: 0.0,
        adasSafetyScore: 100.0,
        isHighCollisionRisk: false,
        safetyAdvisory: 'NOMINAL: No forward traffic proximity recorded.',
      );
    }

    double headwaySum = 0.0;
    int validCount = 0;
    double minHeadway = 99.0;
    int fcwCount = 0;
    int tailgatingEvents = 0;
    double tailgatingSeconds = 0.0;

    for (int i = 0; i < samples.length; i++) {
      final s = samples[i];
      if (s.ownSpeedKmph > 20.0) {
        final hw = s.timeHeadwaySeconds;
        headwaySum += hw;
        validCount++;
        if (hw < minHeadway) minHeadway = hw;

        // Tailgating condition: time headway < 1.5 seconds at speed
        if (hw < 1.5) {
          tailgatingEvents++;
          tailgatingSeconds += 1.0; // 1-second sample step
        }

        // Forward collision warning: TTC < 2.0 seconds while closing fast
        final ttc = s.timeToCollisionSeconds;
        if (ttc != null && ttc < 2.0) {
          fcwCount++;
        }
      }
    }

    final effectiveCount = max(1, validCount);
    final avgHeadway = headwaySum / effectiveCount;

    // Safety score calculation: 100 base, penalized by tailgating & FCWs
    double score = 100.0;
    score -= (tailgatingSeconds * 1.5);
    score -= (fcwCount * 12.0);
    final clampedScore = score.clamp(0.0, 100.0);

    final isHighRisk = clampedScore < 60.0 || fcwCount >= 2;

    String advisory;
    if (isHighRisk) {
      advisory = 'HIGH COLLISION RISK: Severe tailgating and forward collision warnings recorded.';
    } else if (clampedScore < 85.0) {
      advisory = 'CAUTION: Following distance occasionally below safe 2.0s statutory margin.';
    } else {
      advisory = 'EXCELLENT: Driver maintains optimal safe following distance and defensive cushion.';
    }

    return AdasSafetyAudit(
      averageHeadwaySeconds: double.parse(avgHeadway.toStringAsFixed(1)),
      minObservedHeadwaySeconds: double.parse(minHeadway.toStringAsFixed(1)),
      tailgatingEventsCount: tailgatingEvents,
      forwardCollisionWarningCount: fcwCount,
      tailgatingDurationTotalSeconds: double.parse(tailgatingSeconds.toStringAsFixed(1)),
      adasSafetyScore: double.parse(clampedScore.toStringAsFixed(1)),
      isHighCollisionRisk: isHighRisk,
      safetyAdvisory: advisory,
    );
  }
}
