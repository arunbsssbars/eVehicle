/// Vulnerable road user collision threat level (UNECE R151).
enum VruThreatLevel {
  clearNoHazard,
  vruDetectedAdvisory, // Level 1: Yellow optical indicator (VRU within detection zone)
  imminentCollisionAlert, // Level 2: Red acoustic/haptic emergency (Turning conflict)
}

/// Category of detected vulnerable road user.
enum VruTargetType {
  none,
  pedestrian,
  cyclistBicycle,
  electricScooter,
}

/// Instantaneous Doppler radar telemetry from nearside blind spot sensor.
class BlindSpotRadarTelemetry {
  final bool targetDetected;
  final VruTargetType targetType;
  final double lateralDistanceMeters;  // Distance from vehicle side (0.5m to 4.5m)
  final double longitudinalDistanceMeters; // Distance along vehicle length (-2m to 25m)
  final double relativeSpeedMps;       // Relative approach velocity in m/s
  final bool turnSignalActive;         // Vehicle turn indicator active toward curbside
  final double steeringAngleDeg;       // Wheel turned toward blind spot

  const BlindSpotRadarTelemetry({
    required this.targetDetected,
    required this.targetType,
    required this.lateralDistanceMeters,
    required this.longitudinalDistanceMeters,
    required this.relativeSpeedMps,
    required this.turnSignalActive,
    required this.steeringAngleDeg,
  });
}

/// Diagnostic evaluation of blind spot VRU threat.
class VruBlindSpotAudit {
  final VruThreatLevel threatLevel;
  final VruTargetType targetType;
  final double timeToCollisionSeconds;
  final String warningMessage;
  final bool emergencyBrakeInterventionRequired;

  const VruBlindSpotAudit({
    required this.threatLevel,
    required this.targetType,
    required this.timeToCollisionSeconds,
    required this.warningMessage,
    required this.emergencyBrakeInterventionRequired,
  });
}

/// Service evaluating lateral Doppler radar telemetry to protect cyclists and pedestrians.
class VruBlindSpotService {
  const VruBlindSpotService();

  /// Evaluates blind spot radar targets according to UNECE R151 BSIS specifications.
  VruBlindSpotAudit evaluateBlindSpot(BlindSpotRadarTelemetry telemetry) {
    if (!telemetry.targetDetected || telemetry.targetType == VruTargetType.none) {
      return const VruBlindSpotAudit(
        threatLevel: VruThreatLevel.clearNoHazard,
        targetType: VruTargetType.none,
        timeToCollisionSeconds: 99.0,
        warningMessage: 'BLIND SPOT CLEAR: Zero vulnerable road users detected in turn corridor.',
        emergencyBrakeInterventionRequired: false,
      );
    }

    // Time to collision approximation: Longitudinal distance divided by relative approach speed
    double ttc = 99.0;
    if (telemetry.relativeSpeedMps > 0.5) {
      ttc = (telemetry.longitudinalDistanceMeters.abs() / telemetry.relativeSpeedMps).clamp(0.1, 99.0);
    } else {
      // Lateral close proximity
      ttc = (telemetry.lateralDistanceMeters / 1.5).clamp(0.5, 99.0);
    }

    final bool isTurningIntent = telemetry.turnSignalActive || telemetry.steeringAngleDeg > 8.0;

    VruThreatLevel level;
    String message;
    bool emergencyBrake = false;

    if (isTurningIntent && (ttc <= 2.2 || telemetry.lateralDistanceMeters <= 1.2)) {
      level = VruThreatLevel.imminentCollisionAlert;
      emergencyBrake = true;
      message = 'IMMINENT VRU COLLISION! ${telemetry.targetType.name.toUpperCase()} in turn radius (TTC: ${ttc.toStringAsFixed(1)}s). Abort turn!';
    } else {
      level = VruThreatLevel.vruDetectedAdvisory;
      emergencyBrake = false;
      message = '${telemetry.targetType.name.toUpperCase()} DETECTED in nearside blind spot corridor (${telemetry.lateralDistanceMeters.toStringAsFixed(1)}m lateral). Check mirrors before turning.';
    }

    return VruBlindSpotAudit(
      threatLevel: level,
      targetType: telemetry.targetType,
      timeToCollisionSeconds: double.parse(ttc.toStringAsFixed(1)),
      warningMessage: message,
      emergencyBrakeInterventionRequired: emergencyBrake,
    );
  }
}
