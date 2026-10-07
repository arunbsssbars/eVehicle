/// Status of diesel primary fuel water separator and coalescing filter bowl.
enum FuelWaterSeparatorStatus {
  dryInertOperation,
  drainReservoirScheduled,
  criticalWaterBypassHighPressurePumpRisk,
}

/// Continuous optical, conductivity, and differential pressure telemetry from diesel fuel water separator.
class FuelWaterSeparatorTelemetry {
  final double waterBowlAccumulationMl; // Reservoir capacity: ~250 mL.
  final double waterBowlCapacityMl;
  final double coalescerDifferentialPressureKPa; // Filter restriction: Clean < 25 kPa. Plugged > 55 kPa.
  final double fuelConductivityMicroSiemens; // Pure diesel: < 5 µS/m. Emulsified water contamination > 50 µS/m.
  final bool isWifElectricalProbeTripped; // Electronic Water-In-Fuel switch (Conductive circuit across bottom probe).
  final double ambientTemperatureCelsius; // Sub-zero risk: Water freezes at <= 0°C, blocking fuel pick-up.

  const FuelWaterSeparatorTelemetry({
    required this.waterBowlAccumulationMl,
    this.waterBowlCapacityMl = 250.0,
    required this.coalescerDifferentialPressureKPa,
    required this.fuelConductivityMicroSiemens,
    required this.isWifElectricalProbeTripped,
    required this.ambientTemperatureCelsius,
  });

  /// Water volume percentage of the drain bowl.
  double get waterCapacityPercent =>
      ((waterBowlAccumulationMl / waterBowlCapacityMl) * 100.0).clamp(0.0, 100.0);

  /// Sub-zero icing threat inside separator bowl.
  bool get isFreezingIcingRisk => ambientTemperatureCelsius <= 0.0 && waterBowlAccumulationMl > 20.0;
}

/// Comprehensive diesel water separation and fuel injection system protection result.
class FuelWaterSeparatorAuditResult {
  final String vehicleId;
  final FuelWaterSeparatorStatus status;
  final double waterAccumulationMl;
  final double waterPercent;
  final double differentialPressureKPa;
  final double fuelConductivity;
  final bool isSubZeroIcingDanger;
  final String maintenanceAdvisory;

  const FuelWaterSeparatorAuditResult({
    required this.vehicleId,
    required this.status,
    required this.waterAccumulationMl,
    required this.waterPercent,
    required this.differentialPressureKPa,
    required this.fuelConductivity,
    required this.isSubZeroIcingDanger,
    required this.maintenanceAdvisory,
  });

  bool get isSafeForInjection => status == FuelWaterSeparatorStatus.dryInertOperation;
  bool get isCriticalPumpCorrosionRisk =>
      status == FuelWaterSeparatorStatus.criticalWaterBypassHighPressurePumpRisk;
}

/// Evaluates fuel coalescer saturation, optical water bowl levels, and protects common-rail HPFP from cavitation/galling.
class FuelWaterSeparatorService {
  const FuelWaterSeparatorService();

  FuelWaterSeparatorAuditResult auditSeparator({
    required String vehicleId,
    required FuelWaterSeparatorTelemetry telemetry,
  }) {
    final waterPercent = telemetry.waterCapacityPercent;
    final isIcing = telemetry.isFreezingIcingRisk;

    // 1. Critical: Bowl over 80% full, probe tripped, or emulsified water passing into common rail
    if (waterPercent >= 80.0 ||
        telemetry.isWifElectricalProbeTripped ||
        telemetry.fuelConductivityMicroSiemens >= 50.0 ||
        (isIcing && waterPercent >= 30.0)) {
      return FuelWaterSeparatorAuditResult(
        vehicleId: vehicleId,
        status: FuelWaterSeparatorStatus.criticalWaterBypassHighPressurePumpRisk,
        waterAccumulationMl: telemetry.waterBowlAccumulationMl,
        waterPercent: waterPercent,
        differentialPressureKPa: telemetry.coalescerDifferentialPressureKPa,
        fuelConductivity: telemetry.fuelConductivityMicroSiemens,
        isSubZeroIcingDanger: isIcing,
        maintenanceAdvisory:
            'CRITICAL DANGER: WIF sensor tripped (${telemetry.waterBowlAccumulationMl.toStringAsFixed(0)} mL water)! Water intrusion into common rail will destroy 2500-bar fuel injectors and HPFP pump. Drain separator bowl immediately.',
      );
    }

    // 2. Warning: Water accumulation > 35% or filter restriction elevated
    if (waterPercent >= 35.0 ||
        telemetry.coalescerDifferentialPressureKPa >= 45.0 ||
        telemetry.fuelConductivityMicroSiemens >= 20.0) {
      return FuelWaterSeparatorAuditResult(
        vehicleId: vehicleId,
        status: FuelWaterSeparatorStatus.drainReservoirScheduled,
        waterAccumulationMl: telemetry.waterBowlAccumulationMl,
        waterPercent: waterPercent,
        differentialPressureKPa: telemetry.coalescerDifferentialPressureKPa,
        fuelConductivity: telemetry.fuelConductivityMicroSiemens,
        isSubZeroIcingDanger: isIcing,
        maintenanceAdvisory:
            'WARNING: Water-in-fuel accumulation at ${waterPercent.toStringAsFixed(1)}% capacity. Open petcock drain valve at next scheduled driver rest stop to purge condensate.',
      );
    }

    // 3. Normal dry fuel delivery
    return FuelWaterSeparatorAuditResult(
      vehicleId: vehicleId,
      status: FuelWaterSeparatorStatus.dryInertOperation,
      waterAccumulationMl: telemetry.waterBowlAccumulationMl,
      waterPercent: waterPercent,
      differentialPressureKPa: telemetry.coalescerDifferentialPressureKPa,
      fuelConductivity: telemetry.fuelConductivityMicroSiemens,
      isSubZeroIcingDanger: isIcing,
      maintenanceAdvisory:
          'NOMINAL: Diesel primary filter coalescer active. Zero water condensate emulsion detected in common-rail supply line.',
    );
  }
}
