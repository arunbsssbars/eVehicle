/// Overall cabin air quality rating.
enum CabinAirQualityTier {
  pristine,
  moderate,
  unhealthy,
  hazardousDrowsinessTrigger,
}

/// Air recirculation or fresh air HVAC damper recommendation.
enum CabinDamperMode {
  recirculationPurify,
  freshAirIntake,
  emergencyVentilate,
}

/// In-cabin sensor telemetry sample.
class CabinAirTelemetry {
  final double pm25MicrogramsPerCubicMeter; // e.g. 5 to 150 µg/m³
  final int co2Ppm;                         // e.g. 450 to 2500 ppm (drowsiness trigger > 1000 ppm)
  final int vocIndex;                       // 1 to 500 (volatile organic compounds)
  final double filterHealthRemainingPercent; // 0 to 100%

  const CabinAirTelemetry({
    required this.pm25MicrogramsPerCubicMeter,
    required this.co2Ppm,
    required this.vocIndex,
    required this.filterHealthRemainingPercent,
  });
}

/// Comprehensive cabin atmospheric health audit.
class CabinAirQualityAudit {
  final int calculatedAqi;
  final CabinAirQualityTier tier;
  final CabinDamperMode recommendedDamperMode;
  final String statusSummary;
  final bool filterReplacementDue;
  final bool cognitiveImpairmentRisk;

  const CabinAirQualityAudit({
    required this.calculatedAqi,
    required this.tier,
    required this.recommendedDamperMode,
    required this.statusSummary,
    required this.filterReplacementDue,
    required this.cognitiveImpairmentRisk,
  });
}

/// Service assessing in-cabin air quality and automated HVAC damper controls.
class CabinAqiService {
  const CabinAqiService();

  /// Audits PM2.5, CO2, and VOC levels to protect driver respiratory and cognitive performance.
  CabinAirQualityAudit evaluateCabinAir(CabinAirTelemetry sample) {
    // US EPA PM2.5 AQI piecewise conversion approximation
    int aqiFromPm25;
    if (sample.pm25MicrogramsPerCubicMeter <= 12.0) {
      aqiFromPm25 = ((50.0 / 12.0) * sample.pm25MicrogramsPerCubicMeter).round();
    } else if (sample.pm25MicrogramsPerCubicMeter <= 35.4) {
      aqiFromPm25 = (51 + ((49.0 / 23.4) * (sample.pm25MicrogramsPerCubicMeter - 12.1))).round();
    } else if (sample.pm25MicrogramsPerCubicMeter <= 55.4) {
      aqiFromPm25 = (101 + ((49.0 / 20.0) * (sample.pm25MicrogramsPerCubicMeter - 35.5))).round();
    } else {
      aqiFromPm25 = (151 + ((49.0 / 95.0) * (sample.pm25MicrogramsPerCubicMeter - 55.5))).round();
    }

    final calculatedAqi = aqiFromPm25.clamp(0, 500);
    final filterDue = sample.filterHealthRemainingPercent <= 10.0;
    final cognitiveRisk = sample.co2Ppm >= 1200;

    CabinAirQualityTier tier;
    CabinDamperMode damperMode;
    String summary;

    if (sample.co2Ppm >= 1800) {
      tier = CabinAirQualityTier.hazardousDrowsinessTrigger;
      damperMode = CabinDamperMode.emergencyVentilate;
      summary = 'CRITICAL CO₂ ELEVATION: In-cabin CO₂ is ${sample.co2Ppm} ppm. High risk of cognitive lethargy and slow reflexes! Ventilating cabin immediately.';
    } else if (calculatedAqi > 100 || sample.vocIndex > 250) {
      tier = CabinAirQualityTier.unhealthy;
      damperMode = CabinDamperMode.recirculationPurify;
      summary = 'UNHEALTHY PARTICULATE: High ambient PM2.5/VOC detected. Recirculating air through cabin HEPA filter.';
    } else if (sample.co2Ppm >= 1000) {
      tier = CabinAirQualityTier.moderate;
      damperMode = CabinDamperMode.freshAirIntake;
      summary = 'STALE CABIN AIR: CO₂ exceeding 1,000 ppm. Opening fresh air intake damper to restore driver vigilance.';
    } else {
      tier = CabinAirQualityTier.pristine;
      damperMode = CabinDamperMode.freshAirIntake;
      summary = 'CABIN AIR PRISTINE: Atmospheric parameters within clean occupational health thresholds.';
    }

    return CabinAirQualityAudit(
      calculatedAqi: calculatedAqi,
      tier: tier,
      recommendedDamperMode: damperMode,
      statusSummary: summary,
      filterReplacementDue: filterDue,
      cognitiveImpairmentRisk: cognitiveRisk,
    );
  }
}
