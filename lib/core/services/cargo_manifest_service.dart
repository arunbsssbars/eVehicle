/// Individual cargo item in a transport manifest.
class CargoItem {
  final String id;
  final String description;
  final double unitWeightKg;
  final int quantity;
  final bool isHazardous;
  final String destinationHub;

  const CargoItem({
    required this.id,
    required this.description,
    required this.unitWeightKg,
    required this.quantity,
    this.isHazardous = false,
    required this.destinationHub,
  });

  double get totalWeightKg => unitWeightKg * quantity;
}

/// Regulatory compliance status for vehicle weight limits.
enum WeightComplianceStatus {
  legal,
  nearCapacity, // 90% - 100% of GVWR
  overloaded,   // > 100% of GVWR
}

/// Comprehensive vehicle cargo payload and axle distribution audit.
class WeightComplianceAudit {
  final double tareWeightKg; // Empty vehicle weight
  final double totalCargoWeightKg;
  final double grossVehicleWeightKg;
  final double gvwrLimitKg;
  final double payloadCapacityKg;
  final double utilizationPercentage;
  final WeightComplianceStatus status;
  final double frontAxleWeightKg;
  final double rearAxleWeightKg;
  final double finePenaltyUsd;
  final int hazardousItemCount;

  const WeightComplianceAudit({
    required this.tareWeightKg,
    required this.totalCargoWeightKg,
    required this.grossVehicleWeightKg,
    required this.gvwrLimitKg,
    required this.payloadCapacityKg,
    required this.utilizationPercentage,
    required this.status,
    required this.frontAxleWeightKg,
    required this.rearAxleWeightKg,
    required this.finePenaltyUsd,
    required this.hazardousItemCount,
  });
}

/// Enterprise Real-Time Cargo Manifest & Weight Overload Compliance Engine.
class CargoManifestService {
  const CargoManifestService();

  /// Audits cargo items against vehicle tare weight and GVWR limits.
  WeightComplianceAudit evaluatePayload({
    required List<CargoItem> manifest,
    required double tareWeightKg,
    required double gvwrLimitKg,
    double frontAxleRatio = 0.35, // Typically 35% front, 65% rear for commercial vans/trucks
  }) {
    double cargoWeight = 0.0;
    int hazardousCount = 0;

    for (final item in manifest) {
      cargoWeight += item.totalWeightKg;
      if (item.isHazardous) hazardousCount += item.quantity;
    }

    final grossWeight = tareWeightKg + cargoWeight;
    final payloadCap = (gvwrLimitKg - tareWeightKg).clamp(0.0, double.infinity);
    final utilization = (grossWeight / (gvwrLimitKg > 0 ? gvwrLimitKg : 1.0)) * 100.0;

    WeightComplianceStatus status;
    double fine = 0.0;

    if (grossWeight > gvwrLimitKg) {
      status = WeightComplianceStatus.overloaded;
      final excessKg = grossWeight - gvwrLimitKg;
      // Typical DOT fine formula: $250 base + $1.50 per kg over limit
      fine = 250.0 + (excessKg * 1.50);
    } else if (utilization >= 90.0) {
      status = WeightComplianceStatus.nearCapacity;
    } else {
      status = WeightComplianceStatus.legal;
    }

    // Weight distribution across axles
    final frontWeight = grossWeight * frontAxleRatio;
    final rearWeight = grossWeight * (1.0 - frontAxleRatio);

    return WeightComplianceAudit(
      tareWeightKg: double.parse(tareWeightKg.toStringAsFixed(1)),
      totalCargoWeightKg: double.parse(cargoWeight.toStringAsFixed(1)),
      grossVehicleWeightKg: double.parse(grossWeight.toStringAsFixed(1)),
      gvwrLimitKg: double.parse(gvwrLimitKg.toStringAsFixed(1)),
      payloadCapacityKg: double.parse(payloadCap.toStringAsFixed(1)),
      utilizationPercentage: double.parse(utilization.toStringAsFixed(1)),
      status: status,
      frontAxleWeightKg: double.parse(frontWeight.toStringAsFixed(1)),
      rearAxleWeightKg: double.parse(rearWeight.toStringAsFixed(1)),
      finePenaltyUsd: double.parse(fine.toStringAsFixed(2)),
      hazardousItemCount: hazardousCount,
    );
  }
}
