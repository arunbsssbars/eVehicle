/// Status of articulated steering hydraulic cylinder synchronicity and pivot articulation angle.
enum ArticulationJointStatus {
  jointPlumbSynchronous,
  yawDriftAlignmentWarning,
  criticalJackknifeLimpHazard,
}

/// Dynamic telemetry measuring articulation pivot angle, hitch yaw rate, and twin-cylinder pressure split.
class ArticulationJointTelemetry {
  final double articulationAngleDegrees; // Center: 0°. Extreme swing: +/- 45°. Critical jackknife > 48°.
  final double articulationYawRateDegreesPerSec; // Angular velocity: > 25°/s indicates rapid uncommanded swing.
  final double portCylinderPressureKPa; // Twin steering hydraulic cylinders.
  final double starboardCylinderPressureKPa;
  final double vehicleGroundSpeedKmh;
  final double steeringHandwheelAngleDegrees; // Angle driver is commanding at steering column.

  const ArticulationJointTelemetry({
    required this.articulationAngleDegrees,
    required this.articulationYawRateDegreesPerSec,
    required this.portCylinderPressureKPa,
    required this.starboardCylinderPressureKPa,
    required this.vehicleGroundSpeedKmh,
    required this.steeringHandwheelAngleDegrees,
  });

  /// Cylinder hydraulic push/pull imbalance pressure delta (Nominal < 1500 kPa).
  double get cylinderDifferentialPressureKPa =>
      (portCylinderPressureKPa - starboardCylinderPressureKPa).abs();

  /// Angular divergence between driver wheel command and physical articulation center joint.
  double get kinematicTrackingErrorDegrees =>
      (articulationAngleDegrees - (steeringHandwheelAngleDegrees / 12.0)).abs();
}

/// Audit result for heavy articulated bus/tipper steering hinge synchronization and jackknife avoidance.
class ArticulationJointAuditResult {
  final String vehicleId;
  final ArticulationJointStatus status;
  final double articulationAngle;
  final double yawRate;
  final double cylinderDeltaKPa;
  final double trackingErrorDeg;
  final String stabilizationAdvisory;

  const ArticulationJointAuditResult({
    required this.vehicleId,
    required this.status,
    required this.articulationAngle,
    required this.yawRate,
    required this.cylinderDeltaKPa,
    required this.trackingErrorDeg,
    required this.stabilizationAdvisory,
  });

  bool get isArticulatedJointSafe => status == ArticulationJointStatus.jointPlumbSynchronous;
  bool get isCriticalJackknifeRisk =>
      status == ArticulationJointStatus.criticalJackknifeLimpHazard;
}

/// Evaluates articulated vehicle turntable pivot bearing, hydraulic twin-ram synchronization, and high-speed jackknife runaway.
class ArticulationJointStabilizerService {
  const ArticulationJointStabilizerService();

  ArticulationJointAuditResult auditArticulation({
    required String vehicleId,
    required ArticulationJointTelemetry telemetry,
  }) {
    final trackingError = telemetry.kinematicTrackingErrorDegrees;
    final cylinderDelta = telemetry.cylinderDifferentialPressureKPa;
    final absAngle = telemetry.articulationAngleDegrees.abs();

    // 1. Critical: Imminent jackknife (>46° angle or uncommanded yaw spin at speed >25 km/h)
    if (absAngle >= 46.0 ||
        (telemetry.articulationYawRateDegreesPerSec.abs() >= 28.0 && telemetry.vehicleGroundSpeedKmh > 20.0) ||
        (trackingError >= 20.0 && telemetry.vehicleGroundSpeedKmh > 30.0)) {
      return ArticulationJointAuditResult(
        vehicleId: vehicleId,
        status: ArticulationJointStatus.criticalJackknifeLimpHazard,
        articulationAngle: telemetry.articulationAngleDegrees,
        yawRate: telemetry.articulationYawRateDegreesPerSec,
        cylinderDeltaKPa: cylinderDelta,
        trackingErrorDeg: trackingError,
        stabilizationAdvisory:
            'CRITICAL HAZARD: Articulated joint jackknife threshold exceeded (${telemetry.articulationAngleDegrees.toStringAsFixed(1)}° angle)! Hydraulic articulation lock valves triggered and powertrain torque cut to prevent chassis folding.',
      );
    }

    // 2. Warning: Hydraulic cylinder pressure mismatch > 3500 kPa or tracking lag > 10°
    if (cylinderDelta >= 3500.0 ||
        trackingError >= 10.0 ||
        absAngle >= 35.0) {
      return ArticulationJointAuditResult(
        vehicleId: vehicleId,
        status: ArticulationJointStatus.yawDriftAlignmentWarning,
        articulationAngle: telemetry.articulationAngleDegrees,
        yawRate: telemetry.articulationYawRateDegreesPerSec,
        cylinderDeltaKPa: cylinderDelta,
        trackingErrorDeg: trackingError,
        stabilizationAdvisory:
            'WARNING: Hydraulic articulation cylinder pressure split elevated (Delta: ${cylinderDelta.toStringAsFixed(0)} kPa). Inspect turntable slew ring damping dampers and steering proportioning valve.',
      );
    }

    // 3. Normal plumb articulation
    return ArticulationJointAuditResult(
      vehicleId: vehicleId,
      status: ArticulationJointStatus.jointPlumbSynchronous,
      articulationAngle: telemetry.articulationAngleDegrees,
      yawRate: telemetry.articulationYawRateDegreesPerSec,
      cylinderDeltaKPa: cylinderDelta,
      trackingErrorDeg: trackingError,
      stabilizationAdvisory:
          'NOMINAL: Articulated turntable pivot bearing and dual hydraulic steering cylinders are perfectly synchronized.',
    );
  }
}
