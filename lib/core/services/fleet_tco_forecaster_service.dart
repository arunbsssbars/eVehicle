import 'dart:math';

/// Vehicle cost and asset depreciation input parameters.
class TcoVehicleProfile {
  final double purchasePriceUsd;
  final int currentAgeMonths;
  final double currentOdometerKm;
  final double annualDepreciationRate; // e.g. 0.15 for 15% annual decay

  const TcoVehicleProfile({
    required this.purchasePriceUsd,
    required this.currentAgeMonths,
    required this.currentOdometerKm,
    this.annualDepreciationRate = 0.15,
  });
}

/// Historical operating expenditures (OpEx) for a vehicle.
class TcoExpenseHistory {
  final double cumulativeFuelCostUsd;
  final double cumulativeMaintenanceCostUsd;
  final double cumulativeInsuranceCostUsd;
  final double cumulativeTollsAndTiresUsd;

  const TcoExpenseHistory({
    required this.cumulativeFuelCostUsd,
    required this.cumulativeMaintenanceCostUsd,
    required this.cumulativeInsuranceCostUsd,
    required this.cumulativeTollsAndTiresUsd,
  });

  double get totalOpexUsd =>
      cumulativeFuelCostUsd +
      cumulativeMaintenanceCostUsd +
      cumulativeInsuranceCostUsd +
      cumulativeTollsAndTiresUsd;
}

/// Consolidated audit of vehicle lifecycle Total Cost of Ownership (TCO) and residual value.
class FleetTcoAudit {
  final double totalCostOfOwnershipUsd;
  final double costPerKilometerUsd;
  final double estimatedResidualValueUsd;
  final double cumulativeOpexUsd;
  final int optimalReplacementAgeMonths; // Sweet-spot lifecycle disposal (e.g. 60 months)
  final bool isInReplacementWindow;
  final String lifecyclePhase; // NEW, OPTIMAL_SERVICE, AGING, REPLACE_NOW
  final String strategicAdvisory;

  const FleetTcoAudit({
    required this.totalCostOfOwnershipUsd,
    required this.costPerKilometerUsd,
    required this.estimatedResidualValueUsd,
    required this.cumulativeOpexUsd,
    required this.optimalReplacementAgeMonths,
    required this.isInReplacementWindow,
    required this.lifecyclePhase,
    required this.strategicAdvisory,
  });
}

/// Enterprise Fleet Lifetime Total Cost of Ownership (TCO) & Residual Value Forecaster.
class FleetTcoForecasterService {
  const FleetTcoForecasterService();

  /// Calculates residual value using exponential decay: V(t) = P * (1 - r)^(t / 12)
  double estimateResidualValue(TcoVehicleProfile profile) {
    final years = profile.currentAgeMonths / 12.0;
    final residual = profile.purchasePriceUsd * pow(1.0 - profile.annualDepreciationRate, years);
    return max(profile.purchasePriceUsd * 0.10, residual); // 10% salvage floor
  }

  /// Evaluates full lifetime TCO, Cost-Per-Km (CPK), and optimal replacement horizon.
  FleetTcoAudit forecastTco({
    required TcoVehicleProfile profile,
    required TcoExpenseHistory expenses,
  }) {
    final residual = estimateResidualValue(profile);
    final opex = expenses.totalOpexUsd;
    // Net TCO = (Purchase Price - Residual Value) + OpEx
    final netTco = (profile.purchasePriceUsd - residual) + opex;

    final km = max(1.0, profile.currentOdometerKm);
    final cpk = netTco / km;

    // Optimal replacement age: typically 60 months (5 years) or 200,000 km for commercial fleet
    const optimalMonths = 60;
    const optimalKm = 200000.0;

    final isOverAge = profile.currentAgeMonths >= optimalMonths;
    final isOverKm = profile.currentOdometerKm >= optimalKm;
    final inWindow = isOverAge || isOverKm;

    String phase;
    String advisory;

    if (profile.currentAgeMonths >= 72 || profile.currentOdometerKm >= 240000.0) {
      phase = 'REPLACE_NOW';
      advisory = 'COST INVERSION ZONE: Maintenance escalation exceeds depreciation savings. Dispose and replace asset immediately.';
    } else if (inWindow) {
      phase = 'REPLACEMENT_WINDOW';
      advisory = 'OPTIMAL DISPOSAL WINDOW: Vehicle has reached optimal economic lifecycle. Schedule trade-in to maximize residual value.';
    } else if (profile.currentAgeMonths <= 12) {
      phase = 'NEW';
      advisory = 'EARLY LIFECYCLE: Low maintenance amortizing purchase price smoothly.';
    } else {
      phase = 'OPTIMAL_SERVICE';
      advisory = 'PRIME PRODUCTIVE ASSET: Operating cost per km is stabilized at peak ROI.';
    }

    return FleetTcoAudit(
      totalCostOfOwnershipUsd: double.parse(netTco.toStringAsFixed(2)),
      costPerKilometerUsd: double.parse(cpk.toStringAsFixed(3)),
      estimatedResidualValueUsd: double.parse(residual.toStringAsFixed(2)),
      cumulativeOpexUsd: double.parse(opex.toStringAsFixed(2)),
      optimalReplacementAgeMonths: optimalMonths,
      isInReplacementWindow: inWindow,
      lifecyclePhase: phase,
      strategicAdvisory: advisory,
    );
  }
}
