import 'dart:math' as math;

/// Exhaust Gas Recirculation (EGR) valve actuation type.
enum EgrActuationType {
  electronicStepper,
  pneumaticVacuumModulated,
}

/// Telemetry reading from the EGR valve and intake manifold sensors.
class EgrTelemetry {
  final double commandedEgrPositionPercent; // 0 - 100%
  final double actualEgrPositionPercent; // 0 - 100%
  final double egrGasTemperatureCelsius; // Nominal: 120 - 320°C
  final double intakeManifoldDifferentialPressureKpa; // Delta P across venturi
  final double engineLoadPercent;

  const EgrTelemetry({
    required this.commandedEgrPositionPercent,
    required this.actualEgrPositionPercent,
    required this.egrGasTemperatureCelsius,
    required this.intakeManifoldDifferentialPressureKpa,
    required this.engineLoadPercent,
  });

  /// Position tracking error between ECU command and sensor feedback.
  double get positionTrackingErrorPercent => (actualEgrPositionPercent - commandedEgrPositionPercent).abs();
}

/// Operational status of the EGR flow and cooler assembly.
enum EgrHealthStatus {
  normalRecirculation,
  moderateSootClogging,
  criticalValveStuckOrCoolerClogged,
}

/// Comprehensive EGR audit result.
class EgrHealthResult {
  final String vehicleId;
  final EgrHealthStatus status;
  final double sootAccumulationIndexPercent; // 0 - 100%
  final double positionTrackingErrorPercent;
  final bool isCoolerThermalEfficiencyDegraded;
  final String diagnosticAction;

  const EgrHealthResult({
    required this.vehicleId,
    required this.status,
    required this.sootAccumulationIndexPercent,
    required this.positionTrackingErrorPercent,
    required this.isCoolerThermalEfficiencyDegraded,
    required this.diagnosticAction,
  });

  bool get isHealthy => status == EgrHealthStatus.normalRecirculation;
}

/// Service that diagnoses diesel EGR valve carbon fouling and cooler clogging.
class EgrFlowCarbonDiagnosticService {
  const EgrFlowCarbonDiagnosticService();

  EgrHealthResult diagnoseEgrSystem({
    required String vehicleId,
    required EgrTelemetry telemetry,
  }) {
    final error = telemetry.positionTrackingErrorPercent;
    
    // Cooler thermal efficiency degradation when gas temperature exceeds 360°C under load
    final isCoolerDegraded = telemetry.egrGasTemperatureCelsius > 350.0 && telemetry.engineLoadPercent > 50.0;

    // Estimate soot accumulation index based on position hysteresis and flow restriction
    double sootIndex = (error * 4.5).clamp(0.0, 75.0);
    if (telemetry.intakeManifoldDifferentialPressureKpa < 4.0 && telemetry.commandedEgrPositionPercent > 30.0) {
      sootIndex += 25.0; // Flow blockage despite open valve
    }
    if (isCoolerDegraded) {
      sootIndex += 15.0;
    }
    sootIndex = sootIndex.clamp(0.0, 100.0);

    // Status logic
    if (error > 18.0 || sootIndex >= 75.0 || (error > 12.0 && isCoolerDegraded)) {
      return EgrHealthResult(
        vehicleId: vehicleId,
        status: EgrHealthStatus.criticalValveStuckOrCoolerClogged,
        sootAccumulationIndexPercent: sootIndex,
        positionTrackingErrorPercent: error,
        isCoolerThermalEfficiencyDegraded: isCoolerDegraded,
        diagnosticAction:
            'CRITICAL: EGR valve stuck or cooler soot choked. High NOx emission and power loss risk. Perform chemical decarbonization or replacement.',
      );
    }

    if (error > 7.0 || sootIndex >= 35.0 || isCoolerDegraded) {
      return EgrHealthResult(
        vehicleId: vehicleId,
        status: EgrHealthStatus.moderateSootClogging,
        sootAccumulationIndexPercent: sootIndex,
        positionTrackingErrorPercent: error,
        isCoolerThermalEfficiencyDegraded: isCoolerDegraded,
        diagnosticAction:
            'WARNING: Early carbon fouling detected on EGR valve pintle. Schedule intake manifold cleaning at next scheduled service.',
      );
    }

    return EgrHealthResult(
      vehicleId: vehicleId,
      status: EgrHealthStatus.normalRecirculation,
      sootAccumulationIndexPercent: sootIndex,
      positionTrackingErrorPercent: error,
      isCoolerThermalEfficiencyDegraded: false,
      diagnosticAction:
          'NOMINAL: EGR flow rate and cooler temperature conform to emission baseline standards.',
    );
  }
}
