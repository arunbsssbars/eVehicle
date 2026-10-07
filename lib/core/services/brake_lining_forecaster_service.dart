/// Brake pad lining friction material type.
enum BrakeMaterialType {
  organic,
  semiMetallic,
  ceramic,
  sinteredMetallic,
}

/// Dynamic telemetry snapshot of wheel brake conditions.
class BrakeLiningTelemetry {
  final String axleId;
  final double currentThicknessMm;
  final double initialThicknessMm;
  final double discardThicknessMm;
  final double accumulatedKilometers;
  final double averageApplicationCyclesPer100Km;
  final BrakeMaterialType material;

  const BrakeLiningTelemetry({
    required this.axleId,
    required this.currentThicknessMm,
    this.initialThicknessMm = 18.0,
    this.discardThicknessMm = 3.0,
    required this.accumulatedKilometers,
    this.averageApplicationCyclesPer100Km = 35.0,
    this.material = BrakeMaterialType.semiMetallic,
  });

  /// Usable friction material remaining in mm.
  double get usableThicknessMm =>
      (currentThicknessMm - discardThicknessMm).clamp(0.0, initialThicknessMm);

  /// Total usable wear capacity in mm.
  double get totalUsableThicknessMm => initialThicknessMm - discardThicknessMm;

  /// Wear degradation percentage (0% = new, 100% = completely worn out).
  double get wearPercentage =>
      totalUsableThicknessMm > 0 ? ((1.0 - (usableThicknessMm / totalUsableThicknessMm)) * 100).clamp(0.0, 100.0) : 100.0;
}

/// Evaluation result for predictive brake pad wear and lifespan forecasting.
class BrakeLiningForecastResult {
  final String vehicleId;
  final String axleId;
  final double currentThicknessMm;
  final double wearPercentage;
  final double wearRatePer1000Km; // mm worn per 1,000 km
  final double estimatedRemainingKm;
  final bool isReplacementDue;
  final bool isImmediateGrounded;
  final String advisoryMessage;

  const BrakeLiningForecastResult({
    required this.vehicleId,
    required this.axleId,
    required this.currentThicknessMm,
    required this.wearPercentage,
    required this.wearRatePer1000Km,
    required this.estimatedRemainingKm,
    required this.isReplacementDue,
    required this.isImmediateGrounded,
    required this.advisoryMessage,
  });
}

/// Predictive Brake Pad Wear & Rotor Glazing Lifecycle Forecaster Service.
class BrakeLiningForecasterService {
  const BrakeLiningForecasterService();

  BrakeLiningForecastResult forecastBrakeLifespan({
    required String vehicleId,
    required BrakeLiningTelemetry telemetry,
    double severityFactor = 1.0, // Multiplier for mountain / city heavy brake usage
  }) {
    final wornMm = telemetry.initialThicknessMm - telemetry.currentThicknessMm;
    final km = telemetry.accumulatedKilometers;

    // Default rate if vehicle has very low mileage yet
    double ratePer1000Km = km > 100.0
        ? (wornMm / (km / 1000.0)) * severityFactor
        : 0.15 * severityFactor;

    if (ratePer1000Km <= 0.01) {
      ratePer1000Km = 0.10; // Baseline minimum wear
    }

    final remainingMm = telemetry.usableThicknessMm;
    final estimatedKm = (remainingMm / ratePer1000Km) * 1000.0;

    final isGrounded = telemetry.currentThicknessMm <= telemetry.discardThicknessMm;
    final isReplacementDue = isGrounded || remainingMm <= 2.0 || estimatedKm <= 2000.0;

    String advisory;
    if (isGrounded) {
      advisory = 'DANGER: Brake pad below statutory minimum (${telemetry.discardThicknessMm} mm). Metal-to-metal contact risk. Ground immediately.';
    } else if (isReplacementDue) {
      advisory = 'WARNING: Brake replacement due within ${estimatedKm.toStringAsFixed(0)} km. Schedule bay maintenance.';
    } else {
      advisory = 'Brake linings nominal. Estimated lifespan: ${estimatedKm.toStringAsFixed(0)} km remaining.';
    }

    return BrakeLiningForecastResult(
      vehicleId: vehicleId,
      axleId: telemetry.axleId,
      currentThicknessMm: double.parse(telemetry.currentThicknessMm.toStringAsFixed(1)),
      wearPercentage: double.parse(telemetry.wearPercentage.toStringAsFixed(1)),
      wearRatePer1000Km: double.parse(ratePer1000Km.toStringAsFixed(3)),
      estimatedRemainingKm: double.parse(estimatedKm.toStringAsFixed(0)),
      isReplacementDue: isReplacementDue,
      isImmediateGrounded: isGrounded,
      advisoryMessage: advisory,
    );
  }
}
