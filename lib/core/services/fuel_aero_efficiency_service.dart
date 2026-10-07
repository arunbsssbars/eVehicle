import 'dart:math';

/// Aerodynamic and rolling resistance parameters of a vehicle type.
class VehicleAeroProfile {
  final double frontalAreaM2;      // e.g. 2.4 m² for car, 3.8 m² for cargo van, 7.5 m² for semi
  final double dragCoefficientCd;  // e.g. 0.30 for sedan, 0.42 for van, 0.65 for box truck
  final double curbWeightKg;
  final double engineBaselineL100Km;

  const VehicleAeroProfile({
    this.frontalAreaM2 = 3.6,
    this.dragCoefficientCd = 0.40,
    this.curbWeightKg = 2400.0,
    this.engineBaselineL100Km = 8.5,
  });
}

/// Consolidated audit of aerodynamic drag penalty and recommended cruising speed.
class AeroEfficiencyAudit {
  final double averageSpeedKmph;
  final double percentageTimeHighDrag; // Time above 90 km/h
  final double optimalSpeedKmph;       // Typically 75-82 km/h
  final double excessFuelBurnL100Km;
  final double monthlyCostSavingsUsd;
  final String efficiencyGrade; // A, B, C, D
  final String aeroAdvisory;

  const AeroEfficiencyAudit({
    required this.averageSpeedKmph,
    required this.percentageTimeHighDrag,
    required this.optimalSpeedKmph,
    required this.excessFuelBurnL100Km,
    required this.monthlyCostSavingsUsd,
    required this.efficiencyGrade,
    required this.aeroAdvisory,
  });
}

/// Enterprise Fuel Economy Prediction & Aerodynamic Drag Speed Optimizer.
class FuelAeroEfficiencyService {
  const FuelAeroEfficiencyService();

  /// Estimates fuel consumption at a specific velocity taking aero drag into account.
  double estimateConsumptionAtSpeed(double speedKmph, VehicleAeroProfile profile) {
    if (speedKmph <= 0.0) return 0.0;
    // Speed in m/s
    final v = speedKmph / 3.6;
    // Aero drag force: 0.5 * rho (1.225 kg/m³) * Cd * A * v²
    final aeroForceNewtons = 0.5 * 1.225 * profile.dragCoefficientCd * profile.frontalAreaM2 * v * v;
    // Rolling resistance: Crr (0.012) * m * g
    final rollingForce = 0.012 * profile.curbWeightKg * 9.81;
    final totalResistanceKw = ((aeroForceNewtons + rollingForce) * v) / 1000.0;

    // Fuel consumption: baseline engine friction + thermal efficiency factor (~32% diesel)
    final litersPer100Km = profile.engineBaselineL100Km + (totalResistanceKw * 0.18 * (100.0 / max(1.0, speedKmph)));
    return max(profile.engineBaselineL100Km * 0.8, litersPer100Km);
  }

  /// Analyzes a trip's speed telemetry profile and calculates aerodynamic waste.
  AeroEfficiencyAudit evaluateSpeedProfile({
    required List<double> speedsKmph,
    VehicleAeroProfile profile = const VehicleAeroProfile(),
    double fuelPricePerLiter = 1.45,
    double monthlyProjectedKm = 3500.0,
  }) {
    if (speedsKmph.isEmpty) {
      return const AeroEfficiencyAudit(
        averageSpeedKmph: 0.0,
        percentageTimeHighDrag: 0.0,
        optimalSpeedKmph: 80.0,
        excessFuelBurnL100Km: 0.0,
        monthlyCostSavingsUsd: 0.0,
        efficiencyGrade: 'A',
        aeroAdvisory: 'NOMINAL: No velocity telemetry recorded.',
      );
    }

    double speedSum = 0.0;
    int highDragCount = 0;
    int movingCount = 0;
    double actualConsumptionSum = 0.0;
    const optimalSpeed = 80.0;
    final optimalConsumption = estimateConsumptionAtSpeed(optimalSpeed, profile);

    for (final s in speedsKmph) {
      if (s > 10.0) {
        speedSum += s;
        movingCount++;
        if (s > 90.0) highDragCount++;
        actualConsumptionSum += estimateConsumptionAtSpeed(s, profile);
      }
    }

    final valid = max(1, movingCount);
    final avgSpeed = speedSum / valid;
    final highDragPct = (highDragCount / valid) * 100.0;
    final avgActualConsumption = actualConsumptionSum / valid;

    final excessConsumption = max(0.0, avgActualConsumption - optimalConsumption);
    final monthlyExcessLiters = (monthlyProjectedKm / 100.0) * excessConsumption;
    final monthlySavings = monthlyExcessLiters * fuelPricePerLiter;

    String grade;
    String advisory;

    if (highDragPct <= 10.0) {
      grade = 'A';
      advisory = 'AERODYNAMIC CORRIDOR: Fleet operating in peak aerodynamic sweet-spot.';
    } else if (highDragPct <= 25.0) {
      grade = 'B';
      advisory = 'MODERATE DRAG: Occasional high-speed travel; cruising at 80-85 km/h saves ~8% fuel.';
    } else if (highDragPct <= 50.0) {
      grade = 'C';
      advisory = 'HIGH AERO PENALTY: Significant travel >90 km/h is expending excessive fuel on air resistance.';
    } else {
      grade = 'D';
      advisory = 'SEVERE VELOCITY PENALTY: Over 50% of trip at high drag. Speed governor recommended.';
    }

    return AeroEfficiencyAudit(
      averageSpeedKmph: double.parse(avgSpeed.toStringAsFixed(1)),
      percentageTimeHighDrag: double.parse(highDragPct.toStringAsFixed(1)),
      optimalSpeedKmph: optimalSpeed,
      excessFuelBurnL100Km: double.parse(excessConsumption.toStringAsFixed(2)),
      monthlyCostSavingsUsd: double.parse(monthlySavings.toStringAsFixed(2)),
      efficiencyGrade: grade,
      aeroAdvisory: advisory,
    );
  }
}
