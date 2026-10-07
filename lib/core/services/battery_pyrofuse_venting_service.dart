/// Status of EV battery pack safety release & pyrofuse integrity.
enum PyrofuseVentingStatus {
  sealedAndIntact,
  pressureWarningVentingInitiated,
  emergencyPyrofuseDetonated,
}

/// Real-time sensory telemetry from battery pack pressure, gas composition, and pyro-disconnect circuits.
class BatteryThermalSafetyTelemetry {
  final double packInternalPressureKPa; // Nominal: 98 - 104 kPa (1 atm). Rupture disc blows at >= 135 kPa.
  final double ventGasHydrogenPpm; // H2 gas from electrolyte breakdown (>500 ppm indicates off-gassing).
  final double carbonMonoxidePpm; // CO gas (>200 ppm indicates active thermal degradation).
  final double maxCellTemperatureCelsius; // Normal: 15-45°C. Critical: >= 70°C.
  final double cellTemperatureRiseRateCPerSec; // dT/dt > 1.0 °C/sec indicates runaway propagation.
  final bool isPyrofuseCircuitLoopClosed; // High-speed squib circuit continuity (True = armed & intact, False = triggered/open).
  final double packCurrentAmperes; // Normal or short-circuit (>2000A in fault).

  const BatteryThermalSafetyTelemetry({
    required this.packInternalPressureKPa,
    required this.ventGasHydrogenPpm,
    required this.carbonMonoxidePpm,
    required this.maxCellTemperatureCelsius,
    required this.cellTemperatureRiseRateCPerSec,
    required this.isPyrofuseCircuitLoopClosed,
    required this.packCurrentAmperes,
  });

  /// High-risk off-gas detected in enclosure.
  bool get isElectrolyteOffGassingDetected => ventGasHydrogenPpm > 350.0 || carbonMonoxidePpm > 150.0;
}

/// Comprehensive safety diagnosis for thermal runaway prevention and HV isolation severance.
class BatteryThermalRunawayResult {
  final String vehicleId;
  final PyrofuseVentingStatus status;
  final double enclosurePressureKPa;
  final double hydrogenPpm;
  final double maxCellTempCelsius;
  final double temperatureRiseRate;
  final bool isHighVoltageSevered;
  final String safetyAdvisory;

  const BatteryThermalRunawayResult({
    required this.vehicleId,
    required this.status,
    required this.enclosurePressureKPa,
    required this.hydrogenPpm,
    required this.maxCellTempCelsius,
    required this.temperatureRiseRate,
    required this.isHighVoltageSevered,
    required this.safetyAdvisory,
  });

  bool get isSafeToOperate => status == PyrofuseVentingStatus.sealedAndIntact;
  bool get isEvacuationMandatory => status == PyrofuseVentingStatus.emergencyPyrofuseDetonated;
}

/// Evaluates EV battery pack thermal runway precursors, blast valve venting, and high-voltage pyro-fuse disconnect.
class BatteryPyrofuseVentingService {
  const BatteryPyrofuseVentingService();

  BatteryThermalRunawayResult evaluateSafety({
    required String vehicleId,
    required BatteryThermalSafetyTelemetry telemetry,
  }) {
    // 1. Pyrofuse blown or violent cell runaway triggers emergency high-voltage disconnect
    final pyrofuseDetonated = !telemetry.isPyrofuseCircuitLoopClosed;
    final runawayUnstoppable = telemetry.maxCellTemperatureCelsius >= 75.0 ||
        telemetry.cellTemperatureRiseRateCPerSec >= 1.5 ||
        telemetry.packInternalPressureKPa >= 140.0;

    if (pyrofuseDetonated || runawayUnstoppable) {
      return BatteryThermalRunawayResult(
        vehicleId: vehicleId,
        status: PyrofuseVentingStatus.emergencyPyrofuseDetonated,
        enclosurePressureKPa: telemetry.packInternalPressureKPa,
        hydrogenPpm: telemetry.ventGasHydrogenPpm,
        maxCellTempCelsius: telemetry.maxCellTemperatureCelsius,
        temperatureRiseRate: telemetry.cellTemperatureRiseRateCPerSec,
        isHighVoltageSevered: true,
        safetyAdvisory:
            'CRITICAL EMERGENCY: Thermal runaway propagation detected! High-voltage pyrofuse squib triggered. Isolate vehicle perimeter and evacuate immediately.',
      );
    }

    // 2. Pre-runaway off-gassing or pressure valve burst warning
    if (telemetry.packInternalPressureKPa >= 118.0 ||
        telemetry.isElectrolyteOffGassingDetected ||
        telemetry.maxCellTemperatureCelsius >= 55.0 ||
        telemetry.cellTemperatureRiseRateCPerSec >= 0.5) {
      return BatteryThermalRunawayResult(
        vehicleId: vehicleId,
        status: PyrofuseVentingStatus.pressureWarningVentingInitiated,
        enclosurePressureKPa: telemetry.packInternalPressureKPa,
        hydrogenPpm: telemetry.ventGasHydrogenPpm,
        maxCellTempCelsius: telemetry.maxCellTemperatureCelsius,
        temperatureRiseRate: telemetry.cellTemperatureRiseRateCPerSec,
        isHighVoltageSevered: false,
        safetyAdvisory:
            'WARNING: Cell electrolyte venting or anomalous pressure rise (${telemetry.packInternalPressureKPa.toStringAsFixed(1)} kPa). Max cooling commanded, halt charging and inspect thermal management.',
      );
    }

    // 3. Normal nominal pack containment
    return BatteryThermalRunawayResult(
      vehicleId: vehicleId,
      status: PyrofuseVentingStatus.sealedAndIntact,
      enclosurePressureKPa: telemetry.packInternalPressureKPa,
      hydrogenPpm: telemetry.ventGasHydrogenPpm,
      maxCellTempCelsius: telemetry.maxCellTemperatureCelsius,
      temperatureRiseRate: telemetry.cellTemperatureRiseRateCPerSec,
      isHighVoltageSevered: false,
      safetyAdvisory:
          'NOMINAL: Battery enclosure pressure and gas sensors report inert containment. Pyrofuse circuit armed and intact.',
    );
  }
}
