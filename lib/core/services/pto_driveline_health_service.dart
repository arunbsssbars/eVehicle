/// Health and friction clutch pack lockup condition of dynamic power takeoff (PTO) unit.
enum PtoDrivelineHealthStatus {
  ptoOperatingNominal,
  thermalOverloadWarning,
  criticalSplineShearAndOverTorqueHazard,
}

/// Dynamic rotational telemetry measuring PTO output shaft RPM, torque spikes, clutch temperature, and hydraulic line pressure.
class PtoDrivelineTelemetry {
  final double ptoOutputShaftRpm; // Standard 540 RPM or 1000 RPM rating.
  final double engineSpeedRpm;
  final double measuredTorqueNewtonMetres; // Normal operational torque < 900 Nm. Shear pin limit > 1800 Nm.
  final double ratedTorqueLimitNewtonMetres;
  final double ptoClutchSumpTemperatureCelsius; // Normal: 60 - 85°C. Warning > 105°C. Critical > 120°C.
  final double engagementHydraulicPressureKPa; // Normal lockup: 1600 - 2200 kPa. Clutch slip pressure < 1100 kPa.
  final double continuousOperatingHours;

  const PtoDrivelineTelemetry({
    required this.ptoOutputShaftRpm,
    required this.engineSpeedRpm,
    required this.measuredTorqueNewtonMetres,
    this.ratedTorqueLimitNewtonMetres = 1200.0,
    required this.ptoClutchSumpTemperatureCelsius,
    required this.engagementHydraulicPressureKPa,
    required this.continuousOperatingHours,
  });

  /// Ratio of output torque to rated mechanical safety limit.
  double get torqueLoadRatioPercent =>
      ((measuredTorqueNewtonMetres / ratedTorqueLimitNewtonMetres) * 100.0).clamp(0.0, 200.0);

  /// Clutch slip delta: uncommanded speed loss under high hydraulic pump / winch load.
  double get ptoGearSlipPercent {
    if (engineSpeedRpm <= 0) return 0.0;
    final theoreticalOutput = engineSpeedRpm * (1000.0 / 1800.0); // Gear ratio approx
    return (((theoreticalOutput - ptoOutputShaftRpm) / theoreticalOutput) * 100.0).clamp(0.0, 100.0);
  }
}

/// Evaluation result for auxiliary power takeoff driveline, torque shear protection, and hydraulic clutch clamp.
class PtoDrivelineAuditResult {
  final String vehicleId;
  final PtoDrivelineHealthStatus status;
  final double outputRpm;
  final double torqueNm;
  final double loadRatioPercent;
  final double sumpTempCelsius;
  final double clutchPressureKPa;
  final String operationalAdvisory;

  const PtoDrivelineAuditResult({
    required this.vehicleId,
    required this.status,
    required this.outputRpm,
    required this.torqueNm,
    required this.loadRatioPercent,
    required this.sumpTempCelsius,
    required this.clutchPressureKPa,
    required this.operationalAdvisory,
  });

  bool get isPtoRunningClean => status == PtoDrivelineHealthStatus.ptoOperatingNominal;
  bool get isShaftShearImminent =>
      status == PtoDrivelineHealthStatus.criticalSplineShearAndOverTorqueHazard;
}

/// Evaluates commercial vehicle power takeoff (PTO) output shaft torque surges, wet clutch friction plate slipping, and hydraulic pressure drop.
class PtoDrivelineHealthService {
  const PtoDrivelineHealthService();

  PtoDrivelineAuditResult auditPtoDriveline({
    required String vehicleId,
    required PtoDrivelineTelemetry telemetry,
  }) {
    final loadRatio = telemetry.torqueLoadRatioPercent;

    // 1. Critical: Torque > 140% of rating, hydraulic clutch pressure collapse (<1100 kPa), or sump > 120°C
    if (loadRatio >= 140.0 ||
        telemetry.engagementHydraulicPressureKPa <= 1100.0 ||
        telemetry.ptoClutchSumpTemperatureCelsius >= 120.0 ||
        telemetry.ptoGearSlipPercent >= 25.0) {
      return PtoDrivelineAuditResult(
        vehicleId: vehicleId,
        status: PtoDrivelineHealthStatus.criticalSplineShearAndOverTorqueHazard,
        outputRpm: telemetry.ptoOutputShaftRpm,
        torqueNm: telemetry.measuredTorqueNewtonMetres,
        loadRatioPercent: loadRatio,
        sumpTempCelsius: telemetry.ptoClutchSumpTemperatureCelsius,
        clutchPressureKPa: telemetry.engagementHydraulicPressureKPa,
        operationalAdvisory:
            'CRITICAL OVERLOAD: PTO torque surge (${telemetry.measuredTorqueNewtonMetres.toStringAsFixed(0)} Nm, ${loadRatio.toStringAsFixed(0)}% rated load) or clutch pressure collapse! Disengage PTO immediately to prevent output drive spline shear.',
      );
    }

    // 2. Warning: Torque > 105% of rated continuous, temperature elevated, or clutch pressure low
    if (loadRatio >= 105.0 ||
        telemetry.ptoClutchSumpTemperatureCelsius >= 100.0 ||
        telemetry.engagementHydraulicPressureKPa <= 1450.0 ||
        telemetry.ptoGearSlipPercent >= 10.0) {
      return PtoDrivelineAuditResult(
        vehicleId: vehicleId,
        status: PtoDrivelineHealthStatus.thermalOverloadWarning,
        outputRpm: telemetry.ptoOutputShaftRpm,
        torqueNm: telemetry.measuredTorqueNewtonMetres,
        loadRatioPercent: loadRatio,
        sumpTempCelsius: telemetry.ptoClutchSumpTemperatureCelsius,
        clutchPressureKPa: telemetry.engagementHydraulicPressureKPa,
        operationalAdvisory:
            'WARNING: PTO wet clutch thermal stress detected (${telemetry.ptoClutchSumpTemperatureCelsius.toStringAsFixed(1)}°C). Reduce auxiliary pump flow rate and verify transmission power shift solenoid valve.',
      );
    }

    // 3. Normal nominal PTO operation
    return PtoDrivelineAuditResult(
      vehicleId: vehicleId,
      status: PtoDrivelineHealthStatus.ptoOperatingNominal,
      outputRpm: telemetry.ptoOutputShaftRpm,
      torqueNm: telemetry.measuredTorqueNewtonMetres,
      loadRatioPercent: loadRatio,
      sumpTempCelsius: telemetry.ptoClutchSumpTemperatureCelsius,
      clutchPressureKPa: telemetry.engagementHydraulicPressureKPa,
      operationalAdvisory:
          'NOMINAL: Power Takeoff (PTO) output shaft torque and hydraulic clutch pack locking pressure are optimal.',
    );
  }
}
