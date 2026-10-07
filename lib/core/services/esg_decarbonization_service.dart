/// ESG Decarbonization and corporate emission rating tier.
enum EsgRatingTier {
  leaderNetZeroAligned, // AAA / AA
  transitionalCompliant, // A / BBB
  laggingHighEmissions,   // BB / B
  nonCompliantCarbonPenalty, // CCC / D
}

/// Fleet operational energy and emissions consumption input.
class FleetEnergyConsumptionTelemetry {
  final double totalDieselLiters;
  final double totalGasolineLiters;
  final double totalGridElectricityKwh;
  final double renewableElectricityPercentage; // 0 to 100%
  final double upstreamThirdPartyFreightTonKm; // Scope 3 logistics
  final double totalFleetDistanceKm;
  final int totalActiveFleetVehicles;

  const FleetEnergyConsumptionTelemetry({
    required this.totalDieselLiters,
    required this.totalGasolineLiters,
    required this.totalGridElectricityKwh,
    required this.renewableElectricityPercentage,
    required this.upstreamThirdPartyFreightTonKm,
    required this.totalFleetDistanceKm,
    required this.totalActiveFleetVehicles,
  });
}

/// Comprehensive ESG Scope 1, Scope 2, Scope 3 corporate sustainability scorecard.
class EsgDecarbonizationScorecard {
  final double scope1DirectCo2Tons;      // Tailpipe fuel combustion
  final double scope2IndirectGridCo2Tons; // Charging electricity
  final double scope3ValueChainCo2Tons;   // Subcontracted logistics
  final double totalGrossCo2Tons;
  final double fleetAverageGramsCo2PerKm;
  final EsgRatingTier ratingTier;
  final double potentialCarbonOffsetCreditCostUsd; // At $65/ton
  final String sustainabilityAdvisory;
  final String keyDecarbonizationLever;

  const EsgDecarbonizationScorecard({
    required this.scope1DirectCo2Tons,
    required this.scope2IndirectGridCo2Tons,
    required this.scope3ValueChainCo2Tons,
    required this.totalGrossCo2Tons,
    required this.fleetAverageGramsCo2PerKm,
    required this.ratingTier,
    required this.potentialCarbonOffsetCreditCostUsd,
    required this.sustainabilityAdvisory,
    required this.keyDecarbonizationLever,
  });
}

/// Service computing GHG Protocol corporate Scope 1, Scope 2, and Scope 3 fleet decarbonization metrics (ISO 14064 standard).
class EsgDecarbonizationService {
  const EsgDecarbonizationService();

  // GHG Protocol Standard Emission Factors (EPA / DEFRA 2024 benchmarks)
  static const double dieselKgCo2PerLiter = 2.68;
  static const double gasolineKgCo2PerLiter = 2.31;
  static const double gridAverageKgCo2PerKwh = 0.385; // Global / US grid average
  static const double scope3FreightKgCo2PerTonKm = 0.082; // Commercial heavy road freight
  static const double carbonShadowPricePerTonUsd = 65.0; // Carbon border adjustment / offset price

  EsgDecarbonizationScorecard generateScorecard(FleetEnergyConsumptionTelemetry telemetry) {
    // 1. Scope 1 (Direct combustion)
    final double dieselEmissionsKg = telemetry.totalDieselLiters * dieselKgCo2PerLiter;
    final double gasolineEmissionsKg = telemetry.totalGasolineLiters * gasolineKgCo2PerLiter;
    final double scope1Tons = (dieselEmissionsKg + gasolineEmissionsKg) / 1000.0;

    // 2. Scope 2 (Indirect electricity generation adjusted for renewables)
    final double nonRenewableKwh = telemetry.totalGridElectricityKwh *
        (1.0 - (telemetry.renewableElectricityPercentage / 100.0).clamp(0.0, 1.0));
    final double scope2Tons = (nonRenewableKwh * gridAverageKgCo2PerKwh) / 1000.0;

    // 3. Scope 3 (Upstream supply chain freight transport)
    final double scope3Tons = (telemetry.upstreamThirdPartyFreightTonKm * scope3FreightKgCo2PerTonKm) / 1000.0;

    // 4. Aggregates
    final double totalGrossTons = scope1Tons + scope2Tons + scope3Tons;
    final double totalCo2Grams = totalGrossTons * 1000000.0;
    final double gramsPerKm = telemetry.totalFleetDistanceKm > 0.0
        ? (totalCo2Grams / telemetry.totalFleetDistanceKm)
        : 0.0;

    final double carbonOffsetCost = totalGrossTons * carbonShadowPricePerTonUsd;

    EsgRatingTier tier;
    String advisory;
    String lever;

    // Rating benchmarks per km across mixed fleet
    if (gramsPerKm <= 95.0) {
      tier = EsgRatingTier.leaderNetZeroAligned;
      advisory = 'ESG LEADER: Fleet emissions intensity aligned with SBTi 1.5°C corporate net-zero trajectory.';
      lever = 'Maintain high renewable PPA contracts and accelerate full EV heavy tractor replacement.';
    } else if (gramsPerKm <= 250.0) {
      tier = EsgRatingTier.transitionalCompliant;
      advisory = 'TRANSITIONAL: Moderate emissions intensity. Partial electrification delivering measurable reductions.';
      lever = 'Shift terminal tractors to BEVs and expand on-site solar solar canopy microgrids.';
    } else if (gramsPerKm <= 550.0) {
      tier = EsgRatingTier.laggingHighEmissions;
      advisory = 'LAGGING BENCHMARK: High reliance on fossil diesel fuel. Approaching carbon compliance penalty thresholds.';
      lever = 'Incorporate HVO100 renewable diesel and enforce idle cut-off telematics across fleet.';
    } else {
      tier = EsgRatingTier.nonCompliantCarbonPenalty;
      advisory = 'CRITICAL CARBON EXPOSURE: Excessive greenhouse gas footprint. Substantial regulatory offset liabilities (\$${carbonOffsetCost.toStringAsFixed(0)}).';
      lever = 'Urgent fleet modernization required under Corporate Sustainability Due Diligence Directive (CSDDD).';
    }

    return EsgDecarbonizationScorecard(
      scope1DirectCo2Tons: double.parse(scope1Tons.toStringAsFixed(2)),
      scope2IndirectGridCo2Tons: double.parse(scope2Tons.toStringAsFixed(2)),
      scope3ValueChainCo2Tons: double.parse(scope3Tons.toStringAsFixed(2)),
      totalGrossCo2Tons: double.parse(totalGrossTons.toStringAsFixed(2)),
      fleetAverageGramsCo2PerKm: double.parse(gramsPerKm.toStringAsFixed(1)),
      ratingTier: tier,
      potentialCarbonOffsetCreditCostUsd: double.parse(carbonOffsetCost.toStringAsFixed(0)),
      sustainabilityAdvisory: advisory,
      keyDecarbonizationLever: lever,
    );
  }
}
