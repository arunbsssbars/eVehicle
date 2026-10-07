/// Grid electricity tariff time window.
class TariffWindow {
  final String label; // e.g., 'Super Off-Peak', 'Off-Peak', 'Mid-Peak', 'Peak'
  final int startHour; // 0 - 23
  final int endHour; // 0 - 23
  final double ratePerKwh; // in currency units (e.g. INR / USD)
  final double carbonIntensityGPerKwh; // g CO2 / kWh

  const TariffWindow({
    required this.label,
    required this.startHour,
    required this.endHour,
    required this.ratePerKwh,
    required this.carbonIntensityGPerKwh,
  });
}

/// Vehicle powertrain energy specifications.
class VehicleEnergyProfile {
  final String vehicleId;
  final String registrationNumber;
  final bool isElectric;
  final double batteryCapacityKwh; // for EV
  final double currentSoCPercent; // 0 to 100
  final double targetSoCPercent; // 0 to 100
  final double maxChargingPowerKw; // e.g. 50 kW DC or 11 kW AC
  final double dieselEfficiencyKmPerLitre; // for ICE parity comparison
  final double dieselPricePerLitre;

  const VehicleEnergyProfile({
    required this.vehicleId,
    required this.registrationNumber,
    this.isElectric = true,
    this.batteryCapacityKwh = 60.0,
    this.currentSoCPercent = 20.0,
    this.targetSoCPercent = 90.0,
    this.maxChargingPowerKw = 30.0,
    this.dieselEfficiencyKmPerLitre = 14.0,
    this.dieselPricePerLitre = 90.0,
  });
}

/// Smart charging schedule allocation.
class ChargingScheduleBlock {
  final String tariffLabel;
  final int hour;
  final double energyDeliveredKwh;
  final double blockCost;

  const ChargingScheduleBlock({
    required this.tariffLabel,
    required this.hour,
    required this.energyDeliveredKwh,
    required this.blockCost,
  });
}

/// Comprehensive charging optimization plan output.
class ChargingOptimizationPlan {
  final String vehicleId;
  final double energyNeededKwh;
  final double estimatedDurationHours;
  final double optimalCost;
  final double unmanagedPeakCost;
  final double costSavingsPercent;
  final double parityCostPerKmEv;
  final double parityCostPerKmDiesel;
  final double evSavingsPer100Km;
  final double gridCarbonEmissionKg;
  final List<ChargingScheduleBlock> scheduleBlocks;

  const ChargingOptimizationPlan({
    required this.vehicleId,
    required this.energyNeededKwh,
    required this.estimatedDurationHours,
    required this.optimalCost,
    required this.unmanagedPeakCost,
    required this.costSavingsPercent,
    required this.parityCostPerKmEv,
    required this.parityCostPerKmDiesel,
    required this.evSavingsPer100Km,
    required this.gridCarbonEmissionKg,
    required this.scheduleBlocks,
  });
}

/// Multi-Modal Fleet Refueling & EV Smart Grid Dynamic Charging Optimizer.
class FleetChargingOptimizerService {
  const FleetChargingOptimizerService();

  /// Computes optimal charging time windows and diesel parity indices.
  ChargingOptimizationPlan optimizeCharging({
    required VehicleEnergyProfile profile,
    required List<TariffWindow> tariffs,
  }) {
    if (!profile.isElectric) {
      // ICE Fallback
      final dieselCostPerKm = profile.dieselPricePerLitre / profile.dieselEfficiencyKmPerLitre;
      return ChargingOptimizationPlan(
        vehicleId: profile.vehicleId,
        energyNeededKwh: 0,
        estimatedDurationHours: 0,
        optimalCost: 0,
        unmanagedPeakCost: 0,
        costSavingsPercent: 0,
        parityCostPerKmEv: 0,
        parityCostPerKmDiesel: double.parse(dieselCostPerKm.toStringAsFixed(2)),
        evSavingsPer100Km: 0,
        gridCarbonEmissionKg: 0,
        scheduleBlocks: const [],
      );
    }

    final deltaPercent = (profile.targetSoCPercent - profile.currentSoCPercent).clamp(0.0, 100.0);
    final energyNeeded = (deltaPercent / 100.0) * profile.batteryCapacityKwh;

    // Highest peak rate for unmanaged comparison
    double maxRate = 0.0;
    for (final t in tariffs) {
      if (t.ratePerKwh > maxRate) maxRate = t.ratePerKwh;
    }
    if (maxRate == 0.0) maxRate = 12.0; // fallback standard peak

    final unmanagedCost = energyNeeded * maxRate;

    // Find lowest-cost tariff windows first
    final sortedTariffs = List<TariffWindow>.from(tariffs)
      ..sort((a, b) => a.ratePerKwh.compareTo(b.ratePerKwh));

    double remainingEnergy = energyNeeded;
    double totalOptimalCost = 0.0;
    double totalCarbonGrams = 0.0;
    final List<ChargingScheduleBlock> blocks = [];

    for (final tariff in sortedTariffs) {
      if (remainingEnergy <= 0) break;

      final hoursInWindow = tariff.endHour >= tariff.startHour
          ? (tariff.endHour - tariff.startHour + 1)
          : (24 - tariff.startHour + tariff.endHour + 1);

      for (int i = 0; i < hoursInWindow; i++) {
        if (remainingEnergy <= 0) break;
        final hour = (tariff.startHour + i) % 24;
        final energyToCharge = profile.maxChargingPowerKw.clamp(0.0, remainingEnergy);
        final cost = energyToCharge * tariff.ratePerKwh;

        blocks.add(ChargingScheduleBlock(
          tariffLabel: tariff.label,
          hour: hour,
          energyDeliveredKwh: double.parse(energyToCharge.toStringAsFixed(1)),
          blockCost: double.parse(cost.toStringAsFixed(2)),
        ));

        totalOptimalCost += cost;
        totalCarbonGrams += energyToCharge * tariff.carbonIntensityGPerKwh;
        remainingEnergy -= energyToCharge;
      }
    }

    // In case tariffs didn't fully satisfy remaining energy
    if (remainingEnergy > 0) {
      final avgRate = sortedTariffs.isNotEmpty ? sortedTariffs.first.ratePerKwh : 8.0;
      final cost = remainingEnergy * avgRate;
      totalOptimalCost += cost;
      remainingEnergy = 0;
    }

    final durationHours = energyNeeded / (profile.maxChargingPowerKw > 0 ? profile.maxChargingPowerKw : 7.4);
    final savingsPercent = unmanagedCost > 0
        ? ((unmanagedCost - totalOptimalCost) / unmanagedCost) * 100.0
        : 0.0;

    // Parity: Assume EV consumes ~0.18 kWh per km
    const evKwhPerKm = 0.18;
    final effectiveEvRatePerKwh = energyNeeded > 0 ? (totalOptimalCost / energyNeeded) : 7.0;
    final evCostPerKm = evKwhPerKm * effectiveEvRatePerKwh;
    final dieselCostPerKm = profile.dieselPricePerLitre / profile.dieselEfficiencyKmPerLitre;
    final evSavingsPer100Km = (dieselCostPerKm - evCostPerKm) * 100.0;

    return ChargingOptimizationPlan(
      vehicleId: profile.vehicleId,
      energyNeededKwh: double.parse(energyNeeded.toStringAsFixed(1)),
      estimatedDurationHours: double.parse(durationHours.toStringAsFixed(2)),
      optimalCost: double.parse(totalOptimalCost.toStringAsFixed(2)),
      unmanagedPeakCost: double.parse(unmanagedCost.toStringAsFixed(2)),
      costSavingsPercent: double.parse(savingsPercent.toStringAsFixed(1)),
      parityCostPerKmEv: double.parse(evCostPerKm.toStringAsFixed(2)),
      parityCostPerKmDiesel: double.parse(dieselCostPerKm.toStringAsFixed(2)),
      evSavingsPer100Km: double.parse(evSavingsPer100Km.toStringAsFixed(2)),
      gridCarbonEmissionKg: double.parse((totalCarbonGrams / 1000.0).toStringAsFixed(2)),
      scheduleBlocks: blocks,
    );
  }
}
