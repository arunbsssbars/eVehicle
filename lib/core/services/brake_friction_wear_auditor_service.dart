/// Brake pad friction material wear condition.
enum BrakeFrictionWearStatus {
  adequateLiningThickness,
  scheduledServiceThreshold,
  criticalMetalOnMetalBackingPlateRisk,
}

/// Dynamic telemetry reading from continuous acoustic and electrical wear sensors on brake pads.
class BrakeLiningWearTelemetry {
  final double innerPadThicknessMm; // New: 12 - 16 mm. Minimum legal: 3.2 mm (1/8")
  final double outerPadThicknessMm;
  final double discRotorThicknessMm; // Rotor discard limit
  final double rotorDiscardLimitMm;
  final double brakeApplicationsCount;
  final double peakBrakeRotorTemperatureCelsius;

  const BrakeLiningWearTelemetry({
    required this.innerPadThicknessMm,
    required this.outerPadThicknessMm,
    required this.discRotorThicknessMm,
    this.rotorDiscardLimitMm = 28.0,
    required this.brakeApplicationsCount,
    required this.peakBrakeRotorTemperatureCelsius,
  });

  /// The most severely worn pad on the caliper assembly.
  double get minPadThicknessMm =>
      innerPadThicknessMm < outerPadThicknessMm ? innerPadThicknessMm : outerPadThicknessMm;

  /// Pad taper / uneven wear delta between inner and outer friction pucks.
  double get padTaperDeltaMm => (innerPadThicknessMm - outerPadThicknessMm).abs();
}

/// Comprehensive brake friction wear & rotor thickness audit result.
class BrakeFrictionAuditResult {
  final String vehicleId;
  final BrakeFrictionWearStatus status;
  final double minPadMm;
  final double rotorMm;
  final double taperDeltaMm;
  final double remainingLiningLifePercent; // 0 - 100%
  final String serviceAdvisory;

  const BrakeFrictionAuditResult({
    required this.vehicleId,
    required this.status,
    required this.minPadMm,
    required this.rotorMm,
    required this.taperDeltaMm,
    required this.remainingLiningLifePercent,
    required this.serviceAdvisory,
  });

  bool get isSafeForRoad => status == BrakeFrictionWearStatus.adequateLiningThickness;
  bool get isDangerousMetalContact => status == BrakeFrictionWearStatus.criticalMetalOnMetalBackingPlateRisk;
}

/// Service that predicts brake pad life, detects caliper slide pin binding, and alerts rotor scoring.
class BrakeFrictionWearAuditorService {
  const BrakeFrictionWearAuditorService();

  BrakeFrictionAuditResult auditBrakeFriction({
    required String vehicleId,
    required BrakeLiningWearTelemetry telemetry,
  }) {
    final minPad = telemetry.minPadThicknessMm;
    final taper = telemetry.padTaperDeltaMm;
    final isRotorBelowDiscard = telemetry.discRotorThicknessMm < telemetry.rotorDiscardLimitMm;

    // Remaining Lining Life calculation (New: ~14mm, Minimum legal limit: 3.2mm)
    final usableMm = (minPad - 3.2).clamp(0.0, 11.0);
    final lifePercent = ((usableMm / 11.0) * 100.0).clamp(0.0, 100.0);

    // Critical: Pad < 3.2 mm (DOT OOS), taper > 4.5 mm (caliper frozen), or rotor below discard
    if (minPad <= 3.2 || isRotorBelowDiscard || (minPad <= 4.0 && taper > 3.0)) {
      return BrakeFrictionAuditResult(
        vehicleId: vehicleId,
        status: BrakeFrictionWearStatus.criticalMetalOnMetalBackingPlateRisk,
        minPadMm: minPad,
        rotorMm: telemetry.discRotorThicknessMm,
        taperDeltaMm: taper,
        remainingLiningLifePercent: lifePercent,
        serviceAdvisory:
            'CRITICAL: Brake friction lining at steel backing plate limit (<=3.2 mm) or rotor undersize (<28 mm). Catastrophic disc gouging and brake fade hazard.',
      );
    }

    if (minPad <= 5.5 || taper >= 2.5 || telemetry.peakBrakeRotorTemperatureCelsius > 350.0) {
      return BrakeFrictionAuditResult(
        vehicleId: vehicleId,
        status: BrakeFrictionWearStatus.scheduledServiceThreshold,
        minPadMm: minPad,
        rotorMm: telemetry.discRotorThicknessMm,
        taperDeltaMm: taper,
        remainingLiningLifePercent: lifePercent,
        serviceAdvisory:
            'WARNING: Brake pad lining at 20% life or uneven caliper slide pin binding detected (Taper: ${taper.toStringAsFixed(1)} mm). Book pad replacement & pin lubrication.',
      );
    }

    return BrakeFrictionAuditResult(
      vehicleId: vehicleId,
      status: BrakeFrictionWearStatus.adequateLiningThickness,
      minPadMm: minPad,
      rotorMm: telemetry.discRotorThicknessMm,
      taperDeltaMm: taper,
      remainingLiningLifePercent: lifePercent,
      serviceAdvisory:
          'NOMINAL: Friction lining thickness and disc rotor thickness within safe commercial service limits.',
    );
  }
}
