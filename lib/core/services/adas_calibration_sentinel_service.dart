import 'dart:math';

/// Sensor health and calibration status.
enum AdasSensorStatus {
  calibrated,
  misalignedWarning,
  occludedOrBlind,
}

/// Dynamic radar and camera alignment telemetry sample.
class AdasSensorTelemetry {
  final String sensorId;
  final bool isFrontCamera;
  final double yawAngleDeviationDegrees;   // Azimuth angle deviation (-1.5° to +1.5° tolerance)
  final double pitchAngleDeviationDegrees; // Elevation angle deviation (-1.0° to +1.0° tolerance)
  final double opticalTransmissionPercent; // Lens cleanliness / blockage (0 to 100%)
  final int targetTrackingDiscrepancies;  // Disagreement count between radar & camera fused targets

  const AdasSensorTelemetry({
    required this.sensorId,
    required this.isFrontCamera,
    required this.yawAngleDeviationDegrees,
    required this.pitchAngleDeviationDegrees,
    required this.opticalTransmissionPercent,
    required this.targetTrackingDiscrepancies,
  });

  /// Total angular vector misalignment deviation.
  double get totalAngularMisalignment =>
      sqrt(pow(yawAngleDeviationDegrees, 2) + pow(pitchAngleDeviationDegrees, 2));
}

/// Evaluation result for ADAS optical and radar sensor calibration.
class AdasCalibrationResult {
  final String vehicleId;
  final AdasSensorStatus status;
  final double maxAngularMisalignmentDegrees;
  final double minOpticalCleanlinessPercent;
  final bool isEmergencyBrakingInhibited;
  final bool isFieldTargetCalibrationRequired;
  final String recommendation;

  const AdasCalibrationResult({
    required this.vehicleId,
    required this.status,
    required this.maxAngularMisalignmentDegrees,
    required this.minOpticalCleanlinessPercent,
    required this.isEmergencyBrakingInhibited,
    required this.isFieldTargetCalibrationRequired,
    required this.recommendation,
  });
}

/// ADAS Radar / Camera Calibration & Optical Occlusion Sentinel Service.
class AdasCalibrationSentinelService {
  const AdasCalibrationSentinelService();

  static const double angularMisalignmentLimitDegrees = 2.0;
  static const double occlusionCleanlinessThreshold = 45.0; // Mud, bug splatter, or snow blockage

  AdasCalibrationResult evaluateAdasAlignment({
    required String vehicleId,
    required List<AdasSensorTelemetry> sensors,
  }) {
    if (sensors.isEmpty) {
      return AdasCalibrationResult(
        vehicleId: vehicleId,
        status: AdasSensorStatus.calibrated,
        maxAngularMisalignmentDegrees: 0.0,
        minOpticalCleanlinessPercent: 100.0,
        isEmergencyBrakingInhibited: false,
        isFieldTargetCalibrationRequired: false,
        recommendation: 'No ADAS sensors configured.',
      );
    }

    double maxMisalignment = 0.0;
    double minCleanliness = 100.0;
    bool hasOcclusion = false;
    bool hasMisalignment = false;

    for (final s in sensors) {
      final dev = s.totalAngularMisalignment;
      if (dev > maxMisalignment) maxMisalignment = dev;
      if (s.opticalTransmissionPercent < minCleanliness) minCleanliness = s.opticalTransmissionPercent;

      if (s.opticalTransmissionPercent < occlusionCleanlinessThreshold) {
        hasOcclusion = true;
      }
      if (dev > angularMisalignmentLimitDegrees || s.targetTrackingDiscrepancies > 10) {
        hasMisalignment = true;
      }
    }

    AdasSensorStatus status;
    bool aebInhibited;
    String recommendation;

    if (hasOcclusion) {
      status = AdasSensorStatus.occludedOrBlind;
      aebInhibited = true;
      recommendation = 'BLIND SENSOR: Optical camera lens or radar radome blocked by mud/ice. Clean windscreen & grille.';
    } else if (hasMisalignment) {
      status = AdasSensorStatus.misalignedWarning;
      aebInhibited = true;
      recommendation = 'CALIBRATION FAULT: Sensor alignment offset (${maxMisalignment.toStringAsFixed(1)}°). Target board recalibration required.';
    } else {
      status = AdasSensorStatus.calibrated;
      aebInhibited = false;
      recommendation = 'All ADAS forward sensors calibrated and optically clear.';
    }

    return AdasCalibrationResult(
      vehicleId: vehicleId,
      status: status,
      maxAngularMisalignmentDegrees: double.parse(maxMisalignment.toStringAsFixed(2)),
      minOpticalCleanlinessPercent: double.parse(minCleanliness.toStringAsFixed(1)),
      isEmergencyBrakingInhibited: aebInhibited,
      isFieldTargetCalibrationRequired: hasMisalignment,
      recommendation: recommendation,
    );
  }
}
