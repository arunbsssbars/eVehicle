import 'dart:math' as math;

/// Types of pneumatic or hydraulic fifth wheel locking mechanisms.
enum FifthWheelLockType {
  airActuatedJaw,
  manualSecondaryLock,
  magneticKingpinProximity,
}

/// Telemetry reading from the fifth wheel coupler sensors.
class FifthWheelTelemetry {
  final double kingpinDepthMm; // Nominal full engagement: 45.0 - 55.0 mm
  final double jawClampPressureBar; // Nominal: >= 120.0 bar for hydraulic / air
  final bool isSecondarySafetyLockEngaged;
  final double trailerLoadMetricTons;
  final double couplingAngleDegrees; // Must be < 15 degrees during coupling

  const FifthWheelTelemetry({
    required this.kingpinDepthMm,
    required this.jawClampPressureBar,
    required this.isSecondarySafetyLockEngaged,
    required this.trailerLoadMetricTons,
    required this.couplingAngleDegrees,
  });
}

/// Safety status of the tractor-trailer fifth wheel coupling.
enum FifthWheelSecurityStatus {
  securelyLocked,
  warningImproperAlignment,
  criticalFalseLockRisk,
}

/// Evaluation result for fifth wheel coupling security.
class FifthWheelCouplingResult {
  final String vehicleId;
  final FifthWheelSecurityStatus status;
  final double kingpinDepthMm;
  final double jawClampPressureBar;
  final bool isSecondaryEngaged;
  final double hitchIntegrityScorePercent;
  final String safetyAdvisory;

  const FifthWheelCouplingResult({
    required this.vehicleId,
    required this.status,
    required this.kingpinDepthMm,
    required this.jawClampPressureBar,
    required this.isSecondaryEngaged,
    required this.hitchIntegrityScorePercent,
    required this.safetyAdvisory,
  });

  bool get isSafeToDrive => status == FifthWheelSecurityStatus.securelyLocked;
  bool get isCritical => status == FifthWheelSecurityStatus.criticalFalseLockRisk;
}

/// Service that evaluates fifth wheel tractor-trailer coupling to prevent dropped trailers.
class FifthWheelCouplingGuardService {
  const FifthWheelCouplingGuardService();

  FifthWheelCouplingResult evaluateCoupling({
    required String vehicleId,
    required FifthWheelTelemetry telemetry,
  }) {
    // 1. Kingpin penetration check (must be 45-55 mm)
    final isKingpinProperlySeated =
        telemetry.kingpinDepthMm >= 45.0 && telemetry.kingpinDepthMm <= 58.0;

    // 2. Jaw clamping pressure (minimum 100 bar)
    final isPressureSufficient = telemetry.jawClampPressureBar >= 100.0;

    // 3. Angular misalignment during coupling
    final isAngleAcceptable = telemetry.couplingAngleDegrees.abs() <= 12.0;

    // Calculate hitch integrity score (0 - 100%)
    double score = 100.0;
    if (!isKingpinProperlySeated) {
      final dev = (telemetry.kingpinDepthMm - 50.0).abs();
      score -= math.min(50.0, dev * 4.0);
    }
    if (!isPressureSufficient) {
      score -= math.min(30.0, (100.0 - telemetry.jawClampPressureBar) * 0.5);
    }
    if (!telemetry.isSecondarySafetyLockEngaged) {
      score -= 25.0;
    }
    if (!isAngleAcceptable) {
      score -= 15.0;
    }
    score = score.clamp(0.0, 100.0);

    // Determine status & advisory
    if (!isKingpinProperlySeated ||
        telemetry.jawClampPressureBar < 70.0 ||
        (!telemetry.isSecondarySafetyLockEngaged && telemetry.jawClampPressureBar < 110.0)) {
      return FifthWheelCouplingResult(
        vehicleId: vehicleId,
        status: FifthWheelSecurityStatus.criticalFalseLockRisk,
        kingpinDepthMm: telemetry.kingpinDepthMm,
        jawClampPressureBar: telemetry.jawClampPressureBar,
        isSecondaryEngaged: telemetry.isSecondarySafetyLockEngaged,
        hitchIntegrityScorePercent: score,
        safetyAdvisory:
            'CRITICAL: False coupling detected! Kingpin unseated or lock jaw disengaged. Immediate trailer drop risk.',
      );
    }

    if (!telemetry.isSecondarySafetyLockEngaged || !isAngleAcceptable || telemetry.jawClampPressureBar < 115.0) {
      return FifthWheelCouplingResult(
        vehicleId: vehicleId,
        status: FifthWheelSecurityStatus.warningImproperAlignment,
        kingpinDepthMm: telemetry.kingpinDepthMm,
        jawClampPressureBar: telemetry.jawClampPressureBar,
        isSecondaryEngaged: telemetry.isSecondarySafetyLockEngaged,
        hitchIntegrityScorePercent: score,
        safetyAdvisory:
            'WARNING: Secondary safety latch not locked or articulation angle offset. Inspect coupler dog before highway speed.',
      );
    }

    return FifthWheelCouplingResult(
      vehicleId: vehicleId,
      status: FifthWheelSecurityStatus.securelyLocked,
      kingpinDepthMm: telemetry.kingpinDepthMm,
      jawClampPressureBar: telemetry.jawClampPressureBar,
      isSecondaryEngaged: telemetry.isSecondarySafetyLockEngaged,
      hitchIntegrityScorePercent: score,
      safetyAdvisory:
          'NOMINAL: Fifth wheel locking mechanism securely seated. Safe for rated payload transport.',
    );
  }
}
