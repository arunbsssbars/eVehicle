/// Alignment status of commercial vehicle steer axle wheels.
enum SteerAxleAlignmentStatus {
  withinTolerances,
  abnormalScuffAlignmentDrift,
  criticalSteerWanderBlowoutRisk,
}

/// Dynamic kinematic telemetry from optical steer angle, wheel speed, and suspension laser height sensors.
class SteerAxleAlignmentTelemetry {
  final double toeInDegrees; // Nominal: +0.05° to +0.15° total toe-in. Excessive > +0.35° or toe-out < -0.10°.
  final double camberDegrees; // Nominal: 0.0° to +0.5°. Severe tilt < -0.8° or > +1.2°.
  final double casterDegrees; // Nominal: +3.5° to +5.5°. Caster split > 0.8° causes highway pull.
  final double dynamicSideSlipMetresPerKm; // Tire scrub: Nominal < 2.5 m/km. Critical > 6.0 m/km.
  final double shoulderTireTreadDepthMm;
  final double centerTireTreadDepthMm;

  const SteerAxleAlignmentTelemetry({
    required this.toeInDegrees,
    required this.camberDegrees,
    required this.casterDegrees,
    required this.dynamicSideSlipMetresPerKm,
    required this.shoulderTireTreadDepthMm,
    required this.centerTireTreadDepthMm,
  });

  /// Tire feathering / asymmetric shoulder scrub wear delta.
  double get shoulderScrubDeltaMm => (shoulderTireTreadDepthMm - centerTireTreadDepthMm).abs();
}

/// Steer axle alignment and dynamic stability diagnosis result.
class SteerAxleAlignmentAuditResult {
  final String vehicleId;
  final SteerAxleAlignmentStatus status;
  final double toeInDegrees;
  final double camberDegrees;
  final double dynamicSideSlipMPerKm;
  final double scrubDeltaMm;
  final String alignmentAdvisory;

  const SteerAxleAlignmentAuditResult({
    required this.vehicleId,
    required this.status,
    required this.toeInDegrees,
    required this.camberDegrees,
    required this.dynamicSideSlipMPerKm,
    required this.scrubDeltaMm,
    required this.alignmentAdvisory,
  });

  bool get isAlignedCorrectly => status == SteerAxleAlignmentStatus.withinTolerances;
  bool get isSevereWanderRisk => status == SteerAxleAlignmentStatus.criticalSteerWanderBlowoutRisk;
}

/// Evaluates dynamic toe, camber, tie-rod play, and tire scrub to eliminate wandering and high-speed shoulder blowouts.
class SteerAxleAlignmentService {
  const SteerAxleAlignmentService();

  SteerAxleAlignmentAuditResult auditAlignment({
    required String vehicleId,
    required SteerAxleAlignmentTelemetry telemetry,
  }) {
    final scrub = telemetry.shoulderScrubDeltaMm;

    // 1. Critical steer wander, excessive side-slip or dangerous toe divergence
    if (telemetry.dynamicSideSlipMetresPerKm >= 6.0 ||
        telemetry.toeInDegrees < -0.20 ||
        telemetry.toeInDegrees > 0.50 ||
        telemetry.camberDegrees < -1.0 ||
        telemetry.camberDegrees > 1.5 ||
        scrub >= 3.5) {
      return SteerAxleAlignmentAuditResult(
        vehicleId: vehicleId,
        status: SteerAxleAlignmentStatus.criticalSteerWanderBlowoutRisk,
        toeInDegrees: telemetry.toeInDegrees,
        camberDegrees: telemetry.camberDegrees,
        dynamicSideSlipMPerKm: telemetry.dynamicSideSlipMetresPerKm,
        scrubDeltaMm: scrub,
        alignmentAdvisory:
            'CRITICAL HAZARD: Excessive dynamic side-slip (${telemetry.dynamicSideSlipMetresPerKm.toStringAsFixed(1)} m/km) or toe divergence! Severe tire scrub creates highway wander and steer blowout risk. Immediate 3-axle laser alignment required.',
      );
    }

    // 2. Warning: Side slip > 3.0 m/km or shoulder feathering developing
    if (telemetry.dynamicSideSlipMetresPerKm >= 3.0 ||
        telemetry.toeInDegrees < 0.0 ||
        telemetry.toeInDegrees > 0.25 ||
        scrub >= 1.8) {
      return SteerAxleAlignmentAuditResult(
        vehicleId: vehicleId,
        status: SteerAxleAlignmentStatus.abnormalScuffAlignmentDrift,
        toeInDegrees: telemetry.toeInDegrees,
        camberDegrees: telemetry.camberDegrees,
        dynamicSideSlipMPerKm: telemetry.dynamicSideSlipMetresPerKm,
        scrubDeltaMm: scrub,
        alignmentAdvisory:
            'WARNING: Steer axle toe/camber drift detected (Toe: ${telemetry.toeInDegrees.toStringAsFixed(2)}°). Inspect tie-rod drag link and kingpin bushings to halt accelerated tread scuffing.',
      );
    }

    // 3. Normal alignment
    return SteerAxleAlignmentAuditResult(
      vehicleId: vehicleId,
      status: SteerAxleAlignmentStatus.withinTolerances,
      toeInDegrees: telemetry.toeInDegrees,
      camberDegrees: telemetry.camberDegrees,
      dynamicSideSlipMPerKm: telemetry.dynamicSideSlipMetresPerKm,
      scrubDeltaMm: scrub,
      alignmentAdvisory:
          'NOMINAL: Steer axle toe-in, camber, and dynamic side-slip are perfectly centered within factory OEM specifications.',
    );
  }
}
