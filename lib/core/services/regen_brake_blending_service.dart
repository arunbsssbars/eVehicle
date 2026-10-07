/// Status of dynamic regenerative braking back-EMF, battery charge acceptance, and foundation brake blend.
enum RegenBrakeBlendingStatus {
  regenBlendOptimal,
  regenTorqueTaperColdBatteryWarning,
  criticalBackEmfOvervoltageFrictionBrakeLoss,
}

/// Real-time CAN bus telemetry monitoring regen stator voltage, battery pack charge acceptance, and brake pedal travel.
class RegenBrakeBlendingTelemetry {
  final double requestedBrakingDecelerationMPerS2; // Normal service brake: 0.5 - 3.5 m/s²
  final double electricMotorRegenTorqueNm; // Available regen negative torque (Nominal: -400 to -1200 Nm)
  final double foundationAirFrictionTorqueNm; // Foundation S-cam/disc brake blend
  final double batteryStateOfChargePercent; // High SOC (>92%) cannot absorb high regen current
  final double batteryPackTemperatureCelsius; // Cold battery (<0°C) exhibits lithium plating hazard -> Regen limited
  final double regenInverterBackEmfVolts; // Peak back-EMF: Must stay < 850V bus limit
  final double maxPermissibleBatteryChargeCurrentAmps; // Current limit imposed by BMS

  const RegenBrakeBlendingTelemetry({
    required this.requestedBrakingDecelerationMPerS2,
    required this.electricMotorRegenTorqueNm,
    required this.foundationAirFrictionTorqueNm,
    required this.batteryStateOfChargePercent,
    required this.batteryPackTemperatureCelsius,
    required this.regenInverterBackEmfVolts,
    required this.maxPermissibleBatteryChargeCurrentAmps,
  });

  /// Ratio of deceleration provided by pure kinetic regeneration (0 - 100%).
  double get regenDecelRatioPercent {
    final totalTorque = electricMotorRegenTorqueNm.abs() + foundationAirFrictionTorqueNm.abs();
    if (totalTorque <= 0.0) return 100.0;
    return ((electricMotorRegenTorqueNm.abs() / totalTorque) * 100.0).clamp(0.0, 100.0);
  }

  /// Cold battery or high SOC condition restricting regen capture.
  bool get isRegenAbsorptionRestricted =>
      batteryStateOfChargePercent >= 92.0 || batteryPackTemperatureCelsius <= 2.0;
}

/// Audit result for EV/Hybrid regenerative blending, stopping distance safety, and friction brake handoff.
class RegenBrakeBlendingAuditResult {
  final String vehicleId;
  final RegenBrakeBlendingStatus status;
  final double regenTorqueNm;
  final double frictionTorqueNm;
  final double regenRatioPercent;
  final double backEmfVolts;
  final double batterySocPercent;
  final String blendAdvisory;

  const RegenBrakeBlendingAuditResult({
    required this.vehicleId,
    required this.status,
    required this.regenTorqueNm,
    required this.frictionTorqueNm,
    required this.regenRatioPercent,
    required this.backEmfVolts,
    required this.batterySocPercent,
    required this.blendAdvisory,
  });

  bool get isRegenOptimal => status == RegenBrakeBlendingStatus.regenBlendOptimal;
  bool get isOvervoltageCritical =>
      status == RegenBrakeBlendingStatus.criticalBackEmfOvervoltageFrictionBrakeLoss;
}

/// Service that coordinates smooth regenerative-to-friction brake handoff, prevents cold-battery overcharging, and guards inverter DC-bus against back-EMF spikes.
class RegenBrakeBlendingService {
  const RegenBrakeBlendingService();

  RegenBrakeBlendingAuditResult auditBlending({
    required String vehicleId,
    required RegenBrakeBlendingTelemetry telemetry,
  }) {
    final regenRatio = telemetry.regenDecelRatioPercent;

    // 1. Critical: Back-EMF overvoltage spike (>840V) or zero friction brake backup during sudden regen drop
    if (telemetry.regenInverterBackEmfVolts >= 840.0 ||
        (telemetry.isRegenAbsorptionRestricted && telemetry.foundationAirFrictionTorqueNm.abs() < 50.0 && telemetry.requestedBrakingDecelerationMPerS2 > 1.5)) {
      return RegenBrakeBlendingAuditResult(
        vehicleId: vehicleId,
        status: RegenBrakeBlendingStatus.criticalBackEmfOvervoltageFrictionBrakeLoss,
        regenTorqueNm: telemetry.electricMotorRegenTorqueNm,
        frictionTorqueNm: telemetry.foundationAirFrictionTorqueNm,
        regenRatioPercent: regenRatio,
        backEmfVolts: telemetry.regenInverterBackEmfVolts,
        batterySocPercent: telemetry.batteryStateOfChargePercent,
        blendAdvisory:
            'CRITICAL HAZARD: Inverter DC-bus back-EMF spike (${telemetry.regenInverterBackEmfVolts.toStringAsFixed(0)} V) or friction brake handoff shortfall! Rapid foundation pneumatic pre-charge commanded to prevent runaway stopping distance.',
      );
    }

    // 2. Warning: Cold battery or pack full (>92% SOC) forcing regen taper
    if (telemetry.isRegenAbsorptionRestricted ||
        telemetry.maxPermissibleBatteryChargeCurrentAmps < 60.0 ||
        telemetry.batteryPackTemperatureCelsius <= 5.0) {
      return RegenBrakeBlendingAuditResult(
        vehicleId: vehicleId,
        status: RegenBrakeBlendingStatus.regenTorqueTaperColdBatteryWarning,
        regenTorqueNm: telemetry.electricMotorRegenTorqueNm,
        frictionTorqueNm: telemetry.foundationAirFrictionTorqueNm,
        regenRatioPercent: regenRatio,
        backEmfVolts: telemetry.regenInverterBackEmfVolts,
        batterySocPercent: telemetry.batteryStateOfChargePercent,
        blendAdvisory:
            'WARNING: Battery charge acceptance restricted (SOC: ${telemetry.batteryStateOfChargePercent.toStringAsFixed(0)}%, Temp: ${telemetry.batteryPackTemperatureCelsius.toStringAsFixed(1)}°C). Blending foundation friction brakes to compensate for faded regen braking torque.',
      );
    }

    // 3. Normal optimal regenerative brake blending
    return RegenBrakeBlendingAuditResult(
      vehicleId: vehicleId,
      status: RegenBrakeBlendingStatus.regenBlendOptimal,
      regenTorqueNm: telemetry.electricMotorRegenTorqueNm,
      frictionTorqueNm: telemetry.foundationAirFrictionTorqueNm,
      regenRatioPercent: regenRatio,
      backEmfVolts: telemetry.regenInverterBackEmfVolts,
      batterySocPercent: telemetry.batteryStateOfChargePercent,
      blendAdvisory:
          'NOMINAL: Regenerative kinetic recovery and foundation friction brake blending are operating with seamless deceleration continuity.',
    );
  }
}
