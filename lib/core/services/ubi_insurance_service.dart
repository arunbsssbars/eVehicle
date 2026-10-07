import 'dart:math';

/// Actuarial rating tier for Usage-Based Insurance (UBI).
enum InsuranceTier {
  platinumPreferred, // 25% discount
  goldStandard,      // 15% discount
  silverBaseline,    // 0% adjustment (standard book rate)
  elevatedRisk,      // +15% surcharge
  highRiskProvisional // +30% surcharge
}

/// Telemetry risk factors evaluated over an insurance policy billing cycle.
class TelematicsRiskFactors {
  final double monthlyKmDriven;
  final double nightDrivingRatioPercent; // 23:00 - 05:00 high risk window
  final double harshEventsPer100Km;      // Harsh brake + acceleration + cornering
  final double speedCompliancePercent;   // Time spent adhering to posted speed limits

  const TelematicsRiskFactors({
    required this.monthlyKmDriven,
    required this.nightDrivingRatioPercent,
    required this.harshEventsPer100Km,
    required this.speedCompliancePercent,
  });
}

/// Consolidated audit of fleet insurance policy premium adjustments.
class UbiPremiumAudit {
  final double baseMonthlyPremiumUsd;
  final double adjustedMonthlyPremiumUsd;
  final double netMonthlySavingsUsd;
  final double premiumAdjustmentPercent; // Negative = discount, Positive = surcharge
  final InsuranceTier tier;
  final double compositeRiskScore; // 0 (impeccable) to 100 (extreme hazard)
  final String actuarialSummary;

  const UbiPremiumAudit({
    required this.baseMonthlyPremiumUsd,
    required this.adjustedMonthlyPremiumUsd,
    required this.netMonthlySavingsUsd,
    required this.premiumAdjustmentPercent,
    required this.tier,
    required this.compositeRiskScore,
    required this.actuarialSummary,
  });
}

/// Enterprise Fleet Insurance Telematics & UBI Premium Engine.
class UbiInsuranceService {
  const UbiInsuranceService();

  /// Calculates actuarial risk score and adjusts monthly insurance premium.
  UbiPremiumAudit calculatePremium({
    required double baseMonthlyPremiumUsd,
    required TelematicsRiskFactors factors,
  }) {
    // Actuarial weighting:
    // 1. Harsh events (40% weight): 0 events = 0 risk; 5 events/100km = 40 risk
    final harshRisk = (factors.harshEventsPer100Km * 8.0).clamp(0.0, 40.0);

    // 2. Speed compliance (30% weight): 100% compliance = 0 risk; 70% compliance = 30 risk
    final speedDeficit = (100.0 - factors.speedCompliancePercent).clamp(0.0, 100.0);
    final speedRisk = (speedDeficit * 0.30).clamp(0.0, 30.0);

    // 3. Night driving (20% weight): 0% night = 0 risk; 40% night = 20 risk
    final nightRisk = (factors.nightDrivingRatioPercent * 0.50).clamp(0.0, 20.0);

    // 4. Mileage exposure (10% weight): > 4,000 km/mo increases collision exposure
    final mileageRisk = factors.monthlyKmDriven > 4000.0
        ? min(10.0, ((factors.monthlyKmDriven - 4000.0) / 1000.0) * 2.5)
        : 0.0;

    final compositeRisk = (harshRisk + speedRisk + nightRisk + mileageRisk).clamp(0.0, 100.0);

    InsuranceTier tier;
    double adjustmentPercent;
    String summary;

    if (compositeRisk <= 15.0) {
      tier = InsuranceTier.platinumPreferred;
      adjustmentPercent = -25.0; // 25% discount
      summary = 'PLATINUM PREFERRED: Flawless driving profile qualifies for maximum 25% policy discount.';
    } else if (compositeRisk <= 30.0) {
      tier = InsuranceTier.goldStandard;
      adjustmentPercent = -15.0; // 15% discount
      summary = 'GOLD STANDARD: Above-average safety telemetry qualifies for 15% dividend credit.';
    } else if (compositeRisk <= 50.0) {
      tier = InsuranceTier.silverBaseline;
      adjustmentPercent = 0.0;
      summary = 'SILVER BASELINE: Standard fleet operational risk profile. Baseline rates apply.';
    } else if (compositeRisk <= 70.0) {
      tier = InsuranceTier.elevatedRisk;
      adjustmentPercent = 15.0; // +15% surcharge
      summary = 'ELEVATED RISK: Elevated harsh events or night driving incurs a 15% telematics surcharge.';
    } else {
      tier = InsuranceTier.highRiskProvisional;
      adjustmentPercent = 30.0; // +30% surcharge
      summary = 'HIGH RISK: Critical risk indicators detected. Mandatory driver safety coaching required.';
    }

    final adjustedPremium = baseMonthlyPremiumUsd * (1.0 + (adjustmentPercent / 100.0));
    final netSavings = baseMonthlyPremiumUsd - adjustedPremium;

    return UbiPremiumAudit(
      baseMonthlyPremiumUsd: double.parse(baseMonthlyPremiumUsd.toStringAsFixed(2)),
      adjustedMonthlyPremiumUsd: double.parse(adjustedPremium.toStringAsFixed(2)),
      netMonthlySavingsUsd: double.parse(netSavings.toStringAsFixed(2)),
      premiumAdjustmentPercent: double.parse(adjustmentPercent.toStringAsFixed(1)),
      tier: tier,
      compositeRiskScore: double.parse(compositeRisk.toStringAsFixed(1)),
      actuarialSummary: summary,
    );
  }
}
