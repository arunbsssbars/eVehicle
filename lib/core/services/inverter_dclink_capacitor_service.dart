/// Health status of the high-voltage inverter DC-link capacitor bank.
enum InverterDcLinkStatus {
  capacitanceNominal,
  highRippleDegradationWarning,
  criticalDielectricBreakdownRisk,
}

/// High-speed oscilloscope telemetry measuring high-voltage inverter DC-bus stability.
class InverterDcLinkTelemetry {
  final double measuredCapacitanceMicroFarads; // Rated: ~600 µF. EOL discard threshold: < 480 µF (-20%).
  final double ratedCapacitanceMicroFarads;
  final double dcBusVoltageVolts; // Nominal: 400V or 800V architecture.
  final double peakToPeakRippleVoltageVolts; // Normal < 8V pk-pk. Excessive > 25V pk-pk.
  final double equivalentSeriesResistanceMilliOhms; // ESR: Nominal < 5 mΩ. Degraded > 18 mΩ.
  final double capacitorCoreTemperatureCelsius; // Normal: 30 - 65°C. Critical: >= 85°C.

  const InverterDcLinkTelemetry({
    required this.measuredCapacitanceMicroFarads,
    this.ratedCapacitanceMicroFarads = 600.0,
    required this.dcBusVoltageVolts,
    required this.peakToPeakRippleVoltageVolts,
    required this.equivalentSeriesResistanceMilliOhms,
    required this.capacitorCoreTemperatureCelsius,
  });

  /// Capacitance degradation percentage from factory rating.
  double get capacitanceLossPercent =>
      (((ratedCapacitanceMicroFarads - measuredCapacitanceMicroFarads) / ratedCapacitanceMicroFarads) * 100.0)
          .clamp(0.0, 100.0);

  /// Remaining capacitor health index (100% down to 0%).
  double get capacitorHealthPercent => (100.0 - capacitanceLossPercent * 5.0).clamp(0.0, 100.0);
}

/// Comprehensive high-voltage inverter DC-bus capacitor health diagnosis.
class InverterDcLinkAuditResult {
  final String vehicleId;
  final InverterDcLinkStatus status;
  final double measuredCapacitanceUf;
  final double rippleVoltageVolts;
  final double esrMilliOhms;
  final double coreTemperatureCelsius;
  final double healthPercent;
  final String advisory;

  const InverterDcLinkAuditResult({
    required this.vehicleId,
    required this.status,
    required this.measuredCapacitanceUf,
    required this.rippleVoltageVolts,
    required this.esrMilliOhms,
    required this.coreTemperatureCelsius,
    required this.healthPercent,
    required this.advisory,
  });

  bool get isCapacitorHealthy => status == InverterDcLinkStatus.capacitanceNominal;
  bool get isCriticalInverterFailureRisk =>
      status == InverterDcLinkStatus.criticalDielectricBreakdownRisk;
}

/// Evaluates high-voltage traction inverter DC-link capacitor aging, ESR degradation, and voltage ripple harmonics.
class InverterDcLinkCapacitorService {
  const InverterDcLinkCapacitorService();

  InverterDcLinkAuditResult auditCapacitorBank({
    required String vehicleId,
    required InverterDcLinkTelemetry telemetry,
  }) {
    final healthPercent = telemetry.capacitorHealthPercent;
    final capacitanceLoss = telemetry.capacitanceLossPercent;

    // 1. Critical: Capacitance lost > 20%, ripple > 28V, ESR > 20 mΩ, or core temp >= 85°C
    if (capacitanceLoss >= 20.0 ||
        telemetry.peakToPeakRippleVoltageVolts >= 28.0 ||
        telemetry.equivalentSeriesResistanceMilliOhms >= 20.0 ||
        telemetry.capacitorCoreTemperatureCelsius >= 85.0) {
      return InverterDcLinkAuditResult(
        vehicleId: vehicleId,
        status: InverterDcLinkStatus.criticalDielectricBreakdownRisk,
        measuredCapacitanceUf: telemetry.measuredCapacitanceMicroFarads,
        rippleVoltageVolts: telemetry.peakToPeakRippleVoltageVolts,
        esrMilliOhms: telemetry.equivalentSeriesResistanceMilliOhms,
        coreTemperatureCelsius: telemetry.capacitorCoreTemperatureCelsius,
        healthPercent: healthPercent,
        advisory:
            'CRITICAL HAZARD: DC-link capacitor bank dielectric breakdown imminent! High ripple (${telemetry.peakToPeakRippleVoltageVolts.toStringAsFixed(1)} Vpk-pk) threatens SiC/IGBT power modules. Inhibit rapid acceleration and replace inverter module.',
      );
    }

    // 2. Warning: Ripple > 14V or capacitance loss > 10%
    if (capacitanceLoss >= 10.0 ||
        telemetry.peakToPeakRippleVoltageVolts >= 14.0 ||
        telemetry.equivalentSeriesResistanceMilliOhms >= 12.0 ||
        telemetry.capacitorCoreTemperatureCelsius >= 70.0) {
      return InverterDcLinkAuditResult(
        vehicleId: vehicleId,
        status: InverterDcLinkStatus.highRippleDegradationWarning,
        measuredCapacitanceUf: telemetry.measuredCapacitanceMicroFarads,
        rippleVoltageVolts: telemetry.peakToPeakRippleVoltageVolts,
        esrMilliOhms: telemetry.equivalentSeriesResistanceMilliOhms,
        coreTemperatureCelsius: telemetry.capacitorCoreTemperatureCelsius,
        healthPercent: healthPercent,
        advisory:
            'WARNING: DC-link capacitor ESR aging detected (ESR: ${telemetry.equivalentSeriesResistanceMilliOhms.toStringAsFixed(1)} mΩ). Inspect traction inverter coolant flow and schedule bus capacitance recalibration.',
      );
    }

    // 3. Normal nominal capacitor performance
    return InverterDcLinkAuditResult(
      vehicleId: vehicleId,
      status: InverterDcLinkStatus.capacitanceNominal,
      measuredCapacitanceUf: telemetry.measuredCapacitanceMicroFarads,
      rippleVoltageVolts: telemetry.peakToPeakRippleVoltageVolts,
      esrMilliOhms: telemetry.equivalentSeriesResistanceMilliOhms,
      coreTemperatureCelsius: telemetry.capacitorCoreTemperatureCelsius,
      healthPercent: healthPercent,
      advisory:
          'NOMINAL: DC-link film capacitor ripple filtration and equivalent series resistance are within factory specifications.',
    );
  }
}
