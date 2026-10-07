/// Hydraulic fluid health condition.
enum FluidDegradationStatus {
  pristineCleanFluid,
  particulateOrWaterIngressWarning,
  criticalCavitationAndVarnishRisk,
}

/// Telemetry reading from the hydraulic circuit fluid sensors.
class HydraulicFluidTelemetry {
  final double isoParticleCountCode; // ISO 4406 cleanliness code index (e.g. 14 to 24)
  final double waterContentPpm; // Nominal: < 300 PPM. Free water > 800 PPM
  final double dynamicViscosityCSt; // 40°C kinematic viscosity (Nominal ISO VG 46: 41 - 50 cSt)
  final double fluidTemperatureCelsius; // Nominal: 45 - 65°C. Critical: > 85°C
  final double pumpSuctionPressureBar; // Cavitation risk when suction < -0.2 bar

  const HydraulicFluidTelemetry({
    required this.isoParticleCountCode,
    required this.waterContentPpm,
    required this.dynamicViscosityCSt,
    required this.fluidTemperatureCelsius,
    required this.pumpSuctionPressureBar,
  });
}

/// Evaluation result for hydraulic liftgate & tipper oil health.
class HydraulicOilHealthResult {
  final String vehicleId;
  final FluidDegradationStatus status;
  final double isoParticleCode;
  final double waterPpm;
  final double fluidTempCelsius;
  final double fluidQualityIndexPercent; // 0 - 100%
  final String maintenanceDirective;

  const HydraulicOilHealthResult({
    required this.vehicleId,
    required this.status,
    required this.isoParticleCode,
    required this.waterPpm,
    required this.fluidTempCelsius,
    required this.fluidQualityIndexPercent,
    required this.maintenanceDirective,
  });

  bool get isClean => status == FluidDegradationStatus.pristineCleanFluid;
  bool get isCritical => status == FluidDegradationStatus.criticalCavitationAndVarnishRisk;
}

/// Service that monitors tipper & liftgate hydraulic oil particulate contamination and thermal varnish.
class HydraulicFluidHealthService {
  const HydraulicFluidHealthService();

  HydraulicOilHealthResult auditHydraulicOil({
    required String vehicleId,
    required HydraulicFluidTelemetry telemetry,
  }) {
    final isWaterExcessive = telemetry.waterContentPpm > 800.0;
    final isParticleSevere = telemetry.isoParticleCountCode >= 21.0;
    final isThermalVarnish = telemetry.fluidTemperatureCelsius > 85.0;
    final isCavitationRisk = telemetry.pumpSuctionPressureBar < -0.25;

    // Quality Score calculation (0 - 100%)
    double score = 100.0;
    if (telemetry.waterContentPpm > 300.0) {
      score -= ((telemetry.waterContentPpm - 300.0) * 0.06).clamp(0.0, 40.0);
    }
    if (telemetry.isoParticleCountCode > 16.0) {
      score -= ((telemetry.isoParticleCountCode - 16.0) * 8.0).clamp(0.0, 40.0);
    }
    if (isThermalVarnish) {
      score -= 20.0;
    }
    score = score.clamp(0.0, 100.0);

    // Critical conditions
    if (isWaterExcessive || isParticleSevere || (isThermalVarnish && isCavitationRisk)) {
      return HydraulicOilHealthResult(
        vehicleId: vehicleId,
        status: FluidDegradationStatus.criticalCavitationAndVarnishRisk,
        isoParticleCode: telemetry.isoParticleCountCode,
        waterPpm: telemetry.waterContentPpm,
        fluidTempCelsius: telemetry.fluidTemperatureCelsius,
        fluidQualityIndexPercent: score,
        maintenanceDirective:
            'CRITICAL: Severe hydraulic oil contamination (>800 PPM H2O or ISO 21+ particulates). High pump cavitation & spool valve sticking risk. Flush system immediately.',
      );
    }

    if (telemetry.waterContentPpm > 450.0 || telemetry.isoParticleCountCode >= 18.0 || isThermalVarnish) {
      return HydraulicOilHealthResult(
        vehicleId: vehicleId,
        status: FluidDegradationStatus.particulateOrWaterIngressWarning,
        isoParticleCode: telemetry.isoParticleCountCode,
        waterPpm: telemetry.waterContentPpm,
        fluidTempCelsius: telemetry.fluidTemperatureCelsius,
        fluidQualityIndexPercent: score,
        maintenanceDirective:
            'WARNING: Early hydraulic fluid degradation detected. Replace inline 10-micron return filter and desiccant tank breather.',
      );
    }

    return HydraulicOilHealthResult(
      vehicleId: vehicleId,
      status: FluidDegradationStatus.pristineCleanFluid,
      isoParticleCode: telemetry.isoParticleCountCode,
      waterPpm: telemetry.waterContentPpm,
      fluidTempCelsius: telemetry.fluidTemperatureCelsius,
      fluidQualityIndexPercent: score,
      maintenanceDirective:
          'NOMINAL: Hydraulic fluid cleanliness index and thermal viscosity within rated operational parameters.',
    );
  }
}
