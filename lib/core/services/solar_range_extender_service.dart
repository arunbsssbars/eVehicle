/// Solar generation status category.
enum SolarGenerationStatus {
  dormantNight,
  overcastSuboptimal,
  optimalClearSky,
  peakIrradiance,
}

/// Instantaneous solar PV telemetry reading.
class SolarPvReading {
  final double irradianceWattsPerSqMeter; // Solar irradiance (e.g. 0 to 1000 W/m²)
  final double panelSurfaceAreaSqMeters;  // Total rooftop PV panel area (e.g. 4.5 m²)
  final double ambientTempCelsius;
  final double mpptEfficiencyPercent;     // Maximum Power Point Tracking (e.g. 96%)

  const SolarPvReading({
    required this.irradianceWattsPerSqMeter,
    required this.panelSurfaceAreaSqMeters,
    required this.ambientTempCelsius,
    this.mpptEfficiencyPercent = 95.0,
  });
}

/// Predictive audit of solar generation yield and auxiliary energy offset.
class SolarEnergyYieldAudit {
  final double currentPowerOutputWatts;
  final double dailyGenerationKwh;
  final double hvacAuxiliaryOffsetKwh;
  final double netExtendedRangeKm;
  final double co2AvoidedKg;
  final SolarGenerationStatus status;
  final String statusSummary;

  const SolarEnergyYieldAudit({
    required this.currentPowerOutputWatts,
    required this.dailyGenerationKwh,
    required this.hvacAuxiliaryOffsetKwh,
    required this.netExtendedRangeKm,
    required this.co2AvoidedKg,
    required this.status,
    required this.statusSummary,
  });
}

/// Service that computes solar PV energy harvesting and range extension.
class SolarRangeExtenderService {
  const SolarRangeExtenderService();

  /// Evaluates instantaneous solar generation and cumulative daily range extension.
  /// [vehicleWhPerKm] is the vehicle consumption rate (e.g. 180 Wh/km for light commercial EV).
  /// [sunlightHours] is the expected daylight exposure hours for the shift.
  SolarEnergyYieldAudit calculateSolarYield({
    required SolarPvReading reading,
    double cumulativeDayKwh = 0.0,
    double vehicleWhPerKm = 175.0,
    double sunlightHours = 7.0,
  }) {
    // Temperature coefficient derating: PV cells lose ~0.4% efficiency per °C above 25°C
    double tempDerateFactor = 1.0;
    if (reading.ambientTempCelsius > 25.0) {
      tempDerateFactor -= (reading.ambientTempCelsius - 25.0) * 0.004;
    }
    tempDerateFactor = tempDerateFactor.clamp(0.70, 1.05);

    // Instantaneous power: Irradiance * Area * PanelEfficiency (approx 21%) * MPPT * TempDerate
    const double panelNominalEfficiency = 0.21;
    final double instantaneousPowerWatts = reading.irradianceWattsPerSqMeter *
        reading.panelSurfaceAreaSqMeters *
        panelNominalEfficiency *
        (reading.mpptEfficiencyPercent / 100.0) *
        tempDerateFactor;

    // Projected daily generation
    final double projectedDailyKwh = cumulativeDayKwh > 0
        ? cumulativeDayKwh
        : (instantaneousPowerWatts * sunlightHours) / 1000.0;

    // 40% of generated solar directly offsets auxiliary loads (HVAC / reefer / in-cab electronics)
    final double hvacOffsetKwh = projectedDailyKwh * 0.40;
    // Remaining 60% feeds traction battery directly extending range
    final double tractionEnergyKwh = projectedDailyKwh * 0.60;
    final double tractionWh = tractionEnergyKwh * 1000.0;
    final double netRangeKm = tractionWh / vehicleWhPerKm;

    // Carbon offset: ~0.42 kg CO2 per kWh grid equivalent
    final double co2AvoidedKg = projectedDailyKwh * 0.42;

    SolarGenerationStatus status;
    String summary;

    if (reading.irradianceWattsPerSqMeter > 800.0) {
      status = SolarGenerationStatus.peakIrradiance;
      summary = 'PEAK HARVEST: Rooftop PV generating maximum auxiliary & traction energy.';
    } else if (reading.irradianceWattsPerSqMeter > 350.0) {
      status = SolarGenerationStatus.optimalClearSky;
      summary = 'OPTIMAL HARVEST: Steady solar irradiance offsetting auxiliary loads.';
    } else if (reading.irradianceWattsPerSqMeter > 50.0) {
      status = SolarGenerationStatus.overcastSuboptimal;
      summary = 'LOW YIELD: Overcast or shaded conditions; modest auxiliary offset.';
    } else {
      status = SolarGenerationStatus.dormantNight;
      summary = 'DORMANT: Nighttime or heavy cloud cover; solar harvesting inactive.';
    }

    return SolarEnergyYieldAudit(
      currentPowerOutputWatts: double.parse(instantaneousPowerWatts.toStringAsFixed(1)),
      dailyGenerationKwh: double.parse(projectedDailyKwh.toStringAsFixed(2)),
      hvacAuxiliaryOffsetKwh: double.parse(hvacOffsetKwh.toStringAsFixed(2)),
      netExtendedRangeKm: double.parse(netRangeKm.toStringAsFixed(1)),
      co2AvoidedKg: double.parse(co2AvoidedKg.toStringAsFixed(2)),
      status: status,
      statusSummary: summary,
    );
  }
}
