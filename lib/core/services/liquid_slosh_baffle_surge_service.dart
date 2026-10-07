/// Condition of commercial bulk liquid tanker anti-surge transverse and longitudinal baffle bulkheads.
enum LiquidSloshBaffleStatus {
  surgeDampedNominal,
  highCentrifugalSloshWarning,
  criticalDynamicLiquidRollSurgeHazard,
}

/// Dynamic multi-axis accelerometer, ultrasonic liquid level, and ullage volume telemetry inside bulk liquid tank compartments.
class LiquidSloshBaffleTelemetry {
  final double tankFillLevelPercent; // Ullage risk: 40% - 75% fill volume produces maximum dynamic slosh wave energy.
  final double lateralSloshWaveAmplitudeMetres; // Normal damped wave < 0.25 m. Extreme standing wave > 0.65 m.
  final double longitudinalSurgeForceKiloNewtons; // Forward surge upon braking (Normal < 35 kN. Hydrodynamic surge > 85 kN).
  final double vehicleLateralGForce; // Curve cornering G: Highway rollover threshold: > 0.38 G.
  final double roadSpeedKmh;
  final bool hasInternalTransverseBaffles; // Tank compartment design (Baffled vs Smoothbore sanitary milk/food-grade tanker).

  const LiquidSloshBaffleTelemetry({
    required this.tankFillLevelPercent,
    required this.lateralSloshWaveAmplitudeMetres,
    required this.longitudinalSurgeForceKiloNewtons,
    required this.vehicleLateralGForce,
    required this.roadSpeedKmh,
    required this.hasInternalTransverseBaffles,
  });

  /// High rollover danger: High lateral G combined with large slosh wave displacement.
  bool get isDynamicLiquidOverturningMomentHazard =>
      (vehicleLateralGForce >= 0.30 && lateralSloshWaveAmplitudeMetres >= 0.45) ||
      vehicleLateralGForce >= 0.38;
}

/// Audit result for bulk liquid tanker fluid slosh momentum, braking surge dampening, and rollover stability.
class LiquidSloshBaffleAuditResult {
  final String vehicleId;
  final LiquidSloshBaffleStatus status;
  final double fillPercent;
  final double waveAmplitudeM;
  final double surgeForceKN;
  final double lateralG;
  final String transportStabilityAdvisory;

  const LiquidSloshBaffleAuditResult({
    required this.vehicleId,
    required this.status,
    required this.fillPercent,
    required this.waveAmplitudeM,
    required this.surgeForceKN,
    required this.lateralG,
    required this.transportStabilityAdvisory,
  });

  bool get isTankerStable => status == LiquidSloshBaffleStatus.surgeDampedNominal;
  bool get isImminentLiquidRolloverHazard =>
      status == LiquidSloshBaffleStatus.criticalDynamicLiquidRollSurgeHazard;
}

/// Evaluates bulk tanker hydrodynamic slosh momentum, ullage wave resonance, and smoothbore tank liquid surge roll instability.
class LiquidSloshBaffleSurgeService {
  const LiquidSloshBaffleSurgeService();

  LiquidSloshBaffleAuditResult auditLiquidStability({
    required String vehicleId,
    required LiquidSloshBaffleTelemetry telemetry,
  }) {
    final isRollMoment = telemetry.isDynamicLiquidOverturningMomentHazard;

    // 1. Critical: Extreme dynamic rollover moment (G >= 0.38 or wave > 0.6m in corner) or braking surge > 85 kN
    if (isRollMoment ||
        telemetry.lateralSloshWaveAmplitudeMetres >= 0.60 ||
        telemetry.longitudinalSurgeForceKiloNewtons >= 85.0) {
      return LiquidSloshBaffleAuditResult(
        vehicleId: vehicleId,
        status: LiquidSloshBaffleStatus.criticalDynamicLiquidRollSurgeHazard,
        fillPercent: telemetry.tankFillLevelPercent,
        waveAmplitudeM: telemetry.lateralSloshWaveAmplitudeMetres,
        surgeForceKN: telemetry.longitudinalSurgeForceKiloNewtons,
        lateralG: telemetry.vehicleLateralGForce,
        transportStabilityAdvisory:
            'CRITICAL TANKER ROLLOVER HAZARD: Dynamic liquid slosh wave (${telemetry.lateralSloshWaveAmplitudeMetres.toStringAsFixed(2)}m wave at ${telemetry.vehicleLateralGForce.toStringAsFixed(2)}G) overcomes chassis roll stability! Electronic stability control (ESC) braking commanded. Smoothly ease off throttle and widen turning radius.',
      );
    }

    // 2. Warning: Tank in high-ullage danger zone (45% - 75% fill) with wave > 0.35m or surge > 50 kN
    if ((telemetry.tankFillLevelPercent >= 45.0 && telemetry.tankFillLevelPercent <= 75.0 && telemetry.lateralSloshWaveAmplitudeMetres >= 0.32) ||
        telemetry.longitudinalSurgeForceKiloNewtons >= 50.0 ||
        telemetry.vehicleLateralGForce >= 0.24) {
      return LiquidSloshBaffleAuditResult(
        vehicleId: vehicleId,
        status: LiquidSloshBaffleStatus.highCentrifugalSloshWarning,
        fillPercent: telemetry.tankFillLevelPercent,
        waveAmplitudeM: telemetry.lateralSloshWaveAmplitudeMetres,
        surgeForceKN: telemetry.longitudinalSurgeForceKiloNewtons,
        lateralG: telemetry.vehicleLateralGForce,
        transportStabilityAdvisory:
            'WARNING: High liquid slosh inertia in partial-fill ullage zone (${telemetry.tankFillLevelPercent.toStringAsFixed(0)}% fill). Maintain gentle steering inputs and increase following distance to absorb liquid surge shove.',
      );
    }

    // 3. Normal nominal damped surge
    return LiquidSloshBaffleAuditResult(
      vehicleId: vehicleId,
      status: LiquidSloshBaffleStatus.surgeDampedNominal,
      fillPercent: telemetry.tankFillLevelPercent,
      waveAmplitudeM: telemetry.lateralSloshWaveAmplitudeMetres,
      surgeForceKN: telemetry.longitudinalSurgeForceKiloNewtons,
      lateralG: telemetry.vehicleLateralGForce,
      transportStabilityAdvisory:
          'NOMINAL: Bulk liquid hydrodynamic kinetic momentum is damped. Internal baffles and tank compartmentalization maintain center of gravity stability.',
    );
  }
}
