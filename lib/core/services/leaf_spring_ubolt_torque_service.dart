/// Structural condition of heavy vehicle suspension u-bolts, center pins, and axle spring seats.
enum LeafSpringUboltTorqueStatus {
  uboltClampedNominal,
  preloadRelaxationWarning,
  criticalCenterPinShearAxleWalkHazard,
}

/// Dynamic strain gauge and optical displacement telemetry measuring u-bolt nut clamping preload, spring pack fanning, and center pin alignment.
class LeafSpringUboltTelemetry {
  final double uboltClampingPreloadKiloNewtons; // Recommended tension: 85 - 110 kN. Loose < 55 kN.
  final double recommendedPreloadKiloNewtons;
  final double leafSpringFanningOffsetMm; // Lateral leaf wander / fanning: Normal < 3 mm. Splayed > 8 mm.
  final double axleSpringSeatWalkingDeltaMm; // Longitudinal axle walking / dog-tracking: Normal < 2 mm. Walking > 6 mm.
  final bool isCenterPinAcousticallyFractured; // Ultrasonic pulse sensor detecting sheared center dowel pin.
  final double grossAxleWeightTonnes;

  const LeafSpringUboltTelemetry({
    required this.uboltClampingPreloadKiloNewtons,
    this.recommendedPreloadKiloNewtons = 95.0,
    required this.leafSpringFanningOffsetMm,
    required this.axleSpringSeatWalkingDeltaMm,
    required this.isCenterPinAcousticallyFractured,
    required this.grossAxleWeightTonnes,
  });

  /// Preload tension retention percentage from torque specification.
  double get tensionRetentionPercent =>
      ((uboltClampingPreloadKiloNewtons / recommendedPreloadKiloNewtons) * 100.0).clamp(0.0, 150.0);
}

/// Audit result for suspension u-bolt torque retention, spring pack splay, and axle dog-tracking prevention.
class LeafSpringUboltAuditResult {
  final String vehicleId;
  final String axleLocation;
  final LeafSpringUboltTorqueStatus status;
  final double clampingPreloadKN;
  final double tensionPercent;
  final double fanningOffsetMm;
  final double axleWalkingMm;
  final String clampingAdvisory;

  const LeafSpringUboltAuditResult({
    required this.vehicleId,
    required this.axleLocation,
    required this.status,
    required this.clampingPreloadKN,
    required this.tensionPercent,
    required this.fanningOffsetMm,
    required this.axleWalkingMm,
    required this.clampingAdvisory,
  });

  bool get isClampingSecure => status == LeafSpringUboltTorqueStatus.uboltClampedNominal;
  bool get isAxleWalkImminent =>
      status == LeafSpringUboltTorqueStatus.criticalCenterPinShearAxleWalkHazard;
}

/// Evaluates suspension leaf spring u-bolt stretching, center bolt shear failure, and axle walking alignment shifts.
class LeafSpringUboltTorqueService {
  const LeafSpringUboltTorqueService();

  LeafSpringUboltAuditResult auditUboltClamping({
    required String vehicleId,
    required String axleLocation,
    required LeafSpringUboltTelemetry telemetry,
  }) {
    final tensionPercent = telemetry.tensionRetentionPercent;

    // 1. Critical: Center pin sheared, u-bolt tension lost (<55 kN), or axle walking > 6 mm
    if (telemetry.isCenterPinAcousticallyFractured ||
        telemetry.uboltClampingPreloadKiloNewtons <= 55.0 ||
        telemetry.axleSpringSeatWalkingDeltaMm >= 6.0 ||
        telemetry.leafSpringFanningOffsetMm >= 10.0) {
      return LeafSpringUboltAuditResult(
        vehicleId: vehicleId,
        axleLocation: axleLocation,
        status: LeafSpringUboltTorqueStatus.criticalCenterPinShearAxleWalkHazard,
        clampingPreloadKN: telemetry.uboltClampingPreloadKiloNewtons,
        tensionPercent: tensionPercent,
        fanningOffsetMm: telemetry.leafSpringFanningOffsetMm,
        axleWalkingMm: telemetry.axleSpringSeatWalkingDeltaMm,
        clampingAdvisory:
            'CRITICAL SUSPENSION HAZARD: Sheared leaf spring center pin or loose U-bolts detected (${telemetry.axleSpringSeatWalkingDeltaMm.toStringAsFixed(1)} mm axle walk)! Axle shifting under braking forces creates dangerous highway dog-tracking and spring pack fracture.',
      );
    }

    // 2. Warning: Preload relaxation < 75 kN or leaf fanning offset > 4.5 mm
    if (telemetry.uboltClampingPreloadKiloNewtons <= 75.0 ||
        telemetry.leafSpringFanningOffsetMm >= 4.5 ||
        telemetry.axleSpringSeatWalkingDeltaMm >= 3.0) {
      return LeafSpringUboltAuditResult(
        vehicleId: vehicleId,
        axleLocation: axleLocation,
        status: LeafSpringUboltTorqueStatus.preloadRelaxationWarning,
        clampingPreloadKN: telemetry.uboltClampingPreloadKiloNewtons,
        tensionPercent: tensionPercent,
        fanningOffsetMm: telemetry.leafSpringFanningOffsetMm,
        axleWalkingMm: telemetry.axleSpringSeatWalkingDeltaMm,
        clampingAdvisory:
            'WARNING: Suspension U-bolt nut torque relaxation detected (${telemetry.uboltClampingPreloadKiloNewtons.toStringAsFixed(0)} kN clamp). Re-torque U-bolt nuts to factory ft-lbs with cross-pattern sequence.',
      );
    }

    // 3. Normal nominal clamping
    return LeafSpringUboltAuditResult(
      vehicleId: vehicleId,
      axleLocation: axleLocation,
      status: LeafSpringUboltTorqueStatus.uboltClampedNominal,
      clampingPreloadKN: telemetry.uboltClampingPreloadKiloNewtons,
      tensionPercent: tensionPercent,
      fanningOffsetMm: telemetry.leafSpringFanningOffsetMm,
      axleWalkingMm: telemetry.axleSpringSeatWalkingDeltaMm,
      clampingAdvisory:
          'NOMINAL: Leaf spring pack U-bolts maintain solid clamping compression. Center dowel pin fully located in axle perch.',
    );
  }
}
