/// Refrigerant thermodynamic cycle state.
enum ReeferCycleState {
  coolingPullDown,
  temperatureHolding,
  electricDefrostCycle,
  idleStandby,
}

/// Cargo sensitivity classification for thermal compliance.
enum CargoThermalClass {
  deepFrozenMeatFish, // -25°C to -18°C
  chilledDairyProduce, // +2°C to +4°C
  ambientPharmaChemicals, // +15°C to +25°C
}

/// Telemetry reading from the reefer unit and cargo bay sensors.
class ReeferCargoTelemetry {
  final CargoThermalClass cargoClass;
  final double setpointTemperatureCelsius;
  final double supplyAirTemperatureCelsius;
  final double returnAirTemperatureCelsius;
  final double ambientOutsideTemperatureCelsius;
  final ReeferCycleState cycleState;
  final double compressorDischargePressurePsi; // Nominal: 180 - 320 PSI
  final bool isDoorMicroswitchClosed;

  const ReeferCargoTelemetry({
    required this.cargoClass,
    required this.setpointTemperatureCelsius,
    required this.supplyAirTemperatureCelsius,
    required this.returnAirTemperatureCelsius,
    required this.ambientOutsideTemperatureCelsius,
    required this.cycleState,
    required this.compressorDischargePressurePsi,
    required this.isDoorMicroswitchClosed,
  });

  /// Delta temperature across the evaporator coil (return minus supply).
  double get evaporatorDeltaTCelsius => returnAirTemperatureCelsius - supplyAirTemperatureCelsius;

  /// Absolute cargo excursion error relative to setpoint.
  double get setpointExcursionCelsius => (returnAirTemperatureCelsius - setpointTemperatureCelsius).abs();
}

/// Cold chain compliance and compressor health status.
enum ReeferHealthStatus {
  coldChainCompliant,
  minorTemperatureExcursion,
  criticalThermalSpoilageRisk,
}

/// Evaluation result for cold chain integrity and reefer compressor health.
class ReeferColdChainResult {
  final String vehicleId;
  final ReeferHealthStatus status;
  final double cargoTemperatureCelsius;
  final double setpointTemperatureCelsius;
  final double compressorPressurePsi;
  final bool isDoorClosed;
  final double coldChainComplianceScorePercent;
  final String complianceNotice;

  const ReeferColdChainResult({
    required this.vehicleId,
    required this.status,
    required this.cargoTemperatureCelsius,
    required this.setpointTemperatureCelsius,
    required this.compressorPressurePsi,
    required this.isDoorClosed,
    required this.coldChainComplianceScorePercent,
    required this.complianceNotice,
  });

  bool get isCompliant => status == ReeferHealthStatus.coldChainCompliant;
  bool get isCritical => status == ReeferHealthStatus.criticalThermalSpoilageRisk;
}

/// Service that monitors refrigerated cargo units and alerts cold chain excursions.
class ReeferColdChainGuardService {
  const ReeferColdChainGuardService();

  ReeferColdChainResult evaluateColdChain({
    required String vehicleId,
    required ReeferCargoTelemetry telemetry,
  }) {
    final excursion = telemetry.setpointExcursionCelsius;
    final isOverPressure = telemetry.compressorDischargePressurePsi > 400.0;
    final isLowPressure = telemetry.compressorDischargePressurePsi < 110.0;

    // Calculate cold chain compliance score (0 - 100%)
    double score = 100.0;
    if (excursion > 1.0) {
      score -= (excursion * 12.0).clamp(0.0, 60.0);
    }
    if (!telemetry.isDoorMicroswitchClosed) {
      score -= 30.0;
    }
    if (isOverPressure || isLowPressure) {
      score -= 25.0;
    }
    score = score.clamp(0.0, 100.0);

    // Critical conditions: excursion > 4°C, doors open, or compressor discharge failure
    if (excursion > 4.5 || !telemetry.isDoorMicroswitchClosed || isOverPressure) {
      return ReeferColdChainResult(
        vehicleId: vehicleId,
        status: ReeferHealthStatus.criticalThermalSpoilageRisk,
        cargoTemperatureCelsius: telemetry.returnAirTemperatureCelsius,
        setpointTemperatureCelsius: telemetry.setpointTemperatureCelsius,
        compressorPressurePsi: telemetry.compressorDischargePressurePsi,
        isDoorClosed: telemetry.isDoorMicroswitchClosed,
        coldChainComplianceScorePercent: score,
        complianceNotice:
            'CRITICAL: Cold chain breach! Return air +${excursion.toStringAsFixed(1)}°C off setpoint or rear door open. Perishable cargo spoilage imminent.',
      );
    }

    if (excursion > 2.0 || isLowPressure) {
      return ReeferColdChainResult(
        vehicleId: vehicleId,
        status: ReeferHealthStatus.minorTemperatureExcursion,
        cargoTemperatureCelsius: telemetry.returnAirTemperatureCelsius,
        setpointTemperatureCelsius: telemetry.setpointTemperatureCelsius,
        compressorPressurePsi: telemetry.compressorDischargePressurePsi,
        isDoorClosed: telemetry.isDoorMicroswitchClosed,
        coldChainComplianceScorePercent: score,
        complianceNotice:
            'WARNING: Minor cargo temperature excursion. Monitor compressor pull-down duty cycle and thermal insulation curtains.',
      );
    }

    return ReeferColdChainResult(
      vehicleId: vehicleId,
      status: ReeferHealthStatus.coldChainCompliant,
      cargoTemperatureCelsius: telemetry.returnAirTemperatureCelsius,
      setpointTemperatureCelsius: telemetry.setpointTemperatureCelsius,
      compressorPressurePsi: telemetry.compressorDischargePressurePsi,
      isDoorClosed: telemetry.isDoorMicroswitchClosed,
      coldChainComplianceScorePercent: score,
      complianceNotice:
          'NOMINAL: Cold chain cargo within regulated pharmaceutical & food safety tolerance bounds.',
    );
  }
}
