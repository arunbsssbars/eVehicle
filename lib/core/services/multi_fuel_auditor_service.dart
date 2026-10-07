
/// Fuel types supported by commercial and mixed fleets.
enum FleetFuelType {
  diesel,
  petrol,
  cng,
  electric,
}

/// A fuel/energy log entry recorded for a vehicle.
class EnergyLogRecord {
  final String recordId;
  final String vehicleId;
  final DateTime timestamp;
  final FleetFuelType fuelType;
  final double quantityUnits; // Litres for diesel/petrol, kg for CNG, kWh for EV
  final double totalCost; // In currency units
  final double odometerKm;
  final double distanceSinceLastFillKm;

  const EnergyLogRecord({
    required this.recordId,
    required this.vehicleId,
    required this.timestamp,
    required this.fuelType,
    required this.quantityUnits,
    required this.totalCost,
    required this.odometerKm,
    required this.distanceSinceLastFillKm,
  });

  /// Cost per unit of fuel/energy.
  double get unitPrice => quantityUnits > 0 ? totalCost / quantityUnits : 0.0;

  /// Operational fuel/energy efficiency (km/L, km/kg, or km/kWh).
  double get efficiencyRate => quantityUnits > 0 ? distanceSinceLastFillKm / quantityUnits : 0.0;

  /// Energy expenditure cost per kilometer.
  double get costPerKm => distanceSinceLastFillKm > 0 ? totalCost / distanceSinceLastFillKm : 0.0;
}

/// Evaluation result comparing fuel efficiency and cost against diesel fleet baseline.
class EnergyAuditResult {
  final String vehicleId;
  final FleetFuelType fuelType;
  final double averageEfficiency;
  final double averageCostPerKm;
  final double totalQuantity;
  final double totalSpend;
  final double totalDistanceKm;
  final double baselineCostPerKm;
  final double costSavingsPercentage;
  final double co2EmissionsKg;
  final bool isAnomalousConsumption;
  final String recommendation;

  const EnergyAuditResult({
    required this.vehicleId,
    required this.fuelType,
    required this.averageEfficiency,
    required this.averageCostPerKm,
    required this.totalQuantity,
    required this.totalSpend,
    required this.totalDistanceKm,
    required this.baselineCostPerKm,
    required this.costSavingsPercentage,
    required this.co2EmissionsKg,
    required this.isAnomalousConsumption,
    required this.recommendation,
  });
}

/// Multi-Fuel & Alternative Energy Efficiency Auditor Service.
class MultiFuelAuditorService {
  const MultiFuelAuditorService();

  // CO2 factors in kg per unit (Litre, Kg, or kWh)
  static const double dieselCo2PerLitre = 2.68;
  static const double petrolCo2PerLitre = 2.31;
  static const double cngCo2PerKg = 1.95;
  static const double evGridCo2PerKwh = 0.52; // Average national grid mix

  // Baseline commercial diesel cost per km ($/km or ₹/km)
  static const double standardDieselCostPerKm = 0.28;

  EnergyAuditResult auditVehicleEnergy({
    required String vehicleId,
    required FleetFuelType fuelType,
    required List<EnergyLogRecord> records,
    double expectedMinEfficiency = 2.5,
  }) {
    if (records.isEmpty) {
      return EnergyAuditResult(
        vehicleId: vehicleId,
        fuelType: fuelType,
        averageEfficiency: 0.0,
        averageCostPerKm: 0.0,
        totalQuantity: 0.0,
        totalSpend: 0.0,
        totalDistanceKm: 0.0,
        baselineCostPerKm: standardDieselCostPerKm,
        costSavingsPercentage: 0.0,
        co2EmissionsKg: 0.0,
        isAnomalousConsumption: false,
        recommendation: 'Insufficient telemetry to calculate fuel performance.',
      );
    }

    double totalQuantity = 0.0;
    double totalSpend = 0.0;
    double totalDistanceKm = 0.0;

    for (final r in records) {
      totalQuantity += r.quantityUnits;
      totalSpend += r.totalCost;
      totalDistanceKm += r.distanceSinceLastFillKm;
    }

    final avgEfficiency = totalQuantity > 0 ? totalDistanceKm / totalQuantity : 0.0;
    final avgCostPerKm = totalDistanceKm > 0 ? totalSpend / totalDistanceKm : 0.0;

    // Calculate CO2
    double co2Factor;
    switch (fuelType) {
      case FleetFuelType.diesel:
        co2Factor = dieselCo2PerLitre;
        break;
      case FleetFuelType.petrol:
        co2Factor = petrolCo2PerLitre;
        break;
      case FleetFuelType.cng:
        co2Factor = cngCo2PerKg;
        break;
      case FleetFuelType.electric:
        co2Factor = evGridCo2PerKwh;
        break;
    }
    final co2Emissions = totalQuantity * co2Factor;

    // Cost savings vs standard diesel baseline
    final costSavings = standardDieselCostPerKm > 0
        ? ((standardDieselCostPerKm - avgCostPerKm) / standardDieselCostPerKm) * 100
        : 0.0;

    final isAnomalous = avgEfficiency < expectedMinEfficiency && totalDistanceKm > 50;

    String recommendation;
    if (isAnomalous) {
      recommendation = 'Abnormal energy consumption detected. Inspect fuel injectors or battery pack.';
    } else if (fuelType == FleetFuelType.electric) {
      recommendation = 'EV powertrain operating optimally with ${costSavings.toStringAsFixed(1)}% cost savings.';
    } else if (fuelType == FleetFuelType.cng) {
      recommendation = 'CNG economy within green zone with low tailpipe emissions.';
    } else {
      recommendation = 'Fuel economy aligns with fleet operational guidelines.';
    }

    return EnergyAuditResult(
      vehicleId: vehicleId,
      fuelType: fuelType,
      averageEfficiency: double.parse(avgEfficiency.toStringAsFixed(2)),
      averageCostPerKm: double.parse(avgCostPerKm.toStringAsFixed(3)),
      totalQuantity: double.parse(totalQuantity.toStringAsFixed(1)),
      totalSpend: double.parse(totalSpend.toStringAsFixed(2)),
      totalDistanceKm: double.parse(totalDistanceKm.toStringAsFixed(1)),
      baselineCostPerKm: standardDieselCostPerKm,
      costSavingsPercentage: double.parse(costSavings.toStringAsFixed(1)),
      co2EmissionsKg: double.parse(co2Emissions.toStringAsFixed(2)),
      isAnomalousConsumption: isAnomalous,
      recommendation: recommendation,
    );
  }
}
