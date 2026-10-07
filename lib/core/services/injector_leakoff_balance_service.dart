/// High-pressure common-rail fuel injector piezo stack charging and needle leakage status.
enum InjectorLeakoffBalanceStatus {
  injectorsBalancedNominal,
  excessiveLeakoffReturnWarning,
  criticalNeedleSeizureCylinderMisfire,
}

/// Dynamic cylinder-individual telemetry measuring common-rail injector back-leak return, piezo capacitance, and pilot fuel delivery.
class InjectorLeakoffTelemetry {
  final int cylinderNumber;
  final double returnFuelLeakoffMillilitersPerMinute; // Normal idle: 15 - 35 mL/min. High wear > 70 mL/min.
  final double pilotInjectionQuantityMm3; // Pilot injection: ~1.5 - 2.5 mm³/stroke.
  final double piezoActuatorCapacitanceMicroFarads; // Nominal: 2.8 - 3.4 µF. Stack degradation < 2.2 µF.
  final double cylinderSmoothRunningContributionRpm; // Cylinder balance correction (Normal < +/- 15 RPM. Misfire > 60 RPM).
  final double injectorBodyTemperatureCelsius;

  const InjectorLeakoffTelemetry({
    required this.cylinderNumber,
    required this.returnFuelLeakoffMillilitersPerMinute,
    required this.pilotInjectionQuantityMm3,
    required this.piezoActuatorCapacitanceMicroFarads,
    required this.cylinderSmoothRunningContributionRpm,
    required this.injectorBodyTemperatureCelsius,
  });

  /// Cylinder roughness deviation from engine balance baseline.
  double get roughnessDeviationRpm => cylinderSmoothRunningContributionRpm.abs();
}

/// Audit result for common rail diesel injector nozzle needle balance, return flow, and piezo actuator integrity.
class InjectorLeakoffAuditResult {
  final String vehicleId;
  final int cylinderNumber;
  final InjectorLeakoffBalanceStatus status;
  final double leakoffMlPerMin;
  final double piezoCapacitanceUf;
  final double roughnessRpm;
  final String serviceAdvisory;

  const InjectorLeakoffAuditResult({
    required this.vehicleId,
    required this.cylinderNumber,
    required this.status,
    required this.leakoffMlPerMin,
    required this.piezoCapacitanceUf,
    required this.roughnessRpm,
    required this.serviceAdvisory,
  });

  bool get isInjectorHealthy => status == InjectorLeakoffBalanceStatus.injectorsBalancedNominal;
  bool get isCylinderMisfireSevere =>
      status == InjectorLeakoffBalanceStatus.criticalNeedleSeizureCylinderMisfire;
}

/// Evaluates common-rail fuel injector back-leak return volume, pilot pre-injection drift, and piezo ceramic stack degradation.
class InjectorLeakoffBalanceService {
  const InjectorLeakoffBalanceService();

  InjectorLeakoffAuditResult auditInjector({
    required String vehicleId,
    required InjectorLeakoffTelemetry telemetry,
  }) {
    final roughness = telemetry.roughnessDeviationRpm;

    // 1. Critical: Return leakoff > 90 mL/min, piezo capacitance < 2.0 µF, or cylinder misfire roughness > 75 RPM
    if (telemetry.returnFuelLeakoffMillilitersPerMinute >= 90.0 ||
        telemetry.piezoActuatorCapacitanceMicroFarads < 2.0 ||
        roughness >= 75.0 ||
        telemetry.pilotInjectionQuantityMm3 <= 0.4) {
      return InjectorLeakoffAuditResult(
        vehicleId: vehicleId,
        cylinderNumber: telemetry.cylinderNumber,
        status: InjectorLeakoffBalanceStatus.criticalNeedleSeizureCylinderMisfire,
        leakoffMlPerMin: telemetry.returnFuelLeakoffMillilitersPerMinute,
        piezoCapacitanceUf: telemetry.piezoActuatorCapacitanceMicroFarads,
        roughnessRpm: roughness,
        serviceAdvisory:
            'CRITICAL INJECTOR FAULT: Cylinder #${telemetry.cylinderNumber} injector needle stuck or internal control valve blown (${telemetry.returnFuelLeakoffMillilitersPerMinute.toStringAsFixed(0)} mL/min return)! High leakoff bleeds rail pressure causing hard starting and piston crown erosion.',
      );
    }

    // 2. Warning: Return flow > 55 mL/min, piezo capacitance < 2.5 µF, or roughness > 30 RPM
    if (telemetry.returnFuelLeakoffMillilitersPerMinute >= 55.0 ||
        telemetry.piezoActuatorCapacitanceMicroFarads < 2.5 ||
        roughness >= 30.0 ||
        telemetry.injectorBodyTemperatureCelsius >= 115.0) {
      return InjectorLeakoffAuditResult(
        vehicleId: vehicleId,
        cylinderNumber: telemetry.cylinderNumber,
        status: InjectorLeakoffBalanceStatus.excessiveLeakoffReturnWarning,
        leakoffMlPerMin: telemetry.returnFuelLeakoffMillilitersPerMinute,
        piezoCapacitanceUf: telemetry.piezoActuatorCapacitanceMicroFarads,
        roughnessRpm: roughness,
        serviceAdvisory:
            'WARNING: Cylinder #${telemetry.cylinderNumber} back-leak return flow elevated (${telemetry.returnFuelLeakoffMillilitersPerMinute.toStringAsFixed(0)} mL/min). Piezo ceramic actuator aging detected. Perform cylinder balance and IMA code calibration.',
      );
    }

    // 3. Normal nominal injector performance
    return InjectorLeakoffAuditResult(
      vehicleId: vehicleId,
      cylinderNumber: telemetry.cylinderNumber,
      status: InjectorLeakoffBalanceStatus.injectorsBalancedNominal,
      leakoffMlPerMin: telemetry.returnFuelLeakoffMillilitersPerMinute,
      piezoCapacitanceUf: telemetry.piezoActuatorCapacitanceMicroFarads,
      roughnessRpm: roughness,
      serviceAdvisory:
          'NOMINAL: Injector nozzle needle response, pilot pre-injection atomization, and back-leak return flow within factory calibrated limits.',
    );
  }
}
