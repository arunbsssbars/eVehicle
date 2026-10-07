/// Structural pin engagement and hydraulic cylinder lock condition of heavy container twistlocks.
enum IntermodalTwistlockStatus {
  twistlocksLockedAndGrounded,
  manualPositionDiscrepancyWarning,
  criticalUnlatchedHighwayTipoverHazard,
}

/// Dynamic corner-casting optical proximity, strain gauge, and locking latch telemetry on container skeletal trailer.
class IntermodalTwistlockTelemetry {
  final int totalCornerLocksCount; // Typically 4 locks (20ft/40ft chassis).
  final int lockedAndVerifiedCornersCount; // Confirmed by proximity sensors inside ISO casting aperture.
  final double cornerVerticalLoadTonnes; // Total container weight distributed: ~20 - 35 tonnes.
  final double latchEngagementAngleDegrees; // Fully locked = 90.0°. Unlocked = 0.0°.
  final double vehicleRoadSpeedKmh;
  final bool isSecondaryDetentLockPinned; // Mechanical safety lock-pin inserted through handle.

  const IntermodalTwistlockTelemetry({
    this.totalCornerLocksCount = 4,
    required this.lockedAndVerifiedCornersCount,
    required this.cornerVerticalLoadTonnes,
    required this.latchEngagementAngleDegrees,
    required this.vehicleRoadSpeedKmh,
    required this.isSecondaryDetentLockPinned,
  });

  /// True if all 4 ISO corner castings are verified locked 90 degrees with secondary pins.
  bool get areAllCastingsLocked =>
      lockedAndVerifiedCornersCount == totalCornerLocksCount &&
      latchEngagementAngleDegrees >= 85.0 &&
      isSecondaryDetentLockPinned;
}

/// Audit result for intermodal ISO container corner twistlock engagement and highway rollover prevention.
class IntermodalTwistlockAuditResult {
  final String vehicleId;
  final IntermodalTwistlockStatus status;
  final int lockedCount;
  final int totalCount;
  final double lockAngleDegrees;
  final bool isSecondaryPinEngaged;
  final String transportSafetyAdvisory;

  const IntermodalTwistlockAuditResult({
    required this.vehicleId,
    required this.status,
    required this.lockedCount,
    required this.totalCount,
    required this.lockAngleDegrees,
    required this.isSecondaryPinEngaged,
    required this.transportSafetyAdvisory,
  });

  bool get isSafeToTransit => status == IntermodalTwistlockStatus.twistlocksLockedAndGrounded;
  bool get isImminentTipoverRisk =>
      status == IntermodalTwistlockStatus.criticalUnlatchedHighwayTipoverHazard;
}

/// Evaluates skeletal intermodal container chassis corner twistlock lockup, secondary detent pin insertion, and unlatched container rollover risk.
class IntermodalTwistlockAuditorService {
  const IntermodalTwistlockAuditorService();

  IntermodalTwistlockAuditResult auditTwistlocks({
    required String vehicleId,
    required IntermodalTwistlockTelemetry telemetry,
  }) {
    final locked = telemetry.lockedAndVerifiedCornersCount;
    final total = telemetry.totalCornerLocksCount;

    // 1. Critical: Vehicle in motion (>15 km/h) with unlatched corner lock (< 4 locked) or angle < 60°
    if ((locked < total || telemetry.latchEngagementAngleDegrees < 60.0) &&
        telemetry.vehicleRoadSpeedKmh > 15.0 &&
        telemetry.cornerVerticalLoadTonnes > 5.0) {
      return IntermodalTwistlockAuditResult(
        vehicleId: vehicleId,
        status: IntermodalTwistlockStatus.criticalUnlatchedHighwayTipoverHazard,
        lockedCount: locked,
        totalCount: total,
        lockAngleDegrees: telemetry.latchEngagementAngleDegrees,
        isSecondaryPinEngaged: telemetry.isSecondaryDetentLockPinned,
        transportSafetyAdvisory:
            'CRITICAL ROLLOVER HAZARD: Container skeletal twistlock unlatched while vehicle moving ($locked/$total locked at ${telemetry.vehicleRoadSpeedKmh.toStringAsFixed(0)} km/h)! Container detachment imminent in high-speed highway bend. Bring vehicle to emergency stop.',
      );
    }

    // 2. Warning: Twistlock rotated 90° but secondary safety detent pin omitted
    if (!telemetry.isSecondaryDetentLockPinned ||
        locked < total ||
        telemetry.latchEngagementAngleDegrees < 85.0) {
      return IntermodalTwistlockAuditResult(
        vehicleId: vehicleId,
        status: IntermodalTwistlockStatus.manualPositionDiscrepancyWarning,
        lockedCount: locked,
        totalCount: total,
        lockAngleDegrees: telemetry.latchEngagementAngleDegrees,
        isSecondaryPinEngaged: telemetry.isSecondaryDetentLockPinned,
        transportSafetyAdvisory:
            'WARNING: Corner twistlocks engaged but secondary safety latch detent pins not secured ($locked/$total verified). Walk around chassis and insert safety flip pins prior to highway departure.',
      );
    }

    // 3. Normal nominal 4-corner lockup
    return IntermodalTwistlockAuditResult(
      vehicleId: vehicleId,
      status: IntermodalTwistlockStatus.twistlocksLockedAndGrounded,
      lockedCount: locked,
      totalCount: total,
      lockAngleDegrees: telemetry.latchEngagementAngleDegrees,
      isSecondaryPinEngaged: true,
      transportSafetyAdvisory:
          'NOMINAL: All 4 ISO container corner castings are locked 90° with secondary safety detent pins fully engaged.',
    );
  }
}
