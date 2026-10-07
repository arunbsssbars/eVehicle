/// Differential axle locking dog clutch engagement and slip condition.
enum AxleDifferentialLockStatus {
  openDifferentialDisengaged,
  crossLockEngagedNormalTraction,
  criticalPavementLockBindingHazard,
}

/// Dynamic wheel speed telemetry measuring cross-axle spin delta and pneumatic lock pressure.
class AxleDifferentialLockTelemetry {
  final double leftWheelSpeedKmh;
  final double rightWheelSpeedKmh;
  final double vehicleRoadSpeedKmh;
  final double pneumaticActuatorPressureKPa; // Nominal lock engage: > 620 kPa (90 PSI)
  final bool isDashLockSwitchCommanded;
  final bool isDogClutchProximitySensorTripped; // Proximity switch confirming dog teeth fully meshed
  final double steeringAngleDegrees; // Tight turn on dry pavement > 15° with lock engaged causes axle shaft snap

  const AxleDifferentialLockTelemetry({
    required this.leftWheelSpeedKmh,
    required this.rightWheelSpeedKmh,
    required this.vehicleRoadSpeedKmh,
    required this.pneumaticActuatorPressureKPa,
    required this.isDashLockSwitchCommanded,
    required this.isDogClutchProximitySensorTripped,
    required this.steeringAngleDegrees,
  });

  /// Speed differential between companion wheels on the same driven axle.
  double get wheelSpeedDeltaKmh => (leftWheelSpeedKmh - rightWheelSpeedKmh).abs();

  /// Binding torsion condition: High road speed or sharp turn on hard asphalt while locked.
  bool get isTorsionalBindingRisk =>
      isDogClutchProximitySensorTripped &&
      (vehicleRoadSpeedKmh > 40.0 || (steeringAngleDegrees.abs() > 15.0 && vehicleRoadSpeedKmh > 15.0));
}

/// Evaluation result for axle cross-lock engagement and driveline wind-up protection.
class AxleDifferentialLockAuditResult {
  final String vehicleId;
  final String axleDesignation;
  final AxleDifferentialLockStatus status;
  final double speedDeltaKmh;
  final double actuatorPressureKPa;
  final bool isLocked;
  final bool isDrivelineWindUpRisk;
  final String safetyAdvisory;

  const AxleDifferentialLockAuditResult({
    required this.vehicleId,
    required this.axleDesignation,
    required this.status,
    required this.speedDeltaKmh,
    required this.actuatorPressureKPa,
    required this.isLocked,
    required this.isDrivelineWindUpRisk,
    required this.safetyAdvisory,
  });

  bool get isSafeToOperate => status != AxleDifferentialLockStatus.criticalPavementLockBindingHazard;
}

/// Service that audits differential cross-lock engagement, prevents dog clutch tooth stripping, and prevents axle shaft shearing on dry pavement.
class AxleDifferentialLockService {
  const AxleDifferentialLockService();

  AxleDifferentialLockAuditResult auditAxleLock({
    required String vehicleId,
    required String axleDesignation,
    required AxleDifferentialLockTelemetry telemetry,
  }) {
    final speedDelta = telemetry.wheelSpeedDeltaKmh;
    final isWindUp = telemetry.isTorsionalBindingRisk;

    // 1. Critical: Cross-lock engaged at highway speeds or during dry pavement turning -> Driveline wind-up & shaft fracture
    if (telemetry.isDogClutchProximitySensorTripped && isWindUp) {
      return AxleDifferentialLockAuditResult(
        vehicleId: vehicleId,
        axleDesignation: axleDesignation,
        status: AxleDifferentialLockStatus.criticalPavementLockBindingHazard,
        speedDeltaKmh: speedDelta,
        actuatorPressureKPa: telemetry.pneumaticActuatorPressureKPa,
        isLocked: true,
        isDrivelineWindUpRisk: true,
        safetyAdvisory:
            'CRITICAL HAZARD: Differential cross-lock engaged on hard pavement at ${telemetry.vehicleRoadSpeedKmh.toStringAsFixed(0)} km/h! Severe driveline wind-up and axle shaft fracture imminent. Disengage lock immediately.',
      );
    }

    // 2. Normal engaged operation in low-traction / off-road conditions (<40 km/h)
    if (telemetry.isDogClutchProximitySensorTripped || telemetry.isDashLockSwitchCommanded) {
      // Incomplete dog tooth engagement warning if commanded but sensor open
      final incompleteEngagement = telemetry.isDashLockSwitchCommanded && !telemetry.isDogClutchProximitySensorTripped;

      return AxleDifferentialLockAuditResult(
        vehicleId: vehicleId,
        axleDesignation: axleDesignation,
        status: AxleDifferentialLockStatus.crossLockEngagedNormalTraction,
        speedDeltaKmh: speedDelta,
        actuatorPressureKPa: telemetry.pneumaticActuatorPressureKPa,
        isLocked: telemetry.isDogClutchProximitySensorTripped,
        isDrivelineWindUpRisk: false,
        safetyAdvisory: incompleteEngagement
            ? 'WARNING: Diff-lock switch ON but dog clutch not fully meshed. Ease off throttle to allow splines to engage smoothly.'
            : 'TRACTION ENGAGED: Axle differential cross-lock locked 1:1. Maintain low speed (<40 km/h) and straight steering on low-grip surfaces.',
      );
    }

    // 3. Normal Open Differential
    return AxleDifferentialLockAuditResult(
      vehicleId: vehicleId,
      axleDesignation: axleDesignation,
      status: AxleDifferentialLockStatus.openDifferentialDisengaged,
      speedDeltaKmh: speedDelta,
      actuatorPressureKPa: telemetry.pneumaticActuatorPressureKPa,
      isLocked: false,
      isDrivelineWindUpRisk: false,
      safetyAdvisory:
          'NOMINAL: Differential operating in standard open mode. Wheels differentiate freely through turns.',
    );
  }
}
