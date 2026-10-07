/// Battery module dielectric liquid flow, immersion cooling, and vapour chamber dry-out condition.
enum ImmersionCoolingStatus {
  dielectricFlowNominal,
  vapourBubbleBoilWarning,
  criticalDryoutThermalRunawayHazard,
}

/// Dynamic micro-pressure, temperature, and refractive fluid sensors inside immersed battery cell packs.
class ImmersionCoolingTelemetry {
  final double dielectricFluidFlowLitersPerMin; // Nominal immersion circulation: 25 - 60 L/min. Starvation < 12 L/min.
  final double dielectricFluidInletTemperatureCelsius; // Nominal: 22 - 35°C. Warning > 48°C.
  final double dielectricFluidOutletTemperatureCelsius;
  final double vapourBubbleOpticalFractionPercent; // Optical void fraction: Clean liquid: < 2%. Two-phase boiling > 15%. Dry-out > 35%.
  final double packHeatFluxWattsPerCm2; // High-power extreme charging heat dissipation.
  final double dielectricBreakdownVoltageKiloVolts; // Fluid purity: New > 45 kV. Contaminated water ingress < 25 kV.

  const ImmersionCoolingTelemetry({
    required this.dielectricFluidFlowLitersPerMin,
    required this.dielectricFluidInletTemperatureCelsius,
    required this.dielectricFluidOutletTemperatureCelsius,
    required this.vapourBubbleOpticalFractionPercent,
    required this.packHeatFluxWattsPerCm2,
    required this.dielectricBreakdownVoltageKiloVolts,
  });

  /// Thermal delta between dielectric fluid inlet and outlet ports.
  double get fluidTemperatureDeltaCelsius =>
      (dielectricFluidOutletTemperatureCelsius - dielectricFluidInletTemperatureCelsius).abs();

  /// Critical boiling dry-out state: Vapour gas blanket insulating cell surface from liquid.
  bool get isCellSurfaceDryoutVapourLocked =>
      vapourBubbleOpticalFractionPercent >= 28.0 || dielectricFluidFlowLitersPerMin < 8.0;
}

/// Audit result for direct-contact cell immersion cooling, nucleate boiling management, and fluid dielectric purity.
class ImmersionCoolingAuditResult {
  final String vehicleId;
  final ImmersionCoolingStatus status;
  final double flowLitersPerMin;
  final double deltaTempCelsius;
  final double vapourFractionPercent;
  final double dielectricKv;
  final String thermalAdvisory;

  const ImmersionCoolingAuditResult({
    required this.vehicleId,
    required this.status,
    required this.flowLitersPerMin,
    required this.deltaTempCelsius,
    required this.vapourFractionPercent,
    required this.dielectricKv,
    required this.thermalAdvisory,
  });

  bool get isCoolingOptimal => status == ImmersionCoolingStatus.dielectricFlowNominal;
  bool get isThermalRunawayDryoutCritical =>
      status == ImmersionCoolingStatus.criticalDryoutThermalRunawayHazard;
}

/// Evaluates direct-to-cell liquid immersion cooling, dielectric fluid breakdown, and vapour blanket film boiling dry-out.
class ImmersionCoolingAuditorService {
  const ImmersionCoolingAuditorService();

  ImmersionCoolingAuditResult auditImmersionCooling({
    required String vehicleId,
    required ImmersionCoolingTelemetry telemetry,
  }) {
    final deltaTemp = telemetry.fluidTemperatureDeltaCelsius;
    final dryout = telemetry.isCellSurfaceDryoutVapourLocked;

    // 1. Critical: Vapour film boiling dryout (cells insulated by gas bubble), flow starvation < 8 L/min, or fluid dielectric collapse < 25 kV
    if (dryout ||
        telemetry.dielectricBreakdownVoltageKiloVolts <= 25.0 ||
        telemetry.dielectricFluidOutletTemperatureCelsius >= 68.0 ||
        telemetry.vapourBubbleOpticalFractionPercent >= 30.0) {
      return ImmersionCoolingAuditResult(
        vehicleId: vehicleId,
        status: ImmersionCoolingStatus.criticalDryoutThermalRunawayHazard,
        flowLitersPerMin: telemetry.dielectricFluidFlowLitersPerMin,
        deltaTempCelsius: deltaTemp,
        vapourFractionPercent: telemetry.vapourBubbleOpticalFractionPercent,
        dielectricKv: telemetry.dielectricBreakdownVoltageKiloVolts,
        thermalAdvisory:
            'CRITICAL IMMERSION DRY-OUT: Cell surface vapour blanket boiling (${telemetry.vapourBubbleOpticalFractionPercent.toStringAsFixed(0)}% gas void) or dielectric insulation failure (${telemetry.dielectricBreakdownVoltageKiloVolts.toStringAsFixed(0)} kV)! Rapid cell hot-spot propagation will ignite electrolyte. Abort charge immediately.',
      );
    }

    // 2. Warning: Vapour boiling onset > 10% or flow rate < 18 L/min
    if (telemetry.vapourBubbleOpticalFractionPercent >= 10.0 ||
        telemetry.dielectricFluidFlowLitersPerMin < 18.0 ||
        telemetry.dielectricFluidOutletTemperatureCelsius >= 50.0 ||
        deltaTemp >= 14.0) {
      return ImmersionCoolingAuditResult(
        vehicleId: vehicleId,
        status: ImmersionCoolingStatus.vapourBubbleBoilWarning,
        flowLitersPerMin: telemetry.dielectricFluidFlowLitersPerMin,
        deltaTempCelsius: deltaTemp,
        vapourFractionPercent: telemetry.vapourBubbleOpticalFractionPercent,
        dielectricKv: telemetry.dielectricBreakdownVoltageKiloVolts,
        thermalAdvisory:
            'WARNING: Dielectric immersion fluid two-phase boiling onset detected (Void: ${telemetry.vapourBubbleOpticalFractionPercent.toStringAsFixed(1)}%). Ramp electric pump to 100% duty cycle to sweep vapour bubbles away from cell terminals.',
      );
    }

    // 3. Normal nominal single-phase liquid immersion
    return ImmersionCoolingAuditResult(
      vehicleId: vehicleId,
      status: ImmersionCoolingStatus.dielectricFlowNominal,
      flowLitersPerMin: telemetry.dielectricFluidFlowLitersPerMin,
      deltaTempCelsius: deltaTemp,
      vapourFractionPercent: telemetry.vapourBubbleOpticalFractionPercent,
      dielectricKv: telemetry.dielectricBreakdownVoltageKiloVolts,
      thermalAdvisory:
          'NOMINAL: Dielectric synthetic hydrocarbon fluid flow is uniform with zero cell dry-out or moisture contamination.',
    );
  }
}
