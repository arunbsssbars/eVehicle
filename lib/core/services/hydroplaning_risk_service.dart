import 'dart:math';

/// Severity level of hydroplaning and wet asphalt traction loss risk.
enum HydroplaningRiskLevel {
  lowDryRoad,
  moderateWetSurface,
  highHydroplaningHazard,
  extremeCriticalDanger,
}

/// Instantaneous meteorological and tyre condition data.
class WeatherSurfaceTelemetry {
  final double precipitationRateMmPerHour; // Rain rate (e.g. 0 to 50 mm/h)
  final double vehicleSpeedKmh;            // Current speed
  final double tyrePressurePsi;            // e.g. 32 to 36 psi (passenger) or 100+ (HGV)
  final double tyreTreadDepthMm;           // Legal limit usually 1.6mm, new 8.0mm
  final double ambientTempCelsius;

  const WeatherSurfaceTelemetry({
    required this.precipitationRateMmPerHour,
    required this.vehicleSpeedKmh,
    required this.tyrePressurePsi,
    required this.tyreTreadDepthMm,
    required this.ambientTempCelsius,
  });
}

/// Diagnostic evaluation of hydroplaning threshold and traction safety margin.
class HydroplaningSafetyAudit {
  final double estimatedWaterFilmDepthMm;
  final double criticalHydroplaningSpeedKmh; // Horne's formula speed threshold
  final double safetyMarginKmh;              // Critical speed - current speed
  final double riskScorePercent;             // 0 to 100%
  final HydroplaningRiskLevel riskLevel;
  final String advisoryMessage;
  final double recommendedSpeedKmh;

  const HydroplaningSafetyAudit({
    required this.estimatedWaterFilmDepthMm,
    required this.criticalHydroplaningSpeedKmh,
    required this.safetyMarginKmh,
    required this.riskScorePercent,
    required this.riskLevel,
    required this.advisoryMessage,
    required this.recommendedSpeedKmh,
  });
}

/// Service computing dynamic hydroplaning critical speed and wet road safety margins.
class HydroplaningRiskService {
  const HydroplaningRiskService();

  /// Evaluates hydroplaning hazard using Horne's formula adjusted for tread depth.
  HydroplaningSafetyAudit evaluateHazard(WeatherSurfaceTelemetry telemetry) {
    if (telemetry.precipitationRateMmPerHour <= 0.1) {
      return HydroplaningSafetyAudit(
        estimatedWaterFilmDepthMm: 0.0,
        criticalHydroplaningSpeedKmh: 140.0,
        safetyMarginKmh: (140.0 - telemetry.vehicleSpeedKmh).clamp(0.0, 140.0),
        riskScorePercent: 0.0,
        riskLevel: HydroplaningRiskLevel.lowDryRoad,
        advisoryMessage: 'DRY SURFACE: Optimal tyre-to-pavement friction coefficient.',
        recommendedSpeedKmh: telemetry.vehicleSpeedKmh,
      );
    }

    // Water film depth approximation: d = 0.015 * (I^0.5) * (L^0.2)
    // where I is rain rate in mm/h, assuming standard highway drainage cross-slope
    final waterDepthMm = 0.08 * sqrt(telemetry.precipitationRateMmPerHour);

    // Horne's Formula for dynamic hydroplaning:
    // Critical speed Vp (mph) = 10.35 * sqrt(tyre_pressure_psi)
    // Converted to km/h: Vp_kmh = 6.36 * sqrt(tyre_pressure_psi) * 1.60934 = 10.235 * sqrt(p)
    final baselineCriticalSpeedKmh = 10.235 * sqrt(telemetry.tyrePressurePsi);

    // Tread depth degradation modifier:
    // Full tread (8mm) maintains 100% of Horne's speed; 1.6mm drops threshold by up to 35%
    final treadFactor = (telemetry.tyreTreadDepthMm / 8.0).clamp(0.35, 1.0);
    final adjustedCriticalSpeedKmh = baselineCriticalSpeedKmh * (0.65 + 0.35 * treadFactor);

    final safetyMargin = adjustedCriticalSpeedKmh - telemetry.vehicleSpeedKmh;

    // Risk score calculation
    double score = 0.0;
    if (telemetry.vehicleSpeedKmh >= adjustedCriticalSpeedKmh) {
      score = 100.0;
    } else {
      score = (telemetry.vehicleSpeedKmh / adjustedCriticalSpeedKmh) * 100.0;
    }

    HydroplaningRiskLevel level;
    String advisory;
    double recommendedSpeed;

    if (score >= 90.0 || safetyMargin <= 5.0) {
      level = HydroplaningRiskLevel.extremeCriticalDanger;
      recommendedSpeed = adjustedCriticalSpeedKmh * 0.70;
      advisory = 'CRITICAL HYDROPLANING DANGER: Decelerate immediately to under ${recommendedSpeed.toStringAsFixed(0)} km/h.';
    } else if (score >= 70.0 || safetyMargin <= 18.0) {
      level = HydroplaningRiskLevel.highHydroplaningHazard;
      recommendedSpeed = adjustedCriticalSpeedKmh * 0.80;
      advisory = 'HIGH RISK: Water film standing on roadway. Reduce cruising speed to maintain tyre groove channeling.';
    } else if (score >= 45.0) {
      level = HydroplaningRiskLevel.moderateWetSurface;
      recommendedSpeed = telemetry.vehicleSpeedKmh;
      advisory = 'WET ASPHALT: Moderate traction reduction. Increase following distance.';
    } else {
      level = HydroplaningRiskLevel.lowDryRoad;
      recommendedSpeed = telemetry.vehicleSpeedKmh;
      advisory = 'LIGHT MOISTURE: Traction adequate. Drive with standard wet-weather care.';
    }

    return HydroplaningSafetyAudit(
      estimatedWaterFilmDepthMm: double.parse(waterDepthMm.toStringAsFixed(2)),
      criticalHydroplaningSpeedKmh: double.parse(adjustedCriticalSpeedKmh.toStringAsFixed(1)),
      safetyMarginKmh: double.parse(safetyMargin.toStringAsFixed(1)),
      riskScorePercent: double.parse(score.clamp(0.0, 100.0).toStringAsFixed(1)),
      riskLevel: level,
      advisoryMessage: advisory,
      recommendedSpeedKmh: double.parse(recommendedSpeed.toStringAsFixed(0)),
    );
  }
}
