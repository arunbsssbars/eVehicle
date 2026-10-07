/// Telemetry snapshot of dual pneumatic air brake circuits.
class PneumaticAirTelemetry {
  final double primaryReservoirPsi;
  final double secondaryReservoirPsi;
  final double governorCutInPsi;
  final double governorCutOutPsi;
  final double compressorBuildupTimeSeconds; // Standard: 85 to 100 PSI within 45s
  final double pressureDropPerMinuteAppliedPsi; // Max 3 PSI/min for single, 4 PSI for combo

  const PneumaticAirTelemetry({
    required this.primaryReservoirPsi,
    required this.secondaryReservoirPsi,
    this.governorCutInPsi = 100.0,
    this.governorCutOutPsi = 125.0,
    required this.compressorBuildupTimeSeconds,
    required this.pressureDropPerMinuteAppliedPsi,
  });
}

/// Air brake system safety status.
enum AirBrakeIntegrityStatus {
  normal,
  warningLeakage,
  criticalSpringBrakeLockout,
}

/// Audit result for FMCSA / ECE R13 air brake integrity.
class PneumaticAirAuditResult {
  final String vehicleId;
  final AirBrakeIntegrityStatus status;
  final double lowestCircuitPressurePsi;
  final double leakageRatePsiPerMin;
  final bool isGovernorCyclingProperly;
  final bool isSpringBrakeLockoutImminent;
  final String safetyAdvisory;

  const PneumaticAirAuditResult({
    required this.vehicleId,
    required this.status,
    required this.lowestCircuitPressurePsi,
    required this.leakageRatePsiPerMin,
    required this.isGovernorCyclingProperly,
    required this.isSpringBrakeLockoutImminent,
    required this.safetyAdvisory,
  });

  bool get isSafeToOperate => status == AirBrakeIntegrityStatus.normal;
}

/// Commercial Vehicle Pneumatic Air Brake Pressure & Leakage Rate Auditor Service.
class PneumaticAirAuditorService {
  const PneumaticAirAuditorService();

  static const double minimumStatutoryPressurePsi = 60.0; // Low air warning buzzer threshold
  static const double springBrakeEmergencyDeploymentPsi = 45.0;
  static const double maxAllowableAppliedLeakagePsiPerMin = 4.0;

  PneumaticAirAuditResult auditAirSystem({
    required String vehicleId,
    required PneumaticAirTelemetry telemetry,
  }) {
    final lowestPsi = telemetry.primaryReservoirPsi < telemetry.secondaryReservoirPsi
        ? telemetry.primaryReservoirPsi
        : telemetry.secondaryReservoirPsi;

    final isSpringBrakeImminent = lowestPsi <= minimumStatutoryPressurePsi;
    final isGovernorGood = telemetry.governorCutInPsi >= 95.0 && telemetry.governorCutOutPsi <= 135.0;
    final hasExcessiveLeakage = telemetry.pressureDropPerMinuteAppliedPsi > maxAllowableAppliedLeakagePsiPerMin;

    AirBrakeIntegrityStatus status;
    String advisory;

    if (lowestPsi < springBrakeEmergencyDeploymentPsi) {
      status = AirBrakeIntegrityStatus.criticalSpringBrakeLockout;
      advisory = 'CRITICAL: Severe pressure collapse (${lowestPsi.toStringAsFixed(1)} PSI). Spring emergency brakes locked. Do not move vehicle!';
    } else if (isSpringBrakeImminent || hasExcessiveLeakage) {
      status = AirBrakeIntegrityStatus.warningLeakage;
      advisory = 'WARNING: Pneumatic leakage detected (${telemetry.pressureDropPerMinuteAppliedPsi.toStringAsFixed(1)} PSI/min). Low air alarm active.';
    } else {
      status = AirBrakeIntegrityStatus.normal;
      advisory = 'Pneumatic reservoirs charged. Air compressor cycle within nominal DOT parameters.';
    }

    return PneumaticAirAuditResult(
      vehicleId: vehicleId,
      status: status,
      lowestCircuitPressurePsi: double.parse(lowestPsi.toStringAsFixed(1)),
      leakageRatePsiPerMin: double.parse(telemetry.pressureDropPerMinuteAppliedPsi.toStringAsFixed(1)),
      isGovernorCyclingProperly: isGovernorGood,
      isSpringBrakeLockoutImminent: isSpringBrakeImminent,
      safetyAdvisory: advisory,
    );
  }
}
