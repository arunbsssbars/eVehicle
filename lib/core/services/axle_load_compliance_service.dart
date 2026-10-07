/// Axle group classification on heavy commercial vehicles.
enum AxleType {
  steerSingle,
  driveTandem,
  trailerTridem,
}

/// Weight measurement for a specific axle group.
class AxleGroupWeight {
  final AxleType type;
  final String label;
  final double measuredWeightKg;
  final double legalMaxWeightKg;

  const AxleGroupWeight({
    required this.type,
    required this.label,
    required this.measuredWeightKg,
    required this.legalMaxWeightKg,
  });

  bool get isOverloaded => measuredWeightKg > legalMaxWeightKg;
  double get overloadDeltaKg => (measuredWeightKg - legalMaxWeightKg).clamp(0.0, double.infinity);
}

/// Vehicle axle load configuration & chassis dimensions.
class AxleConfiguration {
  final String vehicleId;
  final String registrationNumber;
  final int totalAxleCount;
  final double wheelbaseMeters; // distance from outer front to outer rear axle
  final double maxGvwrKg; // Gross Vehicle Weight Rating
  final List<AxleGroupWeight> axles;

  const AxleConfiguration({
    required this.vehicleId,
    required this.registrationNumber,
    required this.totalAxleCount,
    required this.wheelbaseMeters,
    required this.maxGvwrKg,
    required this.axles,
  });
}

/// Comprehensive axle weight and bridge formula audit result.
class AxleWeightAuditResult {
  final String vehicleId;
  final double totalGrossWeightKg;
  final double maxAllowedBridgeWeightKg;
  final bool isGvwrCompliant;
  final bool isBridgeFormulaCompliant;
  final bool isAnyAxleOverloaded;
  final double steerWeightPercent;
  final double driveWeightPercent;
  final double trailerWeightPercent;
  final double overloadPenaltyEstimate;
  final List<String> violationReasons;

  const AxleWeightAuditResult({
    required this.vehicleId,
    required this.totalGrossWeightKg,
    required this.maxAllowedBridgeWeightKg,
    required this.isGvwrCompliant,
    required this.isBridgeFormulaCompliant,
    required this.isAnyAxleOverloaded,
    required this.steerWeightPercent,
    required this.driveWeightPercent,
    required this.trailerWeightPercent,
    required this.overloadPenaltyEstimate,
    required this.violationReasons,
  });

  bool get isFullyCompliant => isGvwrCompliant && isBridgeFormulaCompliant && !isAnyAxleOverloaded;
}

/// Heavy Vehicle Axle Load & Bridge Weight Limit Compliance Sentinel.
class AxleLoadComplianceService {
  const AxleLoadComplianceService();

  /// Evaluates vehicle axle load distribution and Federal/National bridge limits.
  AxleWeightAuditResult evaluateAxleLoads(AxleConfiguration config) {
    double totalWeight = 0.0;
    double steerWeight = 0.0;
    double driveWeight = 0.0;
    double trailerWeight = 0.0;
    bool anyAxleOverloaded = false;
    final List<String> violations = [];

    for (final axle in config.axles) {
      totalWeight += axle.measuredWeightKg;
      if (axle.isOverloaded) {
        anyAxleOverloaded = true;
        violations.add('${axle.label} overloaded by ${axle.overloadDeltaKg.toStringAsFixed(0)} kg.');
      }

      switch (axle.type) {
        case AxleType.steerSingle:
          steerWeight += axle.measuredWeightKg;
          break;
        case AxleType.driveTandem:
          driveWeight += axle.measuredWeightKg;
          break;
        case AxleType.trailerTridem:
          trailerWeight += axle.measuredWeightKg;
          break;
      }
    }

    final bool gvwrCompliant = totalWeight <= config.maxGvwrKg;
    if (!gvwrCompliant) {
      violations.add('Total GVW (${totalWeight.toStringAsFixed(0)} kg) exceeds GVWR (${config.maxGvwrKg.toStringAsFixed(0)} kg).');
    }

    // Federal Bridge Formula:
    // W = 500 * [ (L * N) / (N - 1) + 12N + 36 ] (in lbs)
    // Convert meters to feet: 1 m ≈ 3.28084 ft
    final lFeet = config.wheelbaseMeters * 3.28084;
    final n = config.totalAxleCount;
    final bridgeWeightLbs = n > 1
        ? 500.0 * (((lFeet * n) / (n - 1)) + (12.0 * n) + 36.0)
        : config.maxGvwrKg * 2.20462;

    // Convert lbs to kg: 1 lb ≈ 0.453592 kg
    final maxBridgeWeightKg = bridgeWeightLbs * 0.453592;
    final bool bridgeCompliant = totalWeight <= maxBridgeWeightKg;
    if (!bridgeCompliant) {
      violations.add('Bridge formula capacity (${maxBridgeWeightKg.toStringAsFixed(0)} kg) exceeded by ${(totalWeight - maxBridgeWeightKg).toStringAsFixed(0)} kg.');
    }

    // Weight distribution percentages
    final steerPct = totalWeight > 0 ? (steerWeight / totalWeight) * 100.0 : 0.0;
    final drivePct = totalWeight > 0 ? (driveWeight / totalWeight) * 100.0 : 0.0;
    final trailerPct = totalWeight > 0 ? (trailerWeight / totalWeight) * 100.0 : 0.0;

    // Penalty estimate calculation (₹2,000 base + ₹1,000 per extra ton)
    double penalty = 0.0;
    if (totalWeight > config.maxGvwrKg) {
      final excessTonnes = (totalWeight - config.maxGvwrKg) / 1000.0;
      penalty += 2000.0 + (excessTonnes * 1000.0);
    }
    if (anyAxleOverloaded) {
      penalty += 3000.0;
    }

    return AxleWeightAuditResult(
      vehicleId: config.vehicleId,
      totalGrossWeightKg: double.parse(totalWeight.toStringAsFixed(1)),
      maxAllowedBridgeWeightKg: double.parse(maxBridgeWeightKg.toStringAsFixed(1)),
      isGvwrCompliant: gvwrCompliant,
      isBridgeFormulaCompliant: bridgeCompliant,
      isAnyAxleOverloaded: anyAxleOverloaded,
      steerWeightPercent: double.parse(steerPct.toStringAsFixed(1)),
      driveWeightPercent: double.parse(drivePct.toStringAsFixed(1)),
      trailerWeightPercent: double.parse(trailerPct.toStringAsFixed(1)),
      overloadPenaltyEstimate: double.parse(penalty.toStringAsFixed(2)),
      violationReasons: violations,
    );
  }
}
