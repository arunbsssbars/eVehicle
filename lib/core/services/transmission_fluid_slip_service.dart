/// Health status of heavy commercial automatic/AMT transmission fluid and clutch packs.
enum TransmissionFluidSlipStatus {
  fluidOptimal,
  thermalBreakdownWarning,
  criticalClutchPackSlipFailure,
}

/// Dynamic telemetry measuring transmission sump temperature, clutch slip RPM, and fluid oxidation.
class TransmissionFluidTelemetry {
  final double transmissionSumpTemperatureCelsius; // Normal: 75 - 95°C. Oxidation accelerates > 105°C. Critical > 125°C.
  final double clutchSlipRpmDelta; // Speed sensor delta between torque converter output & input shaft. Normal < 40 RPM. Slip > 150 RPM.
  final double fluidDielectricOxidationIndex; // Dielectric constant: Clean fluid: 2.1 - 2.5. Oxidized varnish > 4.5.
  final double linePressureKPa; // Main hydraulic clutch apply pressure: Nominal 1200 - 1800 kPa. Low pressure < 850 kPa.
  final double shiftEngagementTimeSeconds; // Shift duration: Normal 0.4 - 0.7s. Flare/delayed shift > 1.4s.
  final double operatingHoursOnFluid;

  const TransmissionFluidTelemetry({
    required this.transmissionSumpTemperatureCelsius,
    required this.clutchSlipRpmDelta,
    required this.fluidDielectricOxidationIndex,
    required this.linePressureKPa,
    required this.shiftEngagementTimeSeconds,
    required this.operatingHoursOnFluid,
  });

  /// Remaining fluid chemical life percentage before thermal varnish breakdown.
  double get remainingFluidLifePercent =>
      (100.0 - (operatingHoursOnFluid / 2000.0) * 100.0).clamp(0.0, 100.0);
}

/// Transmission fluid oxidation and clutch lockup evaluation result.
class TransmissionFluidAuditResult {
  final String vehicleId;
  final TransmissionFluidSlipStatus status;
  final double sumpTempCelsius;
  final double clutchSlipRpm;
  final double fluidOxidationIndex;
  final double linePressureKPa;
  final double shiftTimeSec;
  final double fluidLifePercent;
  final String serviceAdvisory;

  const TransmissionFluidAuditResult({
    required this.vehicleId,
    required this.status,
    required this.sumpTempCelsius,
    required this.clutchSlipRpm,
    required this.fluidOxidationIndex,
    required this.linePressureKPa,
    required this.shiftTimeSec,
    required this.fluidLifePercent,
    required this.serviceAdvisory,
  });

  bool get isTransmissionHealthy => status == TransmissionFluidSlipStatus.fluidOptimal;
  bool get isClutchSlipFatalRisk =>
      status == TransmissionFluidSlipStatus.criticalClutchPackSlipFailure;
}

/// Evaluates automatic transmission fluid thermal breakdown, friction modifier depletion, and clutch plate slip flare.
class TransmissionFluidSlipService {
  const TransmissionFluidSlipService();

  TransmissionFluidAuditResult auditTransmission({
    required String vehicleId,
    required TransmissionFluidTelemetry telemetry,
  }) {
    final fluidLife = telemetry.remainingFluidLifePercent;

    // 1. Critical: Severe clutch slip > 160 RPM, line pressure collapse < 850 kPa, or extreme temperature > 125°C
    if (telemetry.clutchSlipRpmDelta >= 160.0 ||
        telemetry.linePressureKPa <= 850.0 ||
        telemetry.transmissionSumpTemperatureCelsius >= 125.0 ||
        telemetry.shiftEngagementTimeSeconds >= 1.5) {
      return TransmissionFluidAuditResult(
        vehicleId: vehicleId,
        status: TransmissionFluidSlipStatus.criticalClutchPackSlipFailure,
        sumpTempCelsius: telemetry.transmissionSumpTemperatureCelsius,
        clutchSlipRpm: telemetry.clutchSlipRpmDelta,
        fluidOxidationIndex: telemetry.fluidDielectricOxidationIndex,
        linePressureKPa: telemetry.linePressureKPa,
        shiftTimeSec: telemetry.shiftEngagementTimeSeconds,
        fluidLifePercent: 0.0,
        serviceAdvisory:
            'CRITICAL HAZARD: Excessive clutch pack slip flare (${telemetry.clutchSlipRpmDelta.toStringAsFixed(0)} RPM delta) or hydraulic pressure collapse! Sump overheating will glaze friction discs. Stop vehicle immediately to avoid total transmission seizure.',
      );
    }

    // 2. Warning: Sump temp > 105°C, fluid oxidation high, or shift flare > 1.0s
    if (telemetry.transmissionSumpTemperatureCelsius >= 105.0 ||
        telemetry.clutchSlipRpmDelta >= 75.0 ||
        telemetry.fluidDielectricOxidationIndex >= 3.8 ||
        telemetry.shiftEngagementTimeSeconds >= 1.0 ||
        telemetry.linePressureKPa <= 1000.0) {
      return TransmissionFluidAuditResult(
        vehicleId: vehicleId,
        status: TransmissionFluidSlipStatus.thermalBreakdownWarning,
        sumpTempCelsius: telemetry.transmissionSumpTemperatureCelsius,
        clutchSlipRpm: telemetry.clutchSlipRpmDelta,
        fluidOxidationIndex: telemetry.fluidDielectricOxidationIndex,
        linePressureKPa: telemetry.linePressureKPa,
        shiftTimeSec: telemetry.shiftEngagementTimeSeconds,
        fluidLifePercent: fluidLife,
        serviceAdvisory:
            'WARNING: Transmission fluid thermal stress detected (${telemetry.transmissionSumpTemperatureCelsius.toStringAsFixed(1)} °C). Fluid oxidation index indicates friction modifier shearing. Schedule ATF flush and transmission oil cooler inspection.',
      );
    }

    // 3. Normal fluid operation
    return TransmissionFluidAuditResult(
      vehicleId: vehicleId,
      status: TransmissionFluidSlipStatus.fluidOptimal,
      sumpTempCelsius: telemetry.transmissionSumpTemperatureCelsius,
      clutchSlipRpm: telemetry.clutchSlipRpmDelta,
      fluidOxidationIndex: telemetry.fluidDielectricOxidationIndex,
      linePressureKPa: telemetry.linePressureKPa,
      shiftTimeSec: telemetry.shiftEngagementTimeSeconds,
      fluidLifePercent: fluidLife,
      serviceAdvisory:
          'NOMINAL: Automatic transmission fluid viscosity, line pressure, and clutch engagement lockup timing within optimal range.',
    );
  }
}
