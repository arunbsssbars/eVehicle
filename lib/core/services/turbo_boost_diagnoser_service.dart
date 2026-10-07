/// Engine intake and boost airflow telemetry sample.
class TurboIntakeTelemetry {
  final double ambientPressureBar;
  final double manifoldAbsolutePressureBar; // Boost pressure
  final double airFilterDifferentialPressureMbar; // Vacuum drop across air filter
  final double massAirFlowGramsPerSec;
  final double intakeAirTemperatureCelsius;
  final double turboShaftSpeedRpm;
  final double exhaustGasRecirculationPercent;

  const TurboIntakeTelemetry({
    this.ambientPressureBar = 1.0,
    required this.manifoldAbsolutePressureBar,
    required this.airFilterDifferentialPressureMbar,
    required this.massAirFlowGramsPerSec,
    required this.intakeAirTemperatureCelsius,
    this.turboShaftSpeedRpm = 120000.0,
    this.exhaustGasRecirculationPercent = 15.0,
  });

  /// Net boost pressure above ambient in Bar.
  double get netGaugeBoostBar =>
      (manifoldAbsolutePressureBar - ambientPressureBar).clamp(0.0, 5.0);
}

/// Air intake and turbocharger operational health status.
enum IntakeHealthStatus {
  normal,
  airFilterRestrictionWarning,
  boostLeakOrUnderboostCritical,
}

/// Evaluation result for turbocharger boost efficiency and intake restriction.
class TurboBoostAuditResult {
  final String vehicleId;
  final IntakeHealthStatus status;
  final double gaugeBoostBar;
  final double filterRestrictionMbar;
  final double volumetricEfficiencyPercent;
  final bool isIntercoolerHeatSoaked;
  final String diagnosticAdvice;

  const TurboBoostAuditResult({
    required this.vehicleId,
    required this.status,
    required this.gaugeBoostBar,
    required this.filterRestrictionMbar,
    required this.volumetricEfficiencyPercent,
    required this.isIntercoolerHeatSoaked,
    required this.diagnosticAdvice,
  });

  bool get isSafe => status == IntakeHealthStatus.normal;
}

/// Turbocharger Boost Pressure & Air Intake Restriction Diagnoser Service.
class TurboBoostDiagnoserService {
  const TurboBoostDiagnoserService();

  // Thresholds
  static const double airFilterRestrictionLimitMbar = 25.0; // Heavy soot / dirt loading
  static const double minimumExpectedBoostBar = 1.2;        // For heavy diesel at full torque demand
  static const double intercoolerHeatSoakTempCelsius = 60.0;

  TurboBoostAuditResult evaluateBoostPerformance({
    required String vehicleId,
    required TurboIntakeTelemetry telemetry,
    bool isUnderFullEngineLoad = true,
  }) {
    final filterClogged = telemetry.airFilterDifferentialPressureMbar >= airFilterRestrictionLimitMbar;
    final isHeatSoaked = telemetry.intakeAirTemperatureCelsius >= intercoolerHeatSoakTempCelsius;
    final underboost = isUnderFullEngineLoad && telemetry.netGaugeBoostBar < minimumExpectedBoostBar;

    // Approximate volumetric efficiency
    double volumetricEff = 92.0;
    if (filterClogged) volumetricEff -= 12.0;
    if (isHeatSoaked) volumetricEff -= 8.0;
    if (underboost) volumetricEff -= 15.0;
    volumetricEff = volumetricEff.clamp(50.0, 98.0);

    IntakeHealthStatus status;
    String advice;

    if (underboost) {
      status = IntakeHealthStatus.boostLeakOrUnderboostCritical;
      advice = 'UNDERBOOST CRITICAL: Manifold boost pressure (${telemetry.netGaugeBoostBar.toStringAsFixed(2)} Bar) below target. Inspect charge-air pipes, intercooler boots, and wastegate.';
    } else if (filterClogged) {
      status = IntakeHealthStatus.airFilterRestrictionWarning;
      advice = 'INTAKE RESTRICTION: Air filter differential vacuum (${telemetry.airFilterDifferentialPressureMbar.toStringAsFixed(1)} mbar) exceeds threshold. Replace primary air filter cartridge.';
    } else {
      status = IntakeHealthStatus.normal;
      advice = 'Turbocharger spool, compressor surge margin, and charge-air cooling within nominal parameters.';
    }

    return TurboBoostAuditResult(
      vehicleId: vehicleId,
      status: status,
      gaugeBoostBar: double.parse(telemetry.netGaugeBoostBar.toStringAsFixed(2)),
      filterRestrictionMbar: double.parse(telemetry.airFilterDifferentialPressureMbar.toStringAsFixed(1)),
      volumetricEfficiencyPercent: double.parse(volumetricEff.toStringAsFixed(1)),
      isIntercoolerHeatSoaked: isHeatSoaked,
      diagnosticAdvice: advice,
    );
  }
}
