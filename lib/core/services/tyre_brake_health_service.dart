/// Position of an axle wheel on the vehicle.
enum AxlePosition {
  frontLeft,
  frontRight,
  rearLeft,
  rearRight,
}

/// Real-time health metrics of a specific tyre.
class TyreCondition {
  final AxlePosition position;
  final double treadDepthMm;
  final double currentPsi;
  final double recommendedPsi;

  const TyreCondition({
    required this.position,
    required this.treadDepthMm,
    required this.currentPsi,
    required this.recommendedPsi,
  });

  /// Legal minimum tread depth in most jurisdictions is 1.6 mm.
  bool get isLegallyCompliant => treadDepthMm >= 1.6;

  /// Wear percentage relative to new tyre (~8.0 mm tread).
  double get wearPercentage => (((8.0 - treadDepthMm) / (8.0 - 1.6)) * 100.0).clamp(0.0, 100.0);

  bool get isPressureNominal => (currentPsi - recommendedPsi).abs() <= 3.0;
}

/// Health metrics of a specific brake assembly.
class BrakeCondition {
  final AxlePosition position;
  final double padThicknessMm;
  final double rotorThicknessMm;

  const BrakeCondition({
    required this.position,
    required this.padThicknessMm,
    required this.rotorThicknessMm,
  });

  /// Legal/manufacturer minimum pad thickness is ~2.5 mm (new is ~12.0 mm).
  bool get isSafe => padThicknessMm >= 3.0;

  double get padWearPercent => (((12.0 - padThicknessMm) / (12.0 - 2.5)) * 100.0).clamp(0.0, 100.0);
}

/// Comprehensive vehicle undercarriage & safety wear audit.
class ComponentHealthAudit {
  final Map<AxlePosition, TyreCondition> tyres;
  final Map<AxlePosition, BrakeCondition> brakes;
  final double minTreadDepthMm;
  final double maxBrakeWearPercent;
  final bool isRoadworthy;
  final String safetyAdvisory;

  const ComponentHealthAudit({
    required this.tyres,
    required this.brakes,
    required this.minTreadDepthMm,
    required this.maxBrakeWearPercent,
    required this.isRoadworthy,
    required this.safetyAdvisory,
  });
}

/// Predictive Brake & Tyre Wear Degradation Engine.
class TyreBrakeHealthService {
  const TyreBrakeHealthService();

  /// Simulates wear degradation based on mileage, harsh brake events, and load factor.
  ComponentHealthAudit calculateHealth({
    required double currentOdometerKm,
    required double lastServiceOdometerKm,
    required int harshBrakeEventCount,
    required double grossWeightKg,
    required double ratedGvwrKg,
    double initialTreadDepthMm = 8.0,
    double initialPadThicknessMm = 12.0,
  }) {
    final kmTraveled = (currentOdometerKm - lastServiceOdometerKm).clamp(0.0, double.infinity);
    final loadRatio = (grossWeightKg / (ratedGvwrKg > 0 ? ratedGvwrKg : 1.0)).clamp(0.8, 1.6);

    // Tread wear: ~0.1 mm per 1,000 km standard, multiplied by load factor and harsh braking
    final treadWearPer1000Km = 0.12 * loadRatio;
    final harshBrakePenaltyMm = (harshBrakeEventCount * 0.04);
    final totalTreadLost = (kmTraveled / 1000.0 * treadWearPer1000Km) + harshBrakePenaltyMm;
    final remainingTread = (initialTreadDepthMm - totalTreadLost).clamp(0.5, initialTreadDepthMm);

    // Brake pad wear: ~0.15 mm per 1,000 km, escalated by harsh braking
    final padWearPer1000Km = 0.14 * loadRatio;
    final harshPadPenaltyMm = (harshBrakeEventCount * 0.08);
    final totalPadLost = (kmTraveled / 1000.0 * padWearPer1000Km) + harshPadPenaltyMm;
    final remainingPad = (initialPadThicknessMm - totalPadLost).clamp(1.0, initialPadThicknessMm);

    // Build per-axle distribution (front has ~10% more load due to steering/braking dive)
    final tyres = <AxlePosition, TyreCondition>{};
    final brakes = <AxlePosition, BrakeCondition>{};

    for (final pos in AxlePosition.values) {
      final isFront = pos == AxlePosition.frontLeft || pos == AxlePosition.frontRight;
      final axleTread = isFront ? (remainingTread * 0.95) : (remainingTread * 1.05);
      final axlePad = isFront ? (remainingPad * 0.92) : (remainingPad * 1.04);

      tyres[pos] = TyreCondition(
        position: pos,
        treadDepthMm: double.parse(axleTread.clamp(0.5, 8.0).toStringAsFixed(2)),
        currentPsi: 32.0,
        recommendedPsi: 32.0,
      );

      brakes[pos] = BrakeCondition(
        position: pos,
        padThicknessMm: double.parse(axlePad.clamp(1.0, 12.0).toStringAsFixed(2)),
        rotorThicknessMm: 24.0,
      );
    }

    double minTread = 8.0;
    for (final t in tyres.values) {
      if (t.treadDepthMm < minTread) minTread = t.treadDepthMm;
    }

    double maxBrakeWear = 0.0;
    for (final b in brakes.values) {
      if (b.padWearPercent > maxBrakeWear) maxBrakeWear = b.padWearPercent;
    }

    final isRoadworthy = minTread >= 1.6 && maxBrakeWear < 90.0;

    String advisory;
    if (!isRoadworthy) {
      advisory = 'GROUND VEHICLE: Critical tyre/brake wear below legal safety threshold.';
    } else if (minTread < 3.0 || maxBrakeWear > 70.0) {
      advisory = 'SCHEDULE INSPECTION: Front pads or tyre tread nearing service limit.';
    } else {
      advisory = 'NOMINAL: Brake pads and tyre treads within optimum operating envelope.';
    }

    return ComponentHealthAudit(
      tyres: tyres,
      brakes: brakes,
      minTreadDepthMm: minTread,
      maxBrakeWearPercent: double.parse(maxBrakeWear.toStringAsFixed(1)),
      isRoadworthy: isRoadworthy,
      safetyAdvisory: advisory,
    );
  }
}
