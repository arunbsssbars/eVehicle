
/// Vehicle electrical subsystem load category.
enum ElectricalSubsystem {
  cabinHvacBlower,
  liftgateHydraulicPump,
  telematicsAndGps,
  trailerReeferElectricStandby,
  radiatorCoolingFans,
  headlampsAndMarkerLights,
}

/// Dynamic power draw telemetry sample for a specific subsystem.
class SubsystemPowerDraw {
  final ElectricalSubsystem system;
  final double currentAmperes;
  final double voltageVolts;
  final double durationHours;

  const SubsystemPowerDraw({
    required this.system,
    required this.currentAmperes,
    this.voltageVolts = 24.0, // Commercial 24V architecture default
    required this.durationHours,
  });

  /// Instantaneous power in Watts.
  double get powerWatts => currentAmperes * voltageVolts;

  /// Energy consumed in Watt-hours.
  double get energyWattHours => powerWatts * durationHours;
}

/// Overall alternator and auxiliary battery bank telemetry.
class AlternatorBatteryTelemetry {
  final double alternatorRatedOutputAmperes;
  final double alternatorCurrentOutputAmperes;
  final double systemBusVoltage;
  final double batteryStateOfChargePercent;
  final List<SubsystemPowerDraw> loads;

  const AlternatorBatteryTelemetry({
    this.alternatorRatedOutputAmperes = 150.0,
    required this.alternatorCurrentOutputAmperes,
    required this.systemBusVoltage,
    required this.batteryStateOfChargePercent,
    required this.loads,
  });

  /// Total electrical demand in Amperes.
  double get totalLoadAmperes => loads.fold(0.0, (sum, load) => sum + load.currentAmperes);
}

/// Power balance condition.
enum ElectricalBalanceStatus {
  netPositiveCharging,
  neutralLoadBalance,
  netDeficitDischargingCritical,
}

/// Comprehensive electrical power balance audit result.
class ElectricalLoadBalanceResult {
  final String vehicleId;
  final ElectricalBalanceStatus status;
  final double totalDemandAmperes;
  final double alternatorUtilizationPercent;
  final double netCurrentDeficitAmperes;
  final bool isBatteryDepletingUnderLoad;
  final double estimatedBatteryRunwayMinutes;
  final String powerRecommendation;

  const ElectricalLoadBalanceResult({
    required this.vehicleId,
    required this.status,
    required this.totalDemandAmperes,
    required this.alternatorUtilizationPercent,
    required this.netCurrentDeficitAmperes,
    required this.isBatteryDepletingUnderLoad,
    required this.estimatedBatteryRunwayMinutes,
    required this.powerRecommendation,
  });

  bool get isHealthy => status == ElectricalBalanceStatus.netPositiveCharging;
}

/// Auxiliary Power Unit (APU) & Heavy Vehicle 24V Electrical Load Balancer Service.
class ElectricalLoadBalancerService {
  const ElectricalLoadBalancerService();

  ElectricalLoadBalanceResult balanceElectricalSystem({
    required String vehicleId,
    required AlternatorBatteryTelemetry telemetry,
  }) {
    final demandAmps = telemetry.totalLoadAmperes;
    final ratedAmps = telemetry.alternatorRatedOutputAmperes;
    final utilization = ratedAmps > 0 ? (demandAmps / ratedAmps) * 100 : 0.0;

    final deficit = (demandAmps - telemetry.alternatorCurrentOutputAmperes).clamp(0.0, double.infinity);
    final isDepleting = deficit > 5.0 && telemetry.systemBusVoltage < 25.0;

    // Approximate battery remaining runway in minutes under deficit
    // Assume 100Ah reserve battery capacity
    const double batteryReserveAh = 100.0;
    final double remainingAh = batteryReserveAh * (telemetry.batteryStateOfChargePercent / 100.0);
    final double runwayMinutes = deficit > 0 ? (remainingAh / deficit) * 60.0 : 999.0;

    ElectricalBalanceStatus status;
    String recommendation;

    if (isDepleting || deficit >= 25.0) {
      status = ElectricalBalanceStatus.netDeficitDischargingCritical;
      recommendation = 'ELECTRICAL DEFICIT CRITICAL: Total load (${demandAmps.toStringAsFixed(0)} A) exceeds alternator output. Battery runway: ${runwayMinutes.toStringAsFixed(0)} mins. Shed non-essential auxiliary HVAC loads.';
    } else if (utilization >= 85.0) {
      status = ElectricalBalanceStatus.neutralLoadBalance;
      recommendation = 'HIGH UTILIZATION ADVISORY: Alternator operating near rated capacity (${utilization.toStringAsFixed(0)}%). Limit simultaneous liftgate hydraulic cycles.';
    } else {
      status = ElectricalBalanceStatus.netPositiveCharging;
      recommendation = 'Electrical generation in net surplus. Battery bank actively replenishing at nominal voltage.';
    }

    return ElectricalLoadBalanceResult(
      vehicleId: vehicleId,
      status: status,
      totalDemandAmperes: double.parse(demandAmps.toStringAsFixed(1)),
      alternatorUtilizationPercent: double.parse(utilization.toStringAsFixed(1)),
      netCurrentDeficitAmperes: double.parse(deficit.toStringAsFixed(1)),
      isBatteryDepletingUnderLoad: isDepleting,
      estimatedBatteryRunwayMinutes: double.parse(runwayMinutes.toStringAsFixed(0)),
      powerRecommendation: recommendation,
    );
  }
}
