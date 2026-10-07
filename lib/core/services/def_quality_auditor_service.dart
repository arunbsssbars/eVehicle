/// Diesel Exhaust Fluid (DEF / AdBlue) concentration health status.
enum DefQualityStatus {
  compliantConcentration,
  dilutionOrContaminationWarning,
  criticalTamperingDeNoxShutdown,
}

/// Dynamic telemetry reading from the optical refractive and acoustic DEF quality sensor.
class DefQualityTelemetry {
  final double ureaConcentrationPercent; // ISO 22241 standard nominal: 32.5% (±0.7%)
  final double tankLevelPercent;
  final double tankTemperatureCelsius; // AdBlue freezes at -11°C
  final double opticalRefractiveIndex; // Nominal: 1.3814 - 1.3843
  final double noxReductionConversionPercent; // SCR cat efficiency (Nominal > 85%)

  const DefQualityTelemetry({
    required this.ureaConcentrationPercent,
    required this.tankLevelPercent,
    required this.tankTemperatureCelsius,
    required this.opticalRefractiveIndex,
    required this.noxReductionConversionPercent,
  });

  /// Deviation from mandatory 32.5% urea concentration standard.
  double get concentrationDeviationPercent => (ureaConcentrationPercent - 32.5).abs();
}

/// Comprehensive AdBlue chemical purity and tamper audit result.
class DefQualityAuditResult {
  final String vehicleId;
  final DefQualityStatus status;
  final double ureaPercent;
  final double tankLevelPercent;
  final double scrEfficiencyPercent;
  final double purityScorePercent;
  final String complianceAdvisory;

  const DefQualityAuditResult({
    required this.vehicleId,
    required this.status,
    required this.ureaPercent,
    required this.tankLevelPercent,
    required this.scrEfficiencyPercent,
    required this.purityScorePercent,
    required this.complianceAdvisory,
  });

  bool get isCompliant => status == DefQualityStatus.compliantConcentration;
  bool get isInducementTorqueLimitingActive => status == DefQualityStatus.criticalTamperingDeNoxShutdown;
}

/// Service that detects DEF dilution (water/substitute tampering) and SCR de-NOx failure.
class DefQualityAuditorService {
  const DefQualityAuditorService();

  DefQualityAuditResult auditDefPurity({
    required String vehicleId,
    required DefQualityTelemetry telemetry,
  }) {
    final dev = telemetry.concentrationDeviationPercent;
    final isTamperedOrDiluted = telemetry.ureaConcentrationPercent < 26.0 || telemetry.ureaConcentrationPercent > 39.0;
    final isLowScr = telemetry.noxReductionConversionPercent < 60.0;

    // Calculate purity score (0 - 100%)
    double score = 100.0;
    if (dev > 0.7) {
      score -= (dev * 8.0).clamp(0.0, 70.0);
    }
    if (telemetry.tankLevelPercent < 15.0) {
      score -= 15.0;
    }
    score = score.clamp(0.0, 100.0);

    // Critical: DEF < 26% (tap water added) or SCR cat poisoned
    if (isTamperedOrDiluted || isLowScr) {
      return DefQualityAuditResult(
        vehicleId: vehicleId,
        status: DefQualityStatus.criticalTamperingDeNoxShutdown,
        ureaPercent: telemetry.ureaConcentrationPercent,
        tankLevelPercent: telemetry.tankLevelPercent,
        scrEfficiencyPercent: telemetry.noxReductionConversionPercent,
        purityScorePercent: score,
        complianceAdvisory:
            'CRITICAL: Non-compliant DEF concentration (${telemetry.ureaConcentrationPercent.toStringAsFixed(1)}% vs 32.5% ISO 22241). Engine torque derate inducement imminent.',
      );
    }

    if (dev > 1.8 || telemetry.tankLevelPercent < 20.0) {
      return DefQualityAuditResult(
        vehicleId: vehicleId,
        status: DefQualityStatus.dilutionOrContaminationWarning,
        ureaPercent: telemetry.ureaConcentrationPercent,
        tankLevelPercent: telemetry.tankLevelPercent,
        scrEfficiencyPercent: telemetry.noxReductionConversionPercent,
        purityScorePercent: score,
        complianceAdvisory:
            'WARNING: Slight DEF quality drift or low tank level. Refill with certified ISO 22241 AUS-32 fluid to avoid NOx warning.',
      );
    }

    return DefQualityAuditResult(
      vehicleId: vehicleId,
      status: DefQualityStatus.compliantConcentration,
      ureaPercent: telemetry.ureaConcentrationPercent,
      tankLevelPercent: telemetry.tankLevelPercent,
      scrEfficiencyPercent: telemetry.noxReductionConversionPercent,
      purityScorePercent: score,
      complianceAdvisory:
          'NOMINAL: Certified 32.5% DEF concentration with optimal SCR catalyst de-NOx reduction efficiency.',
    );
  }
}
