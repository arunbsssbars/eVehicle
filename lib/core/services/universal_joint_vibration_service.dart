/// Driveline universal joint needle bearing needle brinelling and vibration harmonic condition.
enum UniversalJointVibrationStatus {
  drivelinePhasedNominal,
  uJointTrunnionWearWarning,
  criticalNeedleShatterDriveshaftDropHazard,
}

/// Dynamic piezoelectric accelerometer and angular laser telemetry measuring propshaft 1X/2X rotational harmonics, phase angle, and slip yoke spline play.
class UniversalJointVibrationTelemetry {
  final double propshaftRotationalSpeedRpm; // Normal highway: 1800 - 3200 RPM.
  final double secondOrderHarmonicVibrationMmPerSec; // 2X harmonic indicates U-joint needle brinelling or working angle error (> 4.5 mm/s warning, > 9.0 mm/s destructive).
  final double drivelineWorkingAngleDegrees; // Joint angle: Nominal: 1.0° to 3.5°. Out of phase / binding > 5.5°.
  final double slipYokeSplineRadialPlayMm; // Spline lash: Normal < 0.25 mm. Worn > 0.8 mm.
  final double uJointSpiderTrunnionTemperatureCelsius; // Normal: 45 - 75°C. Unlubricated galling > 110°C.
  final double continuousDriveshaftOperatingHours;

  const UniversalJointVibrationTelemetry({
    required this.propshaftRotationalSpeedRpm,
    required this.secondOrderHarmonicVibrationMmPerSec,
    required this.drivelineWorkingAngleDegrees,
    required this.slipYokeSplineRadialPlayMm,
    required this.uJointSpiderTrunnionTemperatureCelsius,
    required this.continuousDriveshaftOperatingHours,
  });

  /// Driveline vibration severity index: True if trunnion needle bearings are dry/galled.
  bool get isBearingGallingThermalStress =>
      uJointSpiderTrunnionTemperatureCelsius >= 105.0 || secondOrderHarmonicVibrationMmPerSec >= 8.5;
}

/// Audit result for propeller driveshaft universal joint, slip yoke, and center support bearing balance.
class UniversalJointVibrationAuditResult {
  final String vehicleId;
  final String shaftSegment; // e.g. "Main Propshaft - Transmission to Center Bearing"
  final UniversalJointVibrationStatus status;
  final double vibrationMmPerSec;
  final double workingAngleDeg;
  final double trunnionTempCelsius;
  final double splinePlayMm;
  final String harmonicAdvisory;

  const UniversalJointVibrationAuditResult({
    required this.vehicleId,
    required this.shaftSegment,
    required this.status,
    required this.vibrationMmPerSec,
    required this.workingAngleDeg,
    required this.trunnionTempCelsius,
    required this.splinePlayMm,
    required this.harmonicAdvisory,
  });

  bool get isDrivelineSmooth => status == UniversalJointVibrationStatus.drivelinePhasedNominal;
  bool get isDriveshaftDropCatastrophicRisk =>
      status == UniversalJointVibrationStatus.criticalNeedleShatterDriveshaftDropHazard;
}

/// Evaluates propshaft universal joint needle bearing brinelling, working angle phasing mismatch, and driveshaft drop loop protection.
class UniversalJointVibrationService {
  const UniversalJointVibrationService();

  UniversalJointVibrationAuditResult auditUniversalJoint({
    required String vehicleId,
    required String shaftSegment,
    required UniversalJointVibrationTelemetry telemetry,
  }) {
    final vibration = telemetry.secondOrderHarmonicVibrationMmPerSec;

    // 1. Critical: Destructive 2X vibration (>= 9.0 mm/s), bearing overheating > 115°C, or extreme working angle > 5.8°
    if (vibration >= 9.0 ||
        telemetry.uJointSpiderTrunnionTemperatureCelsius >= 115.0 ||
        telemetry.drivelineWorkingAngleDegrees >= 5.8 ||
        telemetry.slipYokeSplineRadialPlayMm >= 1.2) {
      return UniversalJointVibrationAuditResult(
        vehicleId: vehicleId,
        shaftSegment: shaftSegment,
        status: UniversalJointVibrationStatus.criticalNeedleShatterDriveshaftDropHazard,
        vibrationMmPerSec: vibration,
        workingAngleDeg: telemetry.drivelineWorkingAngleDegrees,
        trunnionTempCelsius: telemetry.uJointSpiderTrunnionTemperatureCelsius,
        splinePlayMm: telemetry.slipYokeSplineRadialPlayMm,
        harmonicAdvisory:
            'CRITICAL DRIVELINE HAZARD: Severe 2X propshaft harmonic vibration (${vibration.toStringAsFixed(1)} mm/s) or U-joint trunnion galling! Imminent spider cross snap risks dropping driveshaft onto highway. Immediate towing required.',
      );
    }

    // 2. Warning: 2X vibration >= 4.5 mm/s, trunnion temp > 95°C, or slip yoke play > 0.6 mm
    if (vibration >= 4.5 ||
        telemetry.uJointSpiderTrunnionTemperatureCelsius >= 95.0 ||
        telemetry.drivelineWorkingAngleDegrees >= 4.0 ||
        telemetry.slipYokeSplineRadialPlayMm >= 0.6) {
      return UniversalJointVibrationAuditResult(
        vehicleId: vehicleId,
        shaftSegment: shaftSegment,
        status: UniversalJointVibrationStatus.uJointTrunnionWearWarning,
        vibrationMmPerSec: vibration,
        workingAngleDeg: telemetry.drivelineWorkingAngleDegrees,
        trunnionTempCelsius: telemetry.uJointSpiderTrunnionTemperatureCelsius,
        splinePlayMm: telemetry.slipYokeSplineRadialPlayMm,
        harmonicAdvisory:
            'WARNING: Propeller shaft universal joint needle bearing brinelling detected (2X Harmonic: ${vibration.toStringAsFixed(1)} mm/s). Grease U-joint cross zerk fittings and check transmission output shaft angle.',
      );
    }

    // 3. Normal nominal driveline balance
    return UniversalJointVibrationAuditResult(
      vehicleId: vehicleId,
      shaftSegment: shaftSegment,
      status: UniversalJointVibrationStatus.drivelinePhasedNominal,
      vibrationMmPerSec: vibration,
      workingAngleDeg: telemetry.drivelineWorkingAngleDegrees,
      trunnionTempCelsius: telemetry.uJointSpiderTrunnionTemperatureCelsius,
      splinePlayMm: telemetry.slipYokeSplineRadialPlayMm,
      harmonicAdvisory:
          'NOMINAL: Driveshaft universal joint working angles and rotational 2X harmonics are perfectly balanced.',
    );
  }
}
