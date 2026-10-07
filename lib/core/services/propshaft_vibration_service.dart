import 'dart:math';

/// Severity of driveline torsional and radial vibration.
enum DrivelineVibrationSeverity {
  smoothBalanced,
  minorCarrierWear,
  uJointAngleMismatch,
  criticalPropshaftFailureRisk,
}

/// Instantaneous vibration telemetry captured from transmission tailshaft and differential accelerometers.
class PropshaftVibrationSample {
  final double shaftRotationalRpm;      // e.g. 1500 to 3200 RPM
  final double order1xAmplitudeMmPerSec; // 1X RPM radial imbalance
  final double order2xAmplitudeMmPerSec; // 2X RPM Cardan / U-joint non-uniform velocity
  final double centerBearingGForceRms;   // High-frequency center carrier wear
  final double workingAngleDiffDegrees;  // Angularity difference between front & rear U-joints (nominal < 1.0°)

  const PropshaftVibrationSample({
    required this.shaftRotationalRpm,
    required this.order1xAmplitudeMmPerSec,
    required this.order2xAmplitudeMmPerSec,
    required this.centerBearingGForceRms,
    required this.workingAngleDiffDegrees,
  });
}

/// Diagnostic evaluation of propshaft balance, U-joint phasing, and carrier bearing.
class PropshaftHealthAudit {
  final DrivelineVibrationSeverity severity;
  final double totalVibrationVelocityMmPerSec; // ISO 10816 composite vibration
  final String primaryFaultDiagnosis;
  final String correctiveAction;
  final bool immediateInspectionRequired;

  const PropshaftHealthAudit({
    required this.severity,
    required this.totalVibrationVelocityMmPerSec,
    required this.primaryFaultDiagnosis,
    required this.correctiveAction,
    required this.immediateInspectionRequired,
  });
}

/// Service analyzing commercial vehicle propshaft torsional harmonics and U-joint angles.
class PropshaftVibrationService {
  const PropshaftVibrationService();

  /// Audits ISO 10816 vibration velocity thresholds and 2X torsional harmonics.
  PropshaftHealthAudit diagnoseDriveline(PropshaftVibrationSample sample) {
    if (sample.shaftRotationalRpm < 600.0) {
      return const PropshaftHealthAudit(
        severity: DrivelineVibrationSeverity.smoothBalanced,
        totalVibrationVelocityMmPerSec: 0.5,
        primaryFaultDiagnosis: 'LOW RPM: Driveline idling. Analyze during highway cruising (> 1500 RPM).',
        correctiveAction: 'Maintain current maintenance schedule.',
        immediateInspectionRequired: false,
      );
    }

    // Composite RMS vibration velocity: sqrt(1X^2 + 2X^2)
    final double totalVibration = sqrt(
      pow(sample.order1xAmplitudeMmPerSec, 2) + pow(sample.order2xAmplitudeMmPerSec, 2),
    );

    DrivelineVibrationSeverity severity;
    String fault;
    String action;
    bool immediate = false;

    if (totalVibration >= 8.5 || sample.centerBearingGForceRms >= 3.5) {
      severity = DrivelineVibrationSeverity.criticalPropshaftFailureRisk;
      immediate = true;
      fault = 'CRITICAL DRIVELINE SHUDDER: High amplitude vibration (${totalVibration.toStringAsFixed(1)} mm/s). Risk of center bearing failure or driveshaft drop!';
      action = 'Reduce speed immediately. Inspect U-joint needle bearings and cross-trunnions.';
    } else if (sample.workingAngleDiffDegrees >= 1.5 || sample.order2xAmplitudeMmPerSec >= 4.5) {
      severity = DrivelineVibrationSeverity.uJointAngleMismatch;
      fault = '2X HARMONIC U-JOINT MISMATCH: Excessive Cardan joint operating angle difference (${sample.workingAngleDiffDegrees.toStringAsFixed(1)}°). Non-uniform rotational velocity.';
      action = 'Check pinion angle shims and air-ride ride height setting.';
    } else if (totalVibration >= 3.5 || sample.centerBearingGForceRms >= 1.8) {
      severity = DrivelineVibrationSeverity.minorCarrierWear;
      fault = 'CARRIER BEARING WEAR: 1X imbalance (${sample.order1xAmplitudeMmPerSec.toStringAsFixed(1)} mm/s) causing rubber isolator fatigue.';
      action = 'Dynamic spin balance propshaft and inspect center support rubber mount.';
    } else {
      severity = DrivelineVibrationSeverity.smoothBalanced;
      fault = 'DRIVELINE BALANCED: Rotational harmonics within ISO 10816 Class II limits.';
      action = 'Grease slip yoke and universal joints at next scheduled PM.';
    }

    return PropshaftHealthAudit(
      severity: severity,
      totalVibrationVelocityMmPerSec: double.parse(totalVibration.toStringAsFixed(2)),
      primaryFaultDiagnosis: fault,
      correctiveAction: action,
      immediateInspectionRequired: immediate,
    );
  }
}
