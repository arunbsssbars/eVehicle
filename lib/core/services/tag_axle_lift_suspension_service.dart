/// Operational condition of pneumatic auxiliary axle air bag lift/lower mechanism.
enum TagAxleLiftSuspensionStatus {
  tagAxleDeployedLoadBearing,
  liftBagPressureWarning,
  criticalOverGrossAxleWeightRatingHazard,
}

/// Dynamic telemetry measuring tag/pusher axle air bag inflation pressure, steer caster angle, and gross axle load.
class TagAxleLiftTelemetry {
  final bool isTagAxleLiftedRetracted; // True = wheels off the ground, False = wheels down carrying payload.
  final double liftBagPressureKPa; // Pneumatic lift chamber pressure (600 - 850 kPa to retract axle).
  final double rideBellowsPressureKPa; // Suspension air bellows pressure when deployed (Proportional to weight).
  final double actualDriveAxleLoadTonnes; // Primary drive axle weight (Legal max: 10.0 tonnes single / 18.0 tonnes tandem).
  final double maxLegalDriveAxleRatingTonnes;
  final double vehicleGrossWeightTonnes;
  final double roadSpeedKmh;

  const TagAxleLiftTelemetry({
    required this.isTagAxleLiftedRetracted,
    required this.liftBagPressureKPa,
    required this.rideBellowsPressureKPa,
    required this.actualDriveAxleLoadTonnes,
    this.maxLegalDriveAxleRatingTonnes = 10.0,
    required this.vehicleGrossWeightTonnes,
    required this.roadSpeedKmh,
  });

  /// Overload delta on primary drive axle caused by lifting tag axle while loaded.
  double get driveAxleOverloadTonnes =>
      (actualDriveAxleLoadTonnes - maxLegalDriveAxleRatingTonnes).clamp(0.0, 20.0);

  /// True if drive axle exceeds legal gross weight because tag axle is lifted.
  bool get isDriveAxleOverloaded => actualDriveAxleLoadTonnes > maxLegalDriveAxleRatingTonnes;
}

/// Audit result for tag/pusher auxiliary axle deployment, weight distribution, and road damage prevention.
class TagAxleLiftAuditResult {
  final String vehicleId;
  final TagAxleLiftSuspensionStatus status;
  final bool isAxleLifted;
  final double driveAxleLoadTonnes;
  final double overloadTonnes;
  final double ridePressureKPa;
  final double liftPressureKPa;
  final String complianceAdvisory;

  const TagAxleLiftAuditResult({
    required this.vehicleId,
    required this.status,
    required this.isAxleLifted,
    required this.driveAxleLoadTonnes,
    required this.overloadTonnes,
    required this.ridePressureKPa,
    required this.liftPressureKPa,
    required this.complianceAdvisory,
  });

  bool get isWeightCompliant => status != TagAxleLiftSuspensionStatus.criticalOverGrossAxleWeightRatingHazard;
}

/// Evaluates tag and pusher lift-axle pneumatic deployment, auto-drop safety interlocks, and bridge weight compliance.
class TagAxleLiftSuspensionService {
  const TagAxleLiftSuspensionService();

  TagAxleLiftAuditResult auditTagAxle({
    required String vehicleId,
    required TagAxleLiftTelemetry telemetry,
  }) {
    final overload = telemetry.driveAxleOverloadTonnes;

    // 1. Critical: Tag axle retracted while vehicle payload overloads drive axle beyond legal bridge rating (>1.5T overload)
    if (telemetry.isTagAxleLiftedRetracted && telemetry.isDriveAxleOverloaded && overload >= 1.5) {
      return TagAxleLiftAuditResult(
        vehicleId: vehicleId,
        status: TagAxleLiftSuspensionStatus.criticalOverGrossAxleWeightRatingHazard,
        isAxleLifted: true,
        driveAxleLoadTonnes: telemetry.actualDriveAxleLoadTonnes,
        overloadTonnes: overload,
        ridePressureKPa: telemetry.rideBellowsPressureKPa,
        liftPressureKPa: telemetry.liftBagPressureKPa,
        complianceAdvisory:
            'CRITICAL WEIGHT VIOLATION: Tag axle is lifted while drive axle is overloaded by ${overload.toStringAsFixed(1)} tonnes! Auto-drop interlock triggered to distribute payload across helper axle and prevent bridge damage fine.',
      );
    }

    // 2. Warning: Bellows pressure low or tag axle up with slight weight excess (<1.5T)
    if ((telemetry.isTagAxleLiftedRetracted && telemetry.isDriveAxleOverloaded) ||
        (!telemetry.isTagAxleLiftedRetracted && telemetry.rideBellowsPressureKPa < 350.0)) {
      return TagAxleLiftAuditResult(
        vehicleId: vehicleId,
        status: TagAxleLiftSuspensionStatus.liftBagPressureWarning,
        isAxleLifted: telemetry.isTagAxleLiftedRetracted,
        driveAxleLoadTonnes: telemetry.actualDriveAxleLoadTonnes,
        overloadTonnes: overload,
        ridePressureKPa: telemetry.rideBellowsPressureKPa,
        liftPressureKPa: telemetry.liftBagPressureKPa,
        complianceAdvisory:
            'WARNING: Tag axle suspension air bellows pressure low or marginal drive load (${telemetry.actualDriveAxleLoadTonnes.toStringAsFixed(1)} T). Verify pneumatic height control regulator valve.',
      );
    }

    // 3. Normal compliant tag axle operation (either correctly deployed with weight or lifted while empty)
    return TagAxleLiftAuditResult(
      vehicleId: vehicleId,
      status: TagAxleLiftSuspensionStatus.tagAxleDeployedLoadBearing,
      isAxleLifted: telemetry.isTagAxleLiftedRetracted,
      driveAxleLoadTonnes: telemetry.actualDriveAxleLoadTonnes,
      overloadTonnes: 0.0,
      ridePressureKPa: telemetry.rideBellowsPressureKPa,
      liftPressureKPa: telemetry.liftBagPressureKPa,
      complianceAdvisory: telemetry.isTagAxleLiftedRetracted
          ? 'NOMINAL: Tag axle lifted in empty unladen mode. Rolling resistance and tire scuffing reduced.'
          : 'NOMINAL: Tag axle deployed and bearing road load. Multi-axle gross weight legally balanced.',
    );
  }
}
