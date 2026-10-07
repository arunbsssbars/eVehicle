/// Safety status of the pneumatic air suspension leveling valve.
enum AirSuspensionStatus {
  balancedRideHeight,
  minorRideHeightOffset,
  criticalAirSpringLeakOrOverload,
}

/// Dynamic telemetry reading from axle height sensors and air bellows pressure transducers.
class AirSuspensionTelemetry {
  final double leftBellowPressurePsi; // Nominal: 60 - 110 PSI depending on load
  final double rightBellowPressurePsi;
  final double leftRideHeightMm; // Target nominal: 220 mm
  final double rightRideHeightMm; // Target nominal: 220 mm
  final double nominalRideHeightMm;
  final double compressorDutyCyclePercent; // Compressor run time %
  final bool isKneelingActive;

  const AirSuspensionTelemetry({
    required this.leftBellowPressurePsi,
    required this.rightBellowPressurePsi,
    required this.leftRideHeightMm,
    required this.rightRideHeightMm,
    this.nominalRideHeightMm = 220.0,
    required this.compressorDutyCyclePercent,
    this.isKneelingActive = false,
  });

  /// Ride height lateral cross-tilt difference (left vs right).
  double get crossTiltDeltaMm => (leftRideHeightMm - rightRideHeightMm).abs();

  /// Pressure imbalance across the leveling axle.
  double get bellowPressureDeltaPsi => (leftBellowPressurePsi - rightBellowPressurePsi).abs();
}

/// Comprehensive air suspension leveling and bag puncture audit result.
class AirSuspensionAuditResult {
  final String vehicleId;
  final AirSuspensionStatus status;
  final double crossTiltMm;
  final double pressureDeltaPsi;
  final double averagePressurePsi;
  final bool isCompressorOverworked;
  final String levelingAdvisory;

  const AirSuspensionAuditResult({
    required this.vehicleId,
    required this.status,
    required this.crossTiltMm,
    required this.pressureDeltaPsi,
    required this.averagePressurePsi,
    required this.isCompressorOverworked,
    required this.levelingAdvisory,
  });

  bool get isBalanced => status == AirSuspensionStatus.balancedRideHeight;
  bool get isCritical => status == AirSuspensionStatus.criticalAirSpringLeakOrOverload;
}

/// Service that evaluates commercial bus and truck air suspension leveling valves and bag leaks.
class AirSuspensionLevelingService {
  const AirSuspensionLevelingService();

  AirSuspensionAuditResult auditSuspension({
    required String vehicleId,
    required AirSuspensionTelemetry telemetry,
  }) {
    if (telemetry.isKneelingActive) {
      return AirSuspensionAuditResult(
        vehicleId: vehicleId,
        status: AirSuspensionStatus.balancedRideHeight,
        crossTiltMm: telemetry.crossTiltDeltaMm,
        pressureDeltaPsi: telemetry.bellowPressureDeltaPsi,
        averagePressurePsi: (telemetry.leftBellowPressurePsi + telemetry.rightBellowPressurePsi) / 2.0,
        isCompressorOverworked: false,
        levelingAdvisory: 'PASSENGER KNEELING: Chassis actively lowered for accessible passenger ingress.',
      );
    }

    final tilt = telemetry.crossTiltDeltaMm;
    final deltaP = telemetry.bellowPressureDeltaPsi;
    final isCompressorOverworked = telemetry.compressorDutyCyclePercent > 65.0;
    final minPressure = telemetry.leftBellowPressurePsi < telemetry.rightBellowPressurePsi
        ? telemetry.leftBellowPressurePsi
        : telemetry.rightBellowPressurePsi;

    // Critical: Tilt > 35 mm, delta P > 35 PSI, bellow collapse (< 25 PSI), or overworked compressor
    if (tilt > 35.0 || deltaP > 35.0 || minPressure < 25.0 || (tilt > 25.0 && isCompressorOverworked)) {
      return AirSuspensionAuditResult(
        vehicleId: vehicleId,
        status: AirSuspensionStatus.criticalAirSpringLeakOrOverload,
        crossTiltMm: tilt,
        pressureDeltaPsi: deltaP,
        averagePressurePsi: (telemetry.leftBellowPressurePsi + telemetry.rightBellowPressurePsi) / 2.0,
        isCompressorOverworked: isCompressorOverworked,
        levelingAdvisory:
            'CRITICAL: Air spring bellows puncture or leveling valve linkage disconnected! High vehicle rollover risk.',
      );
    }

    if (tilt > 15.0 || deltaP > 18.0 || isCompressorOverworked) {
      return AirSuspensionAuditResult(
        vehicleId: vehicleId,
        status: AirSuspensionStatus.minorRideHeightOffset,
        crossTiltMm: tilt,
        pressureDeltaPsi: deltaP,
        averagePressurePsi: (telemetry.leftBellowPressurePsi + telemetry.rightBellowPressurePsi) / 2.0,
        isCompressorOverworked: isCompressorOverworked,
        levelingAdvisory:
            'WARNING: Uneven axle load distribution or slow air bellows leak. Inspect height sensor linkage calibration.',
      );
    }

    return AirSuspensionAuditResult(
      vehicleId: vehicleId,
      status: AirSuspensionStatus.balancedRideHeight,
      crossTiltMm: tilt,
      pressureDeltaPsi: deltaP,
      averagePressurePsi: (telemetry.leftBellowPressurePsi + telemetry.rightBellowPressurePsi) / 2.0,
      isCompressorOverworked: false,
      levelingAdvisory:
          'NOMINAL: Pneumatic ride height and air spring bellow pressures symmetrically balanced.',
    );
  }
}
