/// AdBlue / DEF tank and dosing operational status.
enum DefSystemStatus {
  optimal,
  lowRefillRequired,
  criticalDepleted,
  qualityMalfunction,
  inducementDerated,
}

/// DEF tank and SCR telemetry sample.
class DefTelemetrySample {
  final double tankLevelPercent;          // 0 to 100%
  final double tankCapacityLiters;        // e.g. 25.0 L
  final double defConsumptionLitersPer1000Km; // e.g. 1.5 to 2.5 L/1000km
  final double noxReductionEfficiencyPercent; // e.g. 92% to 99%
  final double defQualityConcentrationPercent; // Urea concentration nominal 32.5%
  final double tankTempCelsius;           // Freezes at -11°C, degrades at > 35°C

  const DefTelemetrySample({
    required this.tankLevelPercent,
    required this.tankCapacityLiters,
    required this.defConsumptionLitersPer1000Km,
    required this.noxReductionEfficiencyPercent,
    required this.defQualityConcentrationPercent,
    required this.tankTempCelsius,
  });
}

/// Comprehensive SCR and DEF regulatory compliance audit.
class DefComplianceAudit {
  final double remainingDefLiters;
  final double estimatedRemainingKm;
  final DefSystemStatus status;
  final int inducementCountdownKm; // Km until engine ECU derates power
  final bool heaterActive;         // Tank heater active when temp < -5°C
  final String complianceMessage;
  final bool requiresImmediateAction;

  const DefComplianceAudit({
    required this.remainingDefLiters,
    required this.estimatedRemainingKm,
    required this.status,
    required this.inducementCountdownKm,
    required this.heaterActive,
    required this.complianceMessage,
    required this.requiresImmediateAction,
  });
}

/// Service managing AdBlue / DEF SCR system diagnostics and inducement warnings.
class DefEmissionsHealthService {
  const DefEmissionsHealthService();

  /// Audits DEF consumption, SCR catalytic efficiency, and EPA/Euro VI inducement warnings.
  DefComplianceAudit evaluateDefHealth(DefTelemetrySample sample) {
    final remainingLiters = sample.tankCapacityLiters * (sample.tankLevelPercent / 100.0);
    final consumptionRate = sample.defConsumptionLitersPer1000Km > 0.1
        ? sample.defConsumptionLitersPer1000Km
        : 1.8; // Standard commercial default

    final remainingKm = (remainingLiters / consumptionRate) * 1000.0;

    // Check DEF quality concentration (nominal 32.5% ± 2.5%)
    final isPoorQuality = sample.defQualityConcentrationPercent < 30.0 ||
        sample.defQualityConcentrationPercent > 35.5;

    // Tank heater activation below freezing
    final heaterActive = sample.tankTempCelsius <= -5.0;

    DefSystemStatus status;
    int inducementKm = 800; // Standard regulation warning window
    String message;
    bool immediateAction = false;

    if (sample.tankLevelPercent <= 2.0) {
      status = DefSystemStatus.inducementDerated;
      inducementKm = 0;
      message = 'ENGINE DERATED: AdBlue tank empty. Vehicle speed capped to crawl mode.';
      immediateAction = true;
    } else if (sample.tankLevelPercent <= 8.0) {
      status = DefSystemStatus.criticalDepleted;
      inducementKm = 80;
      message = 'CRITICAL DEF WARNING: Refill immediately! Engine power derating in $inducementKm km.';
      immediateAction = true;
    } else if (isPoorQuality) {
      status = DefSystemStatus.qualityMalfunction;
      inducementKm = 250;
      message = 'DEF QUALITY MALFUNCTION: Urea concentration outside DIN 70070 spec. Flush and replace fluid.';
      immediateAction = true;
    } else if (sample.tankLevelPercent <= 20.0) {
      status = DefSystemStatus.lowRefillRequired;
      inducementKm = 450;
      message = 'LOW DEF: Level below 20%. Schedule refill at next fuel depot.';
      immediateAction = false;
    } else {
      status = DefSystemStatus.optimal;
      inducementKm = 1500;
      message = 'SCR SYSTEM HEALTHY: DEF dosing optimal; NOx conversion at ${sample.noxReductionEfficiencyPercent.toStringAsFixed(0)}%.';
      immediateAction = false;
    }

    return DefComplianceAudit(
      remainingDefLiters: double.parse(remainingLiters.toStringAsFixed(1)),
      estimatedRemainingKm: double.parse(remainingKm.toStringAsFixed(0)),
      status: status,
      inducementCountdownKm: inducementKm,
      heaterActive: heaterActive,
      complianceMessage: message,
      requiresImmediateAction: immediateAction,
    );
  }
}
