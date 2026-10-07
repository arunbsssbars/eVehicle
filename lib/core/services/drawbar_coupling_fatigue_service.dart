/// Structural fatigue and shear crack status for trailer kingpin and drawbar ring.
enum DrawbarCouplingFatigueStatus {
  withinElasticLimit,
  fatigueInspectionRequired,
  criticalShearCrackDecouplingHazard,
}

/// Dynamic strain gauge, acoustic emission, and clearance telemetry for trailer kingpins and drawbars.
class DrawbarCouplingTelemetry {
  final double kingpinDiameterWearMm; // Nominal 50.8 mm (2") or 89 mm (3.5"). Max allowable wear: 1.6 mm (1/16")
  final double drawbarEyeletHoleOvalityMm; // Ovality distortion under cyclic surge braking (Max 2.0 mm)
  final double dynamicTensileMicrostrain; // Normal < 800 µε. High surge load > 1500 µε. Plastic yield > 2200 µε.
  final double acousticEmissionCrackHits; // Ultrasonic ring count detecting sub-surface fracture initiation (>50 hits)
  final double cumulativeTowingKilometers;
  final double grossTowedWeightTonnes;

  const DrawbarCouplingTelemetry({
    required this.kingpinDiameterWearMm,
    required this.drawbarEyeletHoleOvalityMm,
    required this.dynamicTensileMicrostrain,
    required this.acousticEmissionCrackHits,
    required this.cumulativeTowingKilometers,
    required this.grossTowedWeightTonnes,
  });

  bool get hasStructuralAcousticBurst => acousticEmissionCrackHits >= 40.0;
}

/// Coupling fatigue and structural integrity evaluation result.
class DrawbarCouplingAuditResult {
  final String vehicleId;
  final DrawbarCouplingFatigueStatus status;
  final double kingpinWearMm;
  final double eyeletOvalityMm;
  final double microstrain;
  final double acousticHits;
  final double remainingStructuralLifePercent;
  final String advisory;

  const DrawbarCouplingAuditResult({
    required this.vehicleId,
    required this.status,
    required this.kingpinWearMm,
    required this.eyeletOvalityMm,
    required this.microstrain,
    required this.acousticHits,
    required this.remainingStructuralLifePercent,
    required this.advisory,
  });

  bool get isSafeToHaul => status == DrawbarCouplingFatigueStatus.withinElasticLimit;
  bool get isImminentDecouplingDanger => status == DrawbarCouplingFatigueStatus.criticalShearCrackDecouplingHazard;
}

/// Evaluates trailer kingpin neck necking, drawbar eyelet elongation, and acoustic fatigue cracking.
class DrawbarCouplingFatigueService {
  const DrawbarCouplingFatigueService();

  DrawbarCouplingAuditResult auditCoupling({
    required String vehicleId,
    required DrawbarCouplingTelemetry telemetry,
  }) {
    // Structural life remaining calculation (Limit 1.6mm wear)
    final wearRemaining = (1.6 - telemetry.kingpinDiameterWearMm).clamp(0.0, 1.6);
    final lifePercent = ((wearRemaining / 1.6) * 100.0).clamp(0.0, 100.0);

    // 1. Critical shear failure, severe kingpin neck wear or ultrasonic acoustic crack bursts
    if (telemetry.kingpinDiameterWearMm >= 1.6 ||
        telemetry.drawbarEyeletHoleOvalityMm >= 2.5 ||
        telemetry.dynamicTensileMicrostrain >= 2100.0 ||
        telemetry.acousticEmissionCrackHits >= 60.0) {
      return DrawbarCouplingAuditResult(
        vehicleId: vehicleId,
        status: DrawbarCouplingFatigueStatus.criticalShearCrackDecouplingHazard,
        kingpinWearMm: telemetry.kingpinDiameterWearMm,
        eyeletOvalityMm: telemetry.drawbarEyeletHoleOvalityMm,
        microstrain: telemetry.dynamicTensileMicrostrain,
        acousticHits: telemetry.acousticEmissionCrackHits,
        remainingStructuralLifePercent: 0.0,
        advisory:
            'CRITICAL HAZARD: Kingpin neck wear exceeds 1.6 mm discard limit or ultrasonic acoustic crack detected. Severe runaway trailer decoupling danger!',
      );
    }

    // 2. High fatigue accumulation or microcrack initiation threshold
    if (telemetry.kingpinDiameterWearMm >= 1.1 ||
        telemetry.drawbarEyeletHoleOvalityMm >= 1.4 ||
        telemetry.dynamicTensileMicrostrain >= 1400.0 ||
        telemetry.acousticEmissionCrackHits >= 25.0) {
      return DrawbarCouplingAuditResult(
        vehicleId: vehicleId,
        status: DrawbarCouplingFatigueStatus.fatigueInspectionRequired,
        kingpinWearMm: telemetry.kingpinDiameterWearMm,
        eyeletOvalityMm: telemetry.drawbarEyeletHoleOvalityMm,
        microstrain: telemetry.dynamicTensileMicrostrain,
        acousticHits: telemetry.acousticEmissionCrackHits,
        remainingStructuralLifePercent: lifePercent,
        advisory:
            'WARNING: Drawbar eyelet elongation or dynamic microstrain elevated (Strain: ${telemetry.dynamicTensileMicrostrain.toStringAsFixed(0)} µε). Perform magnetic particle or dye penetrant NDT inspection.',
      );
    }

    // 3. Normal elastic towing conditions
    return DrawbarCouplingAuditResult(
      vehicleId: vehicleId,
      status: DrawbarCouplingFatigueStatus.withinElasticLimit,
      kingpinWearMm: telemetry.kingpinDiameterWearMm,
      eyeletOvalityMm: telemetry.drawbarEyeletHoleOvalityMm,
      microstrain: telemetry.dynamicTensileMicrostrain,
      acousticHits: telemetry.acousticEmissionCrackHits,
      remainingStructuralLifePercent: lifePercent,
      advisory:
          'NOMINAL: Trailer kingpin and drawbar eyelet within elastic engineering tolerances. Zero acoustic microcrack propagation.',
    );
  }
}
