import '../models/journey.dart';
import '../models/vehicle.dart';

/// Service calculating greenhouse gas (GHG) & Carbon Dioxide (CO2) footprints
/// for fleet sustainability compliance (ESG) and individual eco-conscious tracking.
class CarbonEmissionsService {
  const CarbonEmissionsService();

  /// Standard Emission factors in kg CO2 per liter (or kg for CNG, kWh for EV)
  /// Grounded in IPCC & Central Pollution Control Board (CPCB) fleet guidelines.
  static const double factorDiesel = 2.68; // kg CO2 / Liter
  static const double factorPetrol = 2.31; // kg CO2 / Liter
  static const double factorCng = 1.82;    // kg CO2 / kg
  static const double factorHybrid = 1.45; // kg CO2 / Liter
  static const double factorElectricDirect = 0.0; // Zero direct tailpipe emissions
  static const double factorElectricIndirectPerKm = 0.052; // Average grid-source indirect

  /// Returns the emission factor (kg CO2 per unit fuel) for a given fuel type string
  static double getFactorForFuelType(String fuelType) {
    final lower = fuelType.toLowerCase();
    if (lower.contains('diesel')) return factorDiesel;
    if (lower.contains('petrol') || lower.contains('gasoline')) return factorPetrol;
    if (lower.contains('cng')) return factorCng;
    if (lower.contains('hybrid')) return factorHybrid;
    if (lower.contains('electric') || lower.contains('ev')) return factorElectricDirect;
    return factorDiesel; // Default conservative fallback
  }

  /// Calculates total CO2 emissions in kilograms for a single journey distance
  static double calculateJourneyEmissionsKg({
    required double distanceKm,
    required String fuelType,
    double efficiencyKmPerUnit = 14.8,
  }) {
    if (distanceKm <= 0) return 0.0;
    final lower = fuelType.toLowerCase();
    if (lower.contains('electric') || lower.contains('ev')) {
      return distanceKm * factorElectricIndirectPerKm;
    }
    final effectiveEfficiency = efficiencyKmPerUnit > 0 ? efficiencyKmPerUnit : 14.8;
    final fuelConsumed = distanceKm / effectiveEfficiency;
    final factor = getFactorForFuelType(fuelType);
    return fuelConsumed * factor;
  }

  /// Calculates total platform or organization fleet emissions
  static double calculateFleetEmissionsKg({
    required List<Journey> journeys,
    required List<Vehicle> vehicles,
  }) {
    final vehicleMap = {for (final v in vehicles) v.id: v};
    double totalKg = 0.0;

    for (final j in journeys) {
      final v = vehicleMap[j.vehicleId];
      final fuelType = v?.fuelType ?? 'Diesel';
      final eff = v?.fuelEfficiencyAvg ?? 14.8;
      totalKg += calculateJourneyEmissionsKg(
        distanceKm: j.calculatedDistance,
        fuelType: fuelType,
        efficiencyKmPerUnit: eff,
      );
    }
    return totalKg;
  }

  /// Calculates Carbon Savings in kilograms achieved by Electric & Hybrid vehicles
  /// compared to a standard diesel fleet baseline (~0.181 kg CO2 / KM)
  static double calculateCarbonSavedKg({
    required List<Journey> journeys,
    required List<Vehicle> vehicles,
  }) {
    final vehicleMap = {for (final v in vehicles) v.id: v};
    const baselinePerKm = 0.181; // standard ICE fleet average
    double savedKg = 0.0;

    for (final j in journeys) {
      final v = vehicleMap[j.vehicleId];
      if (v != null && (v.isElectric || v.fuelType.toLowerCase().contains('hybrid'))) {
        final actual = calculateJourneyEmissionsKg(
          distanceKm: j.calculatedDistance,
          fuelType: v.fuelType,
          efficiencyKmPerUnit: v.fuelEfficiencyAvg,
        );
        final baseline = j.calculatedDistance * baselinePerKm;
        if (baseline > actual) {
          savedKg += (baseline - actual);
        }
      }
    }
    return savedKg;
  }

  /// Computes an Eco-Rating Score from 0 to 100 for a fleet or individual
  /// 90-100: 'A+ Green Fleet'
  /// 75-89:  'B Efficient'
  /// 50-74:  'C Moderate'
  /// <50:    'D High Emitter'
  static EcoRating getEcoRating({
    required double totalDistanceKm,
    required double totalEmissionsKg,
  }) {
    if (totalDistanceKm <= 0) {
      return const EcoRating(
        score: 100,
        grade: 'A+',
        label: 'Zero Emission / Idle',
        colorValue: 0xFF16A34A,
      );
    }

    final avgGramsPerKm = (totalEmissionsKg / totalDistanceKm) * 1000.0;

    if (avgGramsPerKm <= 60.0) {
      return const EcoRating(
        score: 95,
        grade: 'A+',
        label: 'Green Fleet Leader',
        colorValue: 0xFF16A34A,
      );
    } else if (avgGramsPerKm <= 120.0) {
      return const EcoRating(
        score: 82,
        grade: 'B',
        label: 'Eco Efficient',
        colorValue: 0xFF0D9488,
      );
    } else if (avgGramsPerKm <= 180.0) {
      return const EcoRating(
        score: 68,
        grade: 'C',
        label: 'Moderate Footprint',
        colorValue: 0xFFEA580C,
      );
    } else {
      return const EcoRating(
        score: 45,
        grade: 'D',
        label: 'High Emission Alert',
        colorValue: 0xFFDC2626,
      );
    }
  }
}

class EcoRating {
  final int score;
  final String grade;
  final String label;
  final int colorValue;

  const EcoRating({
    required this.score,
    required this.grade,
    required this.label,
    required this.colorValue,
  });
}
