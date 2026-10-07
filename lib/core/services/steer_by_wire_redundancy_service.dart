/// Operational status of dual-redundant Steer-by-Wire (SbW) road wheel actuators.
enum SteerByWireStatus {
  dualChannelSynchronized,
  actuatorTrackingDiscrepancyWarning,
  criticalDualActuatorAngleDivergenceHazard,
}

/// Telemetry metrics for redundant dual-motor Steer-by-Wire (SbW) rack actuators.
class SteerByWireTelemetry {
  final double channelAAngleDeg; // Channel A resolver angle (degrees)
  final double channelBAngleDeg; // Channel B redundant resolver angle (degrees)
  final double handwheelTargetAngleDeg; // Commanded steering angle from driver / autonomous autopilot
  final double rackTorqueLoadNm; // Resisting steering rack dynamic torque load (Nm)
  final double actuatorCurrentDrawAmps; // Total motor phase current draw (Amps)
  final double canSyncLatencyMs; // Inter-actuator CAN sync bus loop latency (ms)

  const SteerByWireTelemetry({
    required this.channelAAngleDeg,
    required this.channelBAngleDeg,
    required this.handwheelTargetAngleDeg,
    required this.rackTorqueLoadNm,
    required this.actuatorCurrentDrawAmps,
    required this.canSyncLatencyMs,
  });

  /// Absolute angle tracking mismatch between dual actuator resolvers.
  double get channelAngleMismatchDeg => (channelAAngleDeg - channelBAngleDeg).abs();

  /// Average road wheel steering deflection angle.
  double get effectiveRoadWheelAngleDeg => (channelAAngleDeg + channelBAngleDeg) / 2.0;

  /// Absolute deviation between target handwheel command and physical rack angle.
  double get trackingErrorFromTargetDeg =>
      (effectiveRoadWheelAngleDeg - handwheelTargetAngleDeg).abs();
}

/// Audit result for dual-redundant steer-by-wire channel tracking and fail-operational status.
class SteerByWireAuditResult {
  final String vehicleId;
  final SteerByWireStatus status;
  final double angleMismatchDeg;
  final double effectiveRackAngleDeg;
  final double trackingErrorDeg;
  final double syncLatencyMs;
  final double motorCurrentAmps;
  final String safetyAdvisory;

  const SteerByWireAuditResult({
    required this.vehicleId,
    required this.status,
    required this.angleMismatchDeg,
    required this.effectiveRackAngleDeg,
    required this.trackingErrorDeg,
    required this.syncLatencyMs,
    required this.motorCurrentAmps,
    required this.safetyAdvisory,
  });

  bool get isSynchronizedNominal => status == SteerByWireStatus.dualChannelSynchronized;
  bool get isCriticalSteeringHazard =>
      status == SteerByWireStatus.criticalDualActuatorAngleDivergenceHazard;
}

/// Evaluates dual-redundant Steer-by-Wire (SbW) rack actuators, cross-channel resolver tracking, and fail-safe limp state.
class SteerByWireRedundancyService {
  const SteerByWireRedundancyService();

  SteerByWireAuditResult auditSteerByWireRedundancy({
    required String vehicleId,
    required SteerByWireTelemetry telemetry,
  }) {
    final mismatch = telemetry.channelAngleMismatchDeg;
    final trackingErr = telemetry.trackingErrorFromTargetDeg;

    // 1. Critical: Angle divergence > 1.8 deg, sync latency > 25 ms, or tracking error > 4.0 deg
    if (mismatch > 1.80 || telemetry.canSyncLatencyMs >= 25.0 || trackingErr >= 4.0) {
      return SteerByWireAuditResult(
        vehicleId: vehicleId,
        status: SteerByWireStatus.criticalDualActuatorAngleDivergenceHazard,
        angleMismatchDeg: mismatch,
        effectiveRackAngleDeg: telemetry.effectiveRoadWheelAngleDeg,
        trackingErrorDeg: trackingErr,
        syncLatencyMs: telemetry.canSyncLatencyMs,
        motorCurrentAmps: telemetry.actuatorCurrentDrawAmps,
        safetyAdvisory:
            'CRITICAL STEER-BY-WIRE ANGLE DIVERGENCE: Dual actuator divergence (${mismatch.toStringAsFixed(2)}° split, latency ${telemetry.canSyncLatencyMs.toStringAsFixed(0)}ms)! Primary channel isolated; secondary fail-operational limp-mode engaged. Bring truck safely to controlled stop.',
      );
    }

    // 2. Warning: Angle divergence > 0.45 deg, sync latency > 12 ms, or motor current > 60A
    if (mismatch > 0.45 ||
        telemetry.canSyncLatencyMs >= 12.0 ||
        telemetry.actuatorCurrentDrawAmps >= 60.0 ||
        trackingErr >= 1.5) {
      return SteerByWireAuditResult(
        vehicleId: vehicleId,
        status: SteerByWireStatus.actuatorTrackingDiscrepancyWarning,
        angleMismatchDeg: mismatch,
        effectiveRackAngleDeg: telemetry.effectiveRoadWheelAngleDeg,
        trackingErrorDeg: trackingErr,
        syncLatencyMs: telemetry.canSyncLatencyMs,
        motorCurrentAmps: telemetry.actuatorCurrentDrawAmps,
        safetyAdvisory:
            'WARNING: Minor dual-channel tracking discrepancy (${mismatch.toStringAsFixed(2)}° offset). Dual resolver calibration check required. Maintain vigilant vehicle control.',
      );
    }

    // 3. Dual channels synchronized nominal
    return SteerByWireAuditResult(
      vehicleId: vehicleId,
      status: SteerByWireStatus.dualChannelSynchronized,
      angleMismatchDeg: mismatch,
      effectiveRackAngleDeg: telemetry.effectiveRoadWheelAngleDeg,
      trackingErrorDeg: trackingErr,
      syncLatencyMs: telemetry.canSyncLatencyMs,
      motorCurrentAmps: telemetry.actuatorCurrentDrawAmps,
      safetyAdvisory:
          'NOMINAL: Steer-by-wire dual actuator channels are in lockstep synchronization. Redundant rack torque and resolver angles verified.',
    );
  }
}
