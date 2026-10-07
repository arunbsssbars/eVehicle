import 'dart:math' as math;

/// Heavy commercial vehicle rollover risk state.
enum RolloverRiskState {
  stableNominal,
  lateralGWarning,
  espDifferentialBrakingActive,
  criticalTrippingOrRollThreshold,
}

/// Dynamic chassis inertial and sensor telemetry.
class RolloverDynamicsTelemetry {
  final double vehicleSpeedKmh;
  final double steeringAngleDegrees;
  final double lateralAccelerationG;       // Lateral G from IMU accelerometer
  final double yawRateDegreesPerSecond;     // Gyro yaw rate
  final double centerOfGravityHeightMeters; // e.g., 1.8m for laden tanker or refrigerated box
  final double trackWidthMeters;            // e.g., 2.05m
  final double roadSuperelevationBankAngleDegrees; // Banking / cross-slope angle

  const RolloverDynamicsTelemetry({
    required this.vehicleSpeedKmh,
    required this.steeringAngleDegrees,
    required this.lateralAccelerationG,
    required this.yawRateDegreesPerSecond,
    required this.centerOfGravityHeightMeters,
    required this.trackWidthMeters,
    this.roadSuperelevationBankAngleDegrees = 0.0,
  });
}

/// Stability analysis output and ESC/RSC intervention commands.
class RolloverStabilityAudit {
  final RolloverRiskState riskState;
  final double staticRolloverThresholdG; // SSF / SRT = T / (2 * H_cg)
  final double loadTransferRatio;        // LTR from 0.0 (even) to 1.0 (wheel liftoff)
  final bool espInterventionTriggered;
  final String activeInterventionSummary;
  final double targetTorqueCutbackPercent;

  const RolloverStabilityAudit({
    required this.riskState,
    required this.staticRolloverThresholdG,
    required this.loadTransferRatio,
    required this.espInterventionTriggered,
    required this.activeInterventionSummary,
    required this.targetTorqueCutbackPercent,
  });
}

/// Service computing heavy vehicle roll stability, Static Rollover Threshold (SRT), and Electronic Stability Program (ESP) intervention.
class RolloverStabilityService {
  const RolloverStabilityService();

  RolloverStabilityAudit evaluateStability(RolloverDynamicsTelemetry telemetry) {
    // 1. Static Rollover Threshold (SRT) = TrackWidth / (2 * CoG_Height) + bank effect
    final double bankTan = math.tan(telemetry.roadSuperelevationBankAngleDegrees * math.pi / 180.0);
    final double rawSrt = (telemetry.trackWidthMeters / (2.0 * math.max(0.5, telemetry.centerOfGravityHeightMeters))) + bankTan;
    final double staticRolloverThresholdG = math.max(0.15, rawSrt);

    // 2. Load Transfer Ratio (LTR) = (F_right - F_left) / (F_right + F_left) approx = 2 * (a_y / g) * (H_cg / T)
    final double ltr = ((2.0 * telemetry.lateralAccelerationG.abs() * telemetry.centerOfGravityHeightMeters) /
            math.max(1.0, telemetry.trackWidthMeters))
        .clamp(0.0, 1.0);

    RolloverRiskState state;
    bool espActive = false;
    double torqueCutback = 0.0;
    String summary;

    if (ltr >= 0.85 || telemetry.lateralAccelerationG.abs() >= (staticRolloverThresholdG * 0.9)) {
      state = RolloverRiskState.criticalTrippingOrRollThreshold;
      espActive = true;
      torqueCutback = 100.0; // Complete engine de-rate
      summary = 'CRITICAL ROLLOVER RISK (LTR ${(ltr * 100).toStringAsFixed(0)}%): Outer wheels approaching liftoff! Autonomous Emergency Braking (AEB) & full differential brake clamp applied!';
    } else if (ltr >= 0.60 || telemetry.lateralAccelerationG.abs() >= (staticRolloverThresholdG * 0.65)) {
      state = RolloverRiskState.espDifferentialBrakingActive;
      espActive = true;
      torqueCutback = 65.0;
      summary = 'ESP / RSC ACTIVE: Lateral G (${telemetry.lateralAccelerationG.toStringAsFixed(2)}G) exceeds roll safety threshold. Pulsing outer drive brakes to counter yaw moment.';
    } else if (ltr >= 0.35 || telemetry.lateralAccelerationG.abs() >= (staticRolloverThresholdG * 0.40)) {
      state = RolloverRiskState.lateralGWarning;
      espActive = false;
      torqueCutback = 15.0;
      summary = 'LATERAL G ADVISORY: Approaching aggressive cornering threshold (${telemetry.lateralAccelerationG.toStringAsFixed(2)}G). Feather accelerator.';
    } else {
      state = RolloverRiskState.stableNominal;
      espActive = false;
      torqueCutback = 0.0;
      summary = 'STABLE: Cornering dynamics well within static roll limit (${staticRolloverThresholdG.toStringAsFixed(2)}G SRT).';
    }

    return RolloverStabilityAudit(
      riskState: state,
      staticRolloverThresholdG: double.parse(staticRolloverThresholdG.toStringAsFixed(2)),
      loadTransferRatio: double.parse(ltr.toStringAsFixed(2)),
      espInterventionTriggered: espActive,
      activeInterventionSummary: summary,
      targetTorqueCutbackPercent: torqueCutback,
    );
  }
}
