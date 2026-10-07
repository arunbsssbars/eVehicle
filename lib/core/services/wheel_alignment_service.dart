/// Wheel alignment severity categorization.
enum AlignmentSeverity {
  properAlignment,
  minorPullDeviation,
  moderateScrubbing,
  criticalChassisMisalignment,
}

/// Suspension kinematics and tyre temperature telemetry from straight cruising.
class KinematicsTelemetrySample {
  final double steeringAngleOffsetDeg;    // Steering angle when driving straight (e.g. -4.5° to +4.5°)
  final double lateralGForceBias;         // Drift pull bias in G (e.g. 0.02 G)
  final double innerShoulderTempCelsius;  // Tyre tread inner rib temperature
  final double outerShoulderTempCelsius;  // Tyre tread outer rib temperature
  final double cruiseSpeedKmh;            // Must be steady straight cruise (> 60 km/h)

  const KinematicsTelemetrySample({
    required this.steeringAngleOffsetDeg,
    required this.lateralGForceBias,
    required this.innerShoulderTempCelsius,
    required this.outerShoulderTempCelsius,
    required this.cruiseSpeedKmh,
  });
}

/// Comprehensive wheel geometry and tyre scrubbing audit.
class WheelAlignmentAudit {
  final AlignmentSeverity severity;
  final double camberToeDeviationScore; // 0 to 100
  final double deltaShoulderTempCelsius; // Inner - outer shoulder temp
  final double projectedTyreLifeLossPercent;
  final double annualScrubbingFuelPenaltyLiters;
  final String diagnosticFinding;
  final bool laserAlignmentRequired;

  const WheelAlignmentAudit({
    required this.severity,
    required this.camberToeDeviationScore,
    required this.deltaShoulderTempCelsius,
    required this.projectedTyreLifeLossPercent,
    required this.annualScrubbingFuelPenaltyLiters,
    required this.diagnosticFinding,
    required this.laserAlignmentRequired,
  });
}

/// Service analyzing steering angle bias and tyre thermal differentials to diagnose misalignment.
class WheelAlignmentService {
  const WheelAlignmentService();

  /// Audits wheel alignment kinematics from steady straight-line cruise telemetry.
  WheelAlignmentAudit evaluateAlignment(KinematicsTelemetrySample sample) {
    if (sample.cruiseSpeedKmh < 45.0) {
      return const WheelAlignmentAudit(
        severity: AlignmentSeverity.properAlignment,
        camberToeDeviationScore: 5.0,
        deltaShoulderTempCelsius: 0.5,
        projectedTyreLifeLossPercent: 0.0,
        annualScrubbingFuelPenaltyLiters: 0.0,
        diagnosticFinding: 'INSUFFICIENT SPEED: Calibrate alignment telemetry at steady highway cruise (> 50 km/h).',
        laserAlignmentRequired: false,
      );
    }

    final double deltaTemp = (sample.innerShoulderTempCelsius - sample.outerShoulderTempCelsius).abs();
    final double steeringOffset = sample.steeringAngleOffsetDeg.abs();
    final double lateralBias = sample.lateralGForceBias.abs();

    // Composite deviation formula:
    // Steering offset weight (10 pts per degree) + Thermal diff weight (5 pts per °C) + Lateral bias weight
    final double score = (steeringOffset * 10.0 + deltaTemp * 5.0 + lateralBias * 250.0).clamp(0.0, 100.0);

    // Tyre life loss and fuel drag penalty
    final double tyreLifeLoss = (score * 0.45).clamp(0.0, 60.0);
    final double fuelPenalty = (score * 1.8).clamp(0.0, 180.0);

    AlignmentSeverity severity;
    String finding;
    bool laserDue = false;

    if (score >= 65.0 || steeringOffset >= 3.5 || deltaTemp >= 8.0) {
      severity = AlignmentSeverity.criticalChassisMisalignment;
      laserDue = true;
      finding = 'SEVERE MISALIGNMENT: Extreme toe/camber scrub detected (ΔTemp: ${deltaTemp.toStringAsFixed(1)}°C, Offset: ${steeringOffset.toStringAsFixed(1)}°). Immediate laser alignment required.';
    } else if (score >= 40.0 || steeringOffset >= 2.0 || deltaTemp >= 4.5) {
      severity = AlignmentSeverity.moderateScrubbing;
      laserDue = true;
      finding = 'MODERATE TOE/CAMBER DRIFT: Vehicle pulls laterally; accelerated inner/outer shoulder shoulder wear occurring.';
    } else if (score >= 20.0 || steeringOffset >= 1.0) {
      severity = AlignmentSeverity.minorPullDeviation;
      finding = 'MINOR PULL: Slight steering center offset. Verify tyre pressures before wheel alignment.';
    } else {
      severity = AlignmentSeverity.properAlignment;
      finding = 'ALIGNED & BALANCED: Steering zero-point true; uniform shoulder heat dissipation across tread.';
    }

    return WheelAlignmentAudit(
      severity: severity,
      camberToeDeviationScore: double.parse(score.toStringAsFixed(1)),
      deltaShoulderTempCelsius: double.parse(deltaTemp.toStringAsFixed(1)),
      projectedTyreLifeLossPercent: double.parse(tyreLifeLoss.toStringAsFixed(1)),
      annualScrubbingFuelPenaltyLiters: double.parse(fuelPenalty.toStringAsFixed(1)),
      diagnosticFinding: finding,
      laserAlignmentRequired: laserDue,
    );
  }
}
