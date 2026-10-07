/// Heavy commercial power steering hydraulic circuit status.
enum SteeringHydraulicStatus {
  normalAssistPressure,
  minorAerationOrCavitation,
  criticalLossOfAssistOrBeltSlip,
}

/// Dynamic telemetry reading from power steering hydraulic pump and rotary spool valve.
class SteeringHydraulicTelemetry {
  final double pumpDischargePressurePsi; // Relief pressure: 1,500 - 2,100 PSI at lock
  final double returnFluidTemperatureCelsius; // Nominal: 60 - 85°C. Critical > 110°C
  final double steeringWheelTorqueNm; // Effort required by driver
  final double fluidLevelPercent;
  final double pumpDriveBeltSlipPercent; // Belt slip ratio

  const SteeringHydraulicTelemetry({
    required this.pumpDischargePressurePsi,
    required this.returnFluidTemperatureCelsius,
    required this.steeringWheelTorqueNm,
    required this.fluidLevelPercent,
    required this.pumpDriveBeltSlipPercent,
  });

  /// True if driver steering effort exceeds unassisted heavy vehicle limit (> 18 Nm).
  bool get isHighDriverSteeringEffort => steeringWheelTorqueNm > 18.0;
}

/// Comprehensive power steering hydraulic assistance audit result.
class SteeringAssistAuditResult {
  final String vehicleId;
  final SteeringHydraulicStatus status;
  final double dischargePressurePsi;
  final double fluidTemperatureCelsius;
  final double steeringTorqueNm;
  final double assistHealthScorePercent;
  final String safetyAdvisory;

  const SteeringAssistAuditResult({
    required this.vehicleId,
    required this.status,
    required this.dischargePressurePsi,
    required this.fluidTemperatureCelsius,
    required this.steeringTorqueNm,
    required this.assistHealthScorePercent,
    required this.safetyAdvisory,
  });

  bool get isSafeToDrive => status == SteeringHydraulicStatus.normalAssistPressure;
  bool get isLossOfSteeringAssist => status == SteeringHydraulicStatus.criticalLossOfAssistOrBeltSlip;
}

/// Service that evaluates commercial truck and bus hydraulic power steering assistance loss.
class SteeringHydraulicAssistService {
  const SteeringHydraulicAssistService();

  SteeringAssistAuditResult auditSteeringAssist({
    required String vehicleId,
    required SteeringHydraulicTelemetry telemetry,
  }) {
    final isLossOfPressure = telemetry.pumpDischargePressurePsi < 350.0 && telemetry.steeringWheelTorqueNm > 15.0;
    final isFluidEmpty = telemetry.fluidLevelPercent < 15.0;
    final isOverheated = telemetry.returnFluidTemperatureCelsius > 115.0;
    final isBeltSlipping = telemetry.pumpDriveBeltSlipPercent > 20.0;

    // Health Score calculation (0 - 100%)
    double score = 100.0;
    if (telemetry.returnFluidTemperatureCelsius > 85.0) {
      score -= ((telemetry.returnFluidTemperatureCelsius - 85.0) * 1.5).clamp(0.0, 40.0);
    }
    if (telemetry.fluidLevelPercent < 50.0) {
      score -= ((50.0 - telemetry.fluidLevelPercent) * 1.2).clamp(0.0, 40.0);
    }
    if (isBeltSlipping) {
      score -= 25.0;
    }
    score = score.clamp(0.0, 100.0);

    // Critical conditions
    if (isLossOfPressure || isFluidEmpty || (isOverheated && telemetry.isHighDriverSteeringEffort)) {
      return SteeringAssistAuditResult(
        vehicleId: vehicleId,
        status: SteeringHydraulicStatus.criticalLossOfAssistOrBeltSlip,
        dischargePressurePsi: telemetry.pumpDischargePressurePsi,
        fluidTemperatureCelsius: telemetry.returnFluidTemperatureCelsius,
        steeringTorqueNm: telemetry.steeringWheelTorqueNm,
        assistHealthScorePercent: score,
        safetyAdvisory:
            'CRITICAL: Power steering hydraulic assist failure! Extreme steering wheel torque required (>18 Nm). Immediate steer axle loss of control risk.',
      );
    }

    if (telemetry.fluidLevelPercent < 35.0 || telemetry.returnFluidTemperatureCelsius > 95.0 || isBeltSlipping) {
      return SteeringAssistAuditResult(
        vehicleId: vehicleId,
        status: SteeringHydraulicStatus.minorAerationOrCavitation,
        dischargePressurePsi: telemetry.pumpDischargePressurePsi,
        fluidTemperatureCelsius: telemetry.returnFluidTemperatureCelsius,
        steeringTorqueNm: telemetry.steeringWheelTorqueNm,
        assistHealthScorePercent: score,
        safetyAdvisory:
            'WARNING: Power steering fluid aeration, pump whine, or accessory serpentine belt slip detected. Check fluid reservoir and tensioner.',
      );
    }

    return SteeringAssistAuditResult(
      vehicleId: vehicleId,
      status: SteeringHydraulicStatus.normalAssistPressure,
      dischargePressurePsi: telemetry.pumpDischargePressurePsi,
      fluidTemperatureCelsius: telemetry.returnFluidTemperatureCelsius,
      steeringTorqueNm: telemetry.steeringWheelTorqueNm,
      assistHealthScorePercent: score,
      safetyAdvisory:
          'NOMINAL: Power steering hydraulic pump discharge pressure and steering torque within factory specification.',
    );
  }
}
