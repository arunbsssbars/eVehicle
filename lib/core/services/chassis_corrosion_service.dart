/// Level of chassis corrosion vulnerability and salt encrustation.
enum CorrosionRiskLevel {
  cleanProtected,
  mildExposure,
  heavySaltAccumulation,
  criticalCorrosionHazard,
}

/// Exposure history and undercarriage wash log.
class UndercarriageExposureLog {
  final int daysSinceLastChassisWash;
  final int winterSaltExposureKm;     // Km traveled on salted/brined winter roads
  final double ambientHumidityPercent; // High humidity accelerates electrolytic oxidation
  final double protectiveWaxZincRatingPercent; // Undercarriage coating integrity (0-100%)

  const UndercarriageExposureLog({
    required this.daysSinceLastChassisWash,
    required this.winterSaltExposureKm,
    required this.ambientHumidityPercent,
    required this.protectiveWaxZincRatingPercent,
  });
}

/// Comprehensive chassis corrosion audit and washing schedule recommendation.
class ChassisCorrosionAudit {
  final double corrosionIndexScore; // 0 to 100
  final CorrosionRiskLevel riskLevel;
  final int recommendedWashWindowDays;
  final String statusSummary;
  final bool requiresMandatoryChassisWash;

  const ChassisCorrosionAudit({
    required this.corrosionIndexScore,
    required this.riskLevel,
    required this.recommendedWashWindowDays,
    required this.statusSummary,
    required this.requiresMandatoryChassisWash,
  });
}

/// Service assessing road salt exposure, galvanic corrosion risk, and fleet wash schedules.
class ChassisCorrosionService {
  const ChassisCorrosionService();

  /// Evaluates salt exposure and protective undercoating health.
  ChassisCorrosionAudit evaluateCorrosionRisk(UndercarriageExposureLog log) {
    // Score increases with days without washing and salt-road mileage
    final double saltFactor = (log.winterSaltExposureKm / 200.0) * 15.0;
    final double dayFactor = log.daysSinceLastChassisWash * 3.5;
    final double protectionDeficit = (100.0 - log.protectiveWaxZincRatingPercent) * 0.35;

    final double score = (saltFactor + dayFactor + protectionDeficit).clamp(0.0, 100.0);

    CorrosionRiskLevel level;
    int washWindow;
    String summary;
    bool mandatoryWash = false;

    if (score >= 75.0 || log.daysSinceLastChassisWash >= 28) {
      level = CorrosionRiskLevel.criticalCorrosionHazard;
      washWindow = 0;
      mandatoryWash = true;
      summary = 'CRITICAL SALT CRUST: Prolonged brine exposure threatening brake lines and chassis rails. Route to depot wash bay immediately.';
    } else if (score >= 45.0 || log.winterSaltExposureKm >= 500) {
      level = CorrosionRiskLevel.heavySaltAccumulation;
      washWindow = 2;
      mandatoryWash = true;
      summary = 'HEAVY CHEMICAL ENCRUSTATION: Winter de-icing salts coating suspension arms. High-pressure wash scheduled within 48 hours.';
    } else if (score >= 20.0 || log.daysSinceLastChassisWash >= 14) {
      level = CorrosionRiskLevel.mildExposure;
      washWindow = 5;
      summary = 'MILD DUST & GRIME: Surface residue detected. Routine undercarriage wash recommended within 5 days.';
    } else {
      level = CorrosionRiskLevel.cleanProtected;
      washWindow = 14;
      summary = 'CHASSIS PROTECTED: Undercarriage clean; zinc-wax protective barrier intact at ${log.protectiveWaxZincRatingPercent.toStringAsFixed(0)}%.';
    }

    return ChassisCorrosionAudit(
      corrosionIndexScore: double.parse(score.toStringAsFixed(1)),
      riskLevel: level,
      recommendedWashWindowDays: washWindow,
      statusSummary: summary,
      requiresMandatoryChassisWash: mandatoryWash,
    );
  }
}
