/// Operating fluid chemistry classification.
enum FleetFluidType {
  engineOil,
  transmissionFluid,
  hydraulicFluid,
  differentialGearOil,
}

/// Dynamic lab spectrophotometry or onboard oil condition sensor telemetry.
class FluidDielectricTelemetry {
  final FleetFluidType fluidType;
  final double dielectricConstant; // Baseline fresh oil ~2.1 - 2.4
  final double freshBaselineDielectric;
  final double kinematicViscosityCst; // Viscosity at 100°C (cSt)
  final double nominalViscosityCst;
  final double waterContentPpm; // Moisture contamination (PPM)
  final double sootOxidationIndex; // Particulate loading
  final double operatingKilometers;

  const FluidDielectricTelemetry({
    required this.fluidType,
    required this.dielectricConstant,
    this.freshBaselineDielectric = 2.2,
    required this.kinematicViscosityCst,
    this.nominalViscosityCst = 14.5, // Typical 15W-40 heavy diesel oil
    required this.waterContentPpm,
    required this.sootOxidationIndex,
    required this.operatingKilometers,
  });

  /// Dielectric shift percentage.
  double get dielectricShiftPercent =>
      freshBaselineDielectric > 0 ? ((dielectricConstant - freshBaselineDielectric) / freshBaselineDielectric) * 100 : 0.0;
}

/// Fluid health condition classification.
enum FluidDegradationGrade {
  pristine,
  acceptable,
  drainDueSoon,
  immediateChangeMandatory,
}

/// Evaluation report for oil breakdown, water intrusion, and soot loading.
class FluidDielectricAuditResult {
  final String vehicleId;
  final FleetFluidType fluidType;
  final FluidDegradationGrade grade;
  final double dielectricShiftPercent;
  final double waterContentPpm;
  final bool hasWaterIntrusion;
  final bool hasSevereThermalOxidation;
  final double remainingUsefulLifeKilometers;
  final String advisory;

  const FluidDielectricAuditResult({
    required this.vehicleId,
    required this.fluidType,
    required this.grade,
    required this.dielectricShiftPercent,
    required this.waterContentPpm,
    required this.hasWaterIntrusion,
    required this.hasSevereThermalOxidation,
    required this.remainingUsefulLifeKilometers,
    required this.advisory,
  });

  bool get isSafe => grade == FluidDegradationGrade.pristine || grade == FluidDegradationGrade.acceptable;
}

/// Fluid Dielectric Constant & Engine Oil Contamination Auditor Service.
class FluidDielectricAuditorService {
  const FluidDielectricAuditorService();

  static const double waterIntrusionPpmLimit = 500.0; // Emulsion risk limit
  static const double dielectricShiftCondemnThreshold = 35.0; // High acid number / oxidation
  static const double standardOilIntervalKm = 25000.0;

  FluidDielectricAuditResult auditFluidQuality({
    required String vehicleId,
    required FluidDielectricTelemetry telemetry,
  }) {
    final hasWater = telemetry.waterContentPpm >= waterIntrusionPpmLimit;
    final shift = telemetry.dielectricShiftPercent.abs();
    final hasSevereOxidation = shift >= dielectricShiftCondemnThreshold || telemetry.sootOxidationIndex > 4.5;

    final remainingRatio = (1.0 - (shift / dielectricShiftCondemnThreshold)).clamp(0.0, 1.0);
    final remainingKm = (standardOilIntervalKm * remainingRatio).clamp(0.0, standardOilIntervalKm);

    FluidDegradationGrade grade;
    String advisory;

    if (hasWater || hasSevereOxidation || remainingKm <= 500.0) {
      grade = FluidDegradationGrade.immediateChangeMandatory;
      advisory = hasWater
          ? 'EMERGENCY: Coolant / water intrusion detected (${telemetry.waterContentPpm.toStringAsFixed(0)} PPM). Drain and inspect head gasket.'
          : 'CRITICAL: Severe lubricant breakdown and thermal oxidation. Drain and replace immediately.';
    } else if (remainingKm <= 3500.0 || shift >= 25.0) {
      grade = FluidDegradationGrade.drainDueSoon;
      advisory = 'ADVISORY: Lubricant nearing end-of-life. Schedule PM oil flush within ${remainingKm.toStringAsFixed(0)} km.';
    } else if (shift <= 12.0) {
      grade = FluidDegradationGrade.pristine;
      advisory = 'Lubricant chemistry pristine. Viscosity and dielectric constant within virgin tolerances.';
    } else {
      grade = FluidDegradationGrade.acceptable;
      advisory = 'Lubricant condition acceptable. Estimated remaining life: ${remainingKm.toStringAsFixed(0)} km.';
    }

    return FluidDielectricAuditResult(
      vehicleId: vehicleId,
      fluidType: telemetry.fluidType,
      grade: grade,
      dielectricShiftPercent: double.parse(shift.toStringAsFixed(1)),
      waterContentPpm: double.parse(telemetry.waterContentPpm.toStringAsFixed(0)),
      hasWaterIntrusion: hasWater,
      hasSevereThermalOxidation: hasSevereOxidation,
      remainingUsefulLifeKilometers: double.parse(remainingKm.toStringAsFixed(0)),
      advisory: advisory,
    );
  }
}
