import 'dart:math';

/// Classification of accident/collision severity.
enum CrashSeverity {
  none,
  minorFenderBender,
  moderateCollision,
  severeImpact,
  rollover,
}

/// A discrete 3-axis accelerometer and speed sample from the device/vehicle IMU.
class GForceSample {
  final DateTime timestamp;
  final double accelX; // Lateral (G)
  final double accelY; // Longitudinal (G)
  final double accelZ; // Vertical (G)
  final double speedKmph;

  const GForceSample({
    required this.timestamp,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.speedKmph,
  });

  /// Vector magnitude of total acceleration in G-force.
  double get totalG => sqrt((accelX * accelX) + (accelY * accelY) + (accelZ * accelZ));
}

/// Black-box forensic reconstruction report following an impact event.
class CrashReconstructionReport {
  final bool hasCrashOccurred;
  final CrashSeverity severity;
  final double peakGForce;
  final double deltaVKmph;
  final double preImpactSpeedKmph;
  final double postImpactSpeedKmph;
  final bool isRollover;
  final double impactVectorDegrees; // 0 = rear, 90 = right, 180 = frontal, 270 = left
  final bool emergencyDispatchRecommended;
  final DateTime? incidentTimestamp;

  const CrashReconstructionReport({
    required this.hasCrashOccurred,
    required this.severity,
    required this.peakGForce,
    required this.deltaVKmph,
    required this.preImpactSpeedKmph,
    required this.postImpactSpeedKmph,
    required this.isRollover,
    required this.impactVectorDegrees,
    required this.emergencyDispatchRecommended,
    this.incidentTimestamp,
  });
}

/// Enterprise Accident & Harsh Collision Impact Reconstruction Engine.
class CrashReconstructionService {
  const CrashReconstructionService();

  /// Analyzes IMU high-rate telemetry samples to detect and reconstruct accident forensics.
  CrashReconstructionReport analyzeImpactTelemetry(List<GForceSample> samples) {
    if (samples.length < 2) {
      return const CrashReconstructionReport(
        hasCrashOccurred: false,
        severity: CrashSeverity.none,
        peakGForce: 0.0,
        deltaVKmph: 0.0,
        preImpactSpeedKmph: 0.0,
        postImpactSpeedKmph: 0.0,
        isRollover: false,
        impactVectorDegrees: 0.0,
        emergencyDispatchRecommended: false,
      );
    }

    double maxG = 0.0;
    int peakIndex = -1;

    for (int i = 0; i < samples.length; i++) {
      final g = samples[i].totalG;
      if (g > maxG) {
        maxG = g;
        peakIndex = i;
      }
    }

    // Thresholds: Normal driving rarely exceeds 1.2G; potholes ~2.0G transient; impacts >= 3.0G
    if (maxG < 2.8) {
      return CrashReconstructionReport(
        hasCrashOccurred: false,
        severity: CrashSeverity.none,
        peakGForce: double.parse(maxG.toStringAsFixed(2)),
        deltaVKmph: 0.0,
        preImpactSpeedKmph: samples.first.speedKmph,
        postImpactSpeedKmph: samples.last.speedKmph,
        isRollover: false,
        impactVectorDegrees: 0.0,
        emergencyDispatchRecommended: false,
      );
    }

    final peakSample = samples[peakIndex];
    // Pre-impact speed taken slightly before peak
    final preSpeed = samples[max(0, peakIndex - 3)].speedKmph;
    // Post-impact speed taken after peak
    final postSpeed = samples[min(samples.length - 1, peakIndex + 3)].speedKmph;
    final deltaV = (preSpeed - postSpeed).abs();

    // Check for rollover: lateral inversion or sustained inverted vertical Z < -0.5G
    bool rollover = false;
    for (int i = peakIndex; i < min(samples.length, peakIndex + 10); i++) {
      if (samples[i].accelZ < -0.4 || samples[i].accelX.abs() > 2.5) {
        rollover = true;
        break;
      }
    }

    // Vector calculation (bearing of impact vector)
    double angleRad = atan2(peakSample.accelX, peakSample.accelY);
    double bearingDeg = (angleRad * 180.0 / pi);
    if (bearingDeg < 0) bearingDeg += 360.0;

    CrashSeverity severity;
    if (rollover) {
      severity = CrashSeverity.rollover;
    } else if (maxG >= 6.5 || deltaV >= 35.0) {
      severity = CrashSeverity.severeImpact;
    } else if (maxG >= 4.0 || deltaV >= 18.0) {
      severity = CrashSeverity.moderateCollision;
    } else {
      severity = CrashSeverity.minorFenderBender;
    }

    final dispatchNeeded = severity == CrashSeverity.severeImpact || severity == CrashSeverity.rollover;

    return CrashReconstructionReport(
      hasCrashOccurred: true,
      severity: severity,
      peakGForce: double.parse(maxG.toStringAsFixed(2)),
      deltaVKmph: double.parse(deltaV.toStringAsFixed(1)),
      preImpactSpeedKmph: double.parse(preSpeed.toStringAsFixed(1)),
      postImpactSpeedKmph: double.parse(postSpeed.toStringAsFixed(1)),
      isRollover: rollover,
      impactVectorDegrees: double.parse(bearingDeg.toStringAsFixed(1)),
      emergencyDispatchRecommended: dispatchNeeded,
      incidentTimestamp: peakSample.timestamp,
    );
  }
}
