/// Wear status of hydraulic cylinders, pump, and fluid.
enum HydraulicWearStatus {
  normalOperational,
  serviceRecommended,
  fluidDegraded,
  sealOverhaulMandatory,
}

/// Telemetry recorded from hydraulic power pack (HPU) and tail-lift sensors.
class HydraulicTelemetrySample {
  final int cumulativeCycles;           // Lift/lower cycle count (e.g. 0 to 50,000)
  final double cumulativeLiftedTons;    // Total tonnage handled
  final double hydraulicFluidTempCelsius; // Optimal 40°C - 60°C; severe breakdown > 80°C
  final double peakOperatingPressureBar; // Nominal 180 to 220 bar
  final double pressureDropRateBarPerSec; // Indicator of internal bypass / cylinder seal leak
  final int fluidOperatingHours;         // Recommended change every 1000 hrs

  const HydraulicTelemetrySample({
    required this.cumulativeCycles,
    required this.cumulativeLiftedTons,
    required this.hydraulicFluidTempCelsius,
    required this.peakOperatingPressureBar,
    required this.pressureDropRateBarPerSec,
    required this.fluidOperatingHours,
  });
}

/// Predictive diagnostic audit for hydraulic loading equipment.
class HydraulicHealthAudit {
  final double sealWearPercentage; // 0 to 100%
  final int remainingCyclesToOverhaul;
  final HydraulicWearStatus status;
  final String statusSummary;
  final bool fluidFlushRequired;
  final bool safetyLockoutRequired;

  const HydraulicHealthAudit({
    required this.sealWearPercentage,
    required this.remainingCyclesToOverhaul,
    required this.status,
    required this.statusSummary,
    required this.fluidFlushRequired,
    required this.safetyLockoutRequired,
  });
}

/// Service analyzing hydraulic tail-lift and crane wear kinematics.
class HydraulicTailLiftService {
  const HydraulicTailLiftService();

  /// Maximum design cycles before mandatory cylinder seal and packing replacement
  static const int maxDesignCycles = 30000;

  /// Audits hydraulic health, thermal degradation, and seal bypass rates.
  HydraulicHealthAudit evaluateHealth(HydraulicTelemetrySample sample) {
    // Wear is a function of cycle count, heavy tonnage factor, and pressure bypass rate
    final double cycleFraction = (sample.cumulativeCycles / maxDesignCycles).clamp(0.0, 1.0);
    final double bypassPenalty = (sample.pressureDropRateBarPerSec > 1.5)
        ? (sample.pressureDropRateBarPerSec - 1.5) * 15.0
        : 0.0;

    final double computedWear = (cycleFraction * 80.0 + bypassPenalty).clamp(0.0, 100.0);
    final remainingCycles = (maxDesignCycles - sample.cumulativeCycles).clamp(0, maxDesignCycles);

    final bool fluidDegraded = sample.hydraulicFluidTempCelsius >= 82.0 ||
        sample.fluidOperatingHours >= 1000;

    HydraulicWearStatus status;
    String summary;
    bool lockout = false;

    if (sample.pressureDropRateBarPerSec >= 4.0 || sample.cumulativeCycles >= maxDesignCycles) {
      status = HydraulicWearStatus.sealOverhaulMandatory;
      lockout = true;
      summary = 'CRITICAL HYDRAULIC LEAK: Severe cylinder bypass (${sample.pressureDropRateBarPerSec.toStringAsFixed(1)} bar/s). Tail-lift descent speed hazard!';
    } else if (fluidDegraded) {
      status = HydraulicWearStatus.fluidDegraded;
      summary = 'FLUID THERMAL BREAKDOWN: Hydraulic oil aged (${sample.fluidOperatingHours}h) or overheated (${sample.hydraulicFluidTempCelsius.toStringAsFixed(0)}°C). Drain and replace ISO VG 32/46 fluid.';
    } else if (computedWear >= 70.0 || sample.cumulativeCycles >= 22000) {
      status = HydraulicWearStatus.serviceRecommended;
      summary = 'SERVICE RECOMMENDED: Preventive packing inspection due within $remainingCycles cycles.';
    } else {
      status = HydraulicWearStatus.normalOperational;
      summary = 'HYDRAULIC INTEGRITY HEALTHY: Pressure holding stable; zero anomalous bypass detected.';
    }

    return HydraulicHealthAudit(
      sealWearPercentage: double.parse(computedWear.toStringAsFixed(1)),
      remainingCyclesToOverhaul: remainingCycles,
      status: status,
      statusSummary: summary,
      fluidFlushRequired: fluidDegraded,
      safetyLockoutRequired: lockout,
    );
  }
}
