import 'dart:math';

/// Classification of road pavement and surface condition.
enum RoadQualityClass {
  smoothHighway,
  acceptableCity,
  roughDegraded,
  severePotholes,
}

/// High-frequency vertical acceleration sample from phone/vehicle IMU.
class VibrationSample {
  final DateTime timestamp;
  final double zAxisAccelG; // Vertical G (nominal is 1.0G stationary)
  final double speedKmph;
  final double latitude;
  final double longitude;

  const VibrationSample({
    required this.timestamp,
    required this.zAxisAccelG,
    required this.speedKmph,
    required this.latitude,
    required this.longitude,
  });
}

/// Recorded high-g pothole strike with geocoding for hazard mapping.
class PotholeStrike {
  final DateTime timestamp;
  final double peakZForce;
  final double speedKmph;
  final double latitude;
  final double longitude;

  const PotholeStrike({
    required this.timestamp,
    required this.peakZForce,
    required this.speedKmph,
    required this.latitude,
    required this.longitude,
  });
}

/// Consolidated audit of road surface roughness and suspension wear impact.
class RoadRoughnessAudit {
  final double roughnessIndex; // 0.0 (mirror smooth) to 10.0 (extreme off-road/cratered)
  final RoadQualityClass qualityClass;
  final int potholeStrikeCount;
  final double averageSpeedKmph;
  final double suspensionWearPenaltyPercent;
  final List<PotholeStrike> severeStrikes;
  final String surfaceSummary;

  const RoadRoughnessAudit({
    required this.roughnessIndex,
    required this.qualityClass,
    required this.potholeStrikeCount,
    required this.averageSpeedKmph,
    required this.suspensionWearPenaltyPercent,
    required this.severeStrikes,
    required this.surfaceSummary,
  });
}

/// Enterprise Automated Road Condition & Pothole Impact Profiler.
class RoadVibrationProfilerService {
  const RoadVibrationProfilerService();

  /// Analyzes vertical Z-axis IMU vibration telemetry to extract roughness and pothole strikes.
  RoadRoughnessAudit analyzeVibrations(List<VibrationSample> samples) {
    if (samples.isEmpty) {
      return const RoadRoughnessAudit(
        roughnessIndex: 0.0,
        qualityClass: RoadQualityClass.smoothHighway,
        potholeStrikeCount: 0,
        averageSpeedKmph: 0.0,
        suspensionWearPenaltyPercent: 0.0,
        severeStrikes: [],
        surfaceSummary: 'NO TELEMETRY: No road vibration samples recorded.',
      );
    }

    double totalDeviation = 0.0;
    double speedSum = 0.0;
    int movingCount = 0;
    final List<PotholeStrike> strikes = [];

    for (int i = 0; i < samples.length; i++) {
      final s = samples[i];
      if (s.speedKmph > 5.0) {
        speedSum += s.speedKmph;
        movingCount++;

        // Deviation from static 1.0G gravity
        final deviation = (s.zAxisAccelG - 1.0).abs();
        totalDeviation += deviation;

        // Pothole strike threshold: vertical spike >= 1.8G or negative drop <= 0.2G
        if (s.zAxisAccelG >= 1.85 || s.zAxisAccelG <= 0.15) {
          strikes.add(PotholeStrike(
            timestamp: s.timestamp,
            peakZForce: double.parse(s.zAxisAccelG.toStringAsFixed(2)),
            speedKmph: s.speedKmph,
            latitude: s.latitude,
            longitude: s.longitude,
          ));
        }
      }
    }

    final validCount = max(1, movingCount);
    final avgSpeed = speedSum / validCount;
    // Mean absolute deviation scaled to 0-10 index
    final meanDeviation = totalDeviation / validCount;
    final rawIndex = (meanDeviation * 12.0) + (strikes.length * 0.4);
    final roughnessIndex = rawIndex.clamp(0.0, 10.0);

    RoadQualityClass quality;
    if (strikes.length >= 5 || roughnessIndex >= 6.5) {
      quality = RoadQualityClass.severePotholes;
    } else if (roughnessIndex >= 4.0) {
      quality = RoadQualityClass.roughDegraded;
    } else if (roughnessIndex >= 2.0) {
      quality = RoadQualityClass.acceptableCity;
    } else {
      quality = RoadQualityClass.smoothHighway;
    }

    final suspensionPenalty = (roughnessIndex * 2.5) + (strikes.length * 1.5);
    final clampedPenalty = suspensionPenalty.clamp(0.0, 50.0);

    String summary;
    switch (quality) {
      case RoadQualityClass.smoothHighway:
        summary = 'Pristine asphalt: Minimal vibration stress on chassis.';
        break;
      case RoadQualityClass.acceptableCity:
        summary = 'Standard urban corridor: Minor road surface undulations.';
        break;
      case RoadQualityClass.roughDegraded:
        summary = 'Degraded pavement: Elevated road chatter; slow down.';
        break;
      case RoadQualityClass.severePotholes:
        summary = 'Hazardous potholes: Extreme vertical impulses recorded.';
        break;
    }

    return RoadRoughnessAudit(
      roughnessIndex: double.parse(roughnessIndex.toStringAsFixed(1)),
      qualityClass: quality,
      potholeStrikeCount: strikes.length,
      averageSpeedKmph: double.parse(avgSpeed.toStringAsFixed(1)),
      suspensionWearPenaltyPercent: double.parse(clampedPenalty.toStringAsFixed(1)),
      severeStrikes: strikes,
      surfaceSummary: summary,
    );
  }
}
