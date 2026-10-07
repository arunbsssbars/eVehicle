/// Operational status of commercial multi-axle pneumatic brake proportioning and brake balance.
enum BrakeTandemProportioningStatus {
  brakeTorqueEvenlyDistributed,
  axleSplitPressureImbalanceWarning,
  criticalSteerDriveBrakeSkewSpinoutHazard,
}

/// Dynamic individual-axle air chamber pressure telemetry measuring deceleration torque split and friction lining heating.
class BrakeTandemProportioningTelemetry {
  final double steerAxleChamberPressureKPa; // Standard service brake application: 200 - 650 kPa.
  final double driveAxleTandemChamberPressureKPa;
  final double trailerAxleChamberPressureKPa;
  final double steerAxleLiningTemperatureCelsius; // Normal: 90 - 220°C.
  final double driveAxleLiningTemperatureCelsius;
  final double vehicleDecelerationGForce; // Retardation efficiency: 0.15 - 0.65 G.

  const BrakeTandemProportioningTelemetry({
    required this.steerAxleChamberPressureKPa,
    required this.driveAxleTandemChamberPressureKPa,
    required this.trailerAxleChamberPressureKPa,
    required this.steerAxleLiningTemperatureCelsius,
    required this.driveAxleLiningTemperatureCelsius,
    required this.vehicleDecelerationGForce,
  });

  /// Pressure delta between front steer axle and rear drive tandem axle chambers.
  double get steerDrivePressureSplitDeltaKPa =>
      (steerAxleChamberPressureKPa - driveAxleTandemChamberPressureKPa).abs();

  /// Thermal lining delta indicating dragging brake or unequal deceleration work.
  double get liningTemperatureDeltaCelsius =>
      (steerAxleLiningTemperatureCelsius - driveAxleLiningTemperatureCelsius).abs();
}

/// Audit result for pneumatic brake pressure proportioning, relay valve synchronization, and jackknife spinout avoidance.
class BrakeTandemProportioningAuditResult {
  final String vehicleId;
  final BrakeTandemProportioningStatus status;
  final double steerChamberKPa;
  final double driveChamberKPa;
  final double pressureSplitDeltaKPa;
  final double thermalDeltaCelsius;
  final double decelerationG;
  final String balanceAdvisory;

  const BrakeTandemProportioningAuditResult({
    required this.vehicleId,
    required this.status,
    required this.steerChamberKPa,
    required this.driveChamberKPa,
    required this.pressureSplitDeltaKPa,
    required this.thermalDeltaCelsius,
    required this.decelerationG,
    required this.balanceAdvisory,
  });

  bool get isBrakingBalanced =>
      status == BrakeTandemProportioningStatus.brakeTorqueEvenlyDistributed;
  bool get isSevereSpinoutRisk =>
      status == BrakeTandemProportioningStatus.criticalSteerDriveBrakeSkewSpinoutHazard;
}

/// Evaluates front-to-rear pneumatic brake pressure timing split, relay valve crack pressure mismatch, and high-speed spinout lockup.
class BrakeTandemProportioningService {
  const BrakeTandemProportioningService();

  BrakeTandemProportioningAuditResult auditBrakeProportioning({
    required String vehicleId,
    required BrakeTandemProportioningTelemetry telemetry,
  }) {
    final splitDelta = telemetry.steerDrivePressureSplitDeltaKPa;
    final tempDelta = telemetry.liningTemperatureDeltaCelsius;

    // 1. Critical: Pressure split > 180 kPa under moderate braking, or thermal lining delta > 120°C
    if (splitDelta >= 180.0 ||
        tempDelta >= 120.0 ||
        (splitDelta >= 120.0 && telemetry.vehicleDecelerationGForce > 0.35)) {
      return BrakeTandemProportioningAuditResult(
        vehicleId: vehicleId,
        status: BrakeTandemProportioningStatus.criticalSteerDriveBrakeSkewSpinoutHazard,
        steerChamberKPa: telemetry.steerAxleChamberPressureKPa,
        driveChamberKPa: telemetry.driveAxleTandemChamberPressureKPa,
        pressureSplitDeltaKPa: splitDelta,
        thermalDeltaCelsius: tempDelta,
        decelerationG: telemetry.vehicleDecelerationGForce,
        balanceAdvisory:
            'CRITICAL BRAKE TIMING SKEW: Front-to-rear brake air pressure split diverges by ${splitDelta.toStringAsFixed(0)} kPa! Drive tandem locking before steer axle under highway braking creates imminent tractor spinout jackknife hazard.',
      );
    }

    // 2. Warning: Split delta > 75 kPa or lining temp delta > 55°C
    if (splitDelta >= 75.0 || tempDelta >= 55.0) {
      return BrakeTandemProportioningAuditResult(
        vehicleId: vehicleId,
        status: BrakeTandemProportioningStatus.axleSplitPressureImbalanceWarning,
        steerChamberKPa: telemetry.steerAxleChamberPressureKPa,
        driveChamberKPa: telemetry.driveAxleTandemChamberPressureKPa,
        pressureSplitDeltaKPa: splitDelta,
        thermalDeltaCelsius: tempDelta,
        decelerationG: telemetry.vehicleDecelerationGForce,
        balanceAdvisory:
            'WARNING: Relay valve crack pressure timing imbalance detected (Split: ${splitDelta.toStringAsFixed(0)} kPa). Test tractor protection valve and quick-release valves to equalize service brake apply rates.',
      );
    }

    // 3. Normal nominal balanced brake proportioning
    return BrakeTandemProportioningAuditResult(
      vehicleId: vehicleId,
      status: BrakeTandemProportioningStatus.brakeTorqueEvenlyDistributed,
      steerChamberKPa: telemetry.steerAxleChamberPressureKPa,
      driveChamberKPa: telemetry.driveAxleTandemChamberPressureKPa,
      pressureSplitDeltaKPa: splitDelta,
      thermalDeltaCelsius: tempDelta,
      decelerationG: telemetry.vehicleDecelerationGForce,
      balanceAdvisory:
          'NOMINAL: Pneumatic brake chamber apply timing and thermal energy dissipation are evenly balanced across all vehicle axles.',
    );
  }
}
