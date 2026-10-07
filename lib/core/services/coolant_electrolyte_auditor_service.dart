/// Engine coolant glycol concentration & electrochemical status.
enum CoolantElectrolyteStatus {
  balancedFreezeAndCorrosionProtection,
  glycolDilutionFreezeRisk,
  acidicElectrolysisCorrosionWarning,
}

/// Dynamic telemetry reading from optical refractometer and electrochemical pH sensor.
class CoolantChemistryTelemetry {
  final double ethyleneGlycolConcentrationPercent; // Target: 50% (50/50 mix, -37°C freeze protection)
  final double coolantPh; // Nominal: 8.5 - 10.5. Acidic < 7.5
  final double strayElectricalVoltageMilliVolts; // Electrolysis threshold > 300 mV
  final double nitriteSilicateCorrosionInhibitorPpm; // Scavenger additive level (Nominal > 1,200 PPM)
  final double coolantTemperatureCelsius;

  const CoolantChemistryTelemetry({
    required this.ethyleneGlycolConcentrationPercent,
    required this.coolantPh,
    required this.strayElectricalVoltageMilliVolts,
    required this.nitriteSilicateCorrosionInhibitorPpm,
    required this.coolantTemperatureCelsius,
  });

  /// Freeze point protection temperature (°C) derived from glycol %.
  double get freezePointProtectionCelsius {
    // 50% glycol = -37°C. 30% glycol = -15°C. 0% = 0°C.
    return -(ethyleneGlycolConcentrationPercent * 0.74);
  }
}

/// Comprehensive engine coolant chemistry audit result.
class CoolantChemistryAuditResult {
  final String vehicleId;
  final CoolantElectrolyteStatus status;
  final double glycolPercent;
  final double phLevel;
  final double strayVoltageMv;
  final double freezeProtectionCelsius;
  final double chemistryHealthScorePercent;
  final String maintenanceDirective;

  const CoolantChemistryAuditResult({
    required this.vehicleId,
    required this.status,
    required this.glycolPercent,
    required this.phLevel,
    required this.strayVoltageMv,
    required this.freezeProtectionCelsius,
    required this.chemistryHealthScorePercent,
    required this.maintenanceDirective,
  });

  bool get isElectrolyteBalanced => status == CoolantElectrolyteStatus.balancedFreezeAndCorrosionProtection;
  bool get isCorrosiveElectrolysisActive => status == CoolantElectrolyteStatus.acidicElectrolysisCorrosionWarning;
}

/// Service that evaluates heavy engine coolant chemistry, winter freeze point, and electrolysis pitting.
class CoolantElectrolyteAuditorService {
  const CoolantElectrolyteAuditorService();

  CoolantChemistryAuditResult auditCoolantChemistry({
    required String vehicleId,
    required CoolantChemistryTelemetry telemetry,
  }) {
    final freezeTemp = telemetry.freezePointProtectionCelsius;
    final isAcidic = telemetry.coolantPh < 7.2;
    final isElectrolysis = telemetry.strayElectricalVoltageMilliVolts > 350.0;
    final isDiluted = telemetry.ethyleneGlycolConcentrationPercent < 33.0;

    // Health Score calculation (0 - 100%)
    double score = 100.0;
    if (telemetry.ethyleneGlycolConcentrationPercent < 45.0) {
      score -= ((45.0 - telemetry.ethyleneGlycolConcentrationPercent) * 2.0).clamp(0.0, 40.0);
    }
    if (telemetry.coolantPh < 8.2) {
      score -= ((8.2 - telemetry.coolantPh) * 20.0).clamp(0.0, 35.0);
    }
    if (telemetry.strayElectricalVoltageMilliVolts > 150.0) {
      score -= ((telemetry.strayElectricalVoltageMilliVolts - 150.0) * 0.1).clamp(0.0, 25.0);
    }
    score = score.clamp(0.0, 100.0);

    // Critical: Acidic coolant + high stray voltage (radiator core pinhole erosion)
    if (isAcidic || isElectrolysis) {
      return CoolantChemistryAuditResult(
        vehicleId: vehicleId,
        status: CoolantElectrolyteStatus.acidicElectrolysisCorrosionWarning,
        glycolPercent: telemetry.ethyleneGlycolConcentrationPercent,
        phLevel: telemetry.coolantPh,
        strayVoltageMv: telemetry.strayElectricalVoltageMilliVolts,
        freezeProtectionCelsius: freezeTemp,
        chemistryHealthScorePercent: score,
        maintenanceDirective:
            'ELECTROLYSIS ALERT: Acidic coolant (pH ${telemetry.coolantPh.toStringAsFixed(1)}) and stray ground voltage (>350 mV) eroding aluminum radiator core & heater matrix. Flush & ground chassis.',
      );
    }

    if (isDiluted || telemetry.coolantPh < 7.8 || telemetry.nitriteSilicateCorrosionInhibitorPpm < 800.0) {
      return CoolantChemistryAuditResult(
        vehicleId: vehicleId,
        status: CoolantElectrolyteStatus.glycolDilutionFreezeRisk,
        glycolPercent: telemetry.ethyleneGlycolConcentrationPercent,
        phLevel: telemetry.coolantPh,
        strayVoltageMv: telemetry.strayElectricalVoltageMilliVolts,
        freezeProtectionCelsius: freezeTemp,
        chemistryHealthScorePercent: score,
        maintenanceDirective:
            'WARNING: Water dilution detected (Glycol < 33%). Winter engine block freeze-cracking risk (Freeze point only ${freezeTemp.toStringAsFixed(0)}°C). Add concentrated OAT coolant.',
      );
    }

    return CoolantChemistryAuditResult(
      vehicleId: vehicleId,
      status: CoolantElectrolyteStatus.balancedFreezeAndCorrosionProtection,
      glycolPercent: telemetry.ethyleneGlycolConcentrationPercent,
      phLevel: telemetry.coolantPh,
      strayVoltageMv: telemetry.strayElectricalVoltageMilliVolts,
      freezeProtectionCelsius: freezeTemp,
      chemistryHealthScorePercent: score,
      maintenanceDirective:
          'NOMINAL: 50/50 ethylene glycol ratio with alkaline anti-corrosion inhibitor reserve (-37°C freeze rating).',
    );
  }
}
