/// Operational condition of pneumatic auxiliary axle automated drop control logic.
enum AutoDropAuxiliaryAxleStatus {
  logicArmedNominal,
  speedInterlockOverrideWarning,
  criticalReverseGearTireScrubShearHazard,
}

/// Dynamic transmission gear, road speed, reverse switch, and axle weight telemetry governing helper axle deployment.
class AutoDropAuxiliaryAxleTelemetry {
  final bool isAuxiliaryAxleLoweredToPavement; // True = wheels rolling on pavement, False = retracted up.
  final bool isReverseGearEngaged; // Reverse direction.
  final double vehicleRoadSpeedKmh;
  final double driveAxlePayloadTonnes; // Legal threshold: > 9.5 tonnes mandates auto-drop.
  final double legalAutoDropThresholdTonnes;
  final bool isManualDashLiftSwitchHeld; // Driver overriding system by holding override toggle.
  final double steerAngleDegrees; // Tight backing maneuver > 18° scrubs tires if non-steerable tag is down.

  const AutoDropAuxiliaryAxleTelemetry({
    required this.isAuxiliaryAxleLoweredToPavement,
    required this.isReverseGearEngaged,
    required this.vehicleRoadSpeedKmh,
    required this.driveAxlePayloadTonnes,
    this.legalAutoDropThresholdTonnes = 9.5,
    required this.isManualDashLiftSwitchHeld,
    required this.steerAngleDegrees,
  });

  /// Mandates automated axle drop to comply with bridge weight laws.
  bool get isAutoDropLegallyMandated =>
      driveAxlePayloadTonnes >= legalAutoDropThresholdTonnes && vehicleRoadSpeedKmh > 8.0;

  /// High scrub risk: Backing in reverse with non-steer auxiliary axle pinned down.
  bool get isReverseScrubDamageRisk =>
      isReverseGearEngaged && isAuxiliaryAxleLoweredToPavement && steerAngleDegrees.abs() > 10.0;
}

/// Audit result for automated lift axle deployment logic, reverse auto-lift interlocks, and tire scrub protection.
class AutoDropAuxiliaryAxleAuditResult {
  final String vehicleId;
  final AutoDropAuxiliaryAxleStatus status;
  final bool isAxleDown;
  final bool shouldAutoDropBeEnacted;
  final bool shouldAutoLiftInReverseBeEnacted;
  final double driveLoadTonnes;
  final String interlockAdvisory;

  const AutoDropAuxiliaryAxleAuditResult({
    required this.vehicleId,
    required this.status,
    required this.isAxleDown,
    required this.shouldAutoDropBeEnacted,
    required this.shouldAutoLiftInReverseBeEnacted,
    required this.driveLoadTonnes,
    required this.interlockAdvisory,
  });

  bool get isInterlockSafe => status == AutoDropAuxiliaryAxleStatus.logicArmedNominal;
  bool get isReverseScrubDanger =>
      status == AutoDropAuxiliaryAxleStatus.criticalReverseGearTireScrubShearHazard;
}

/// Evaluates speed/weight auxiliary axle automated drop, reverse gear auto-lift interlock, and driver manual override tampering.
class AutoDropAuxiliaryAxleService {
  const AutoDropAuxiliaryAxleService();

  AutoDropAuxiliaryAxleAuditResult auditAutoDropLogic({
    required String vehicleId,
    required AutoDropAuxiliaryAxleTelemetry telemetry,
  }) {
    final reverseScrub = telemetry.isReverseScrubDamageRisk;
    final autoDropNeeded = telemetry.isAutoDropLegallyMandated;

    // 1. Critical: Reversing with auxiliary axle down during sharp turn -> Rim bending & tire bead de-seating
    if (reverseScrub) {
      return AutoDropAuxiliaryAxleAuditResult(
        vehicleId: vehicleId,
        status: AutoDropAuxiliaryAxleStatus.criticalReverseGearTireScrubShearHazard,
        isAxleDown: telemetry.isAuxiliaryAxleLoweredToPavement,
        shouldAutoDropBeEnacted: false,
        shouldAutoLiftInReverseBeEnacted: true,
        driveLoadTonnes: telemetry.driveAxlePayloadTonnes,
        interlockAdvisory:
            'CRITICAL TIRE SCRUB HAZARD: Non-steer auxiliary axle is deployed on ground while reversing into turn (${telemetry.steerAngleDegrees.toStringAsFixed(1)}° steer angle)! Immediate auto-lift commanded to prevent tire rim peeling and spindle snap.',
      );
    }

    // 2. Warning: Driver manual switch override holding axle up while overloaded, or speed > 10 km/h with load
    if (autoDropNeeded && !telemetry.isAuxiliaryAxleLoweredToPavement) {
      return AutoDropAuxiliaryAxleAuditResult(
        vehicleId: vehicleId,
        status: AutoDropAuxiliaryAxleStatus.speedInterlockOverrideWarning,
        isAxleDown: false,
        shouldAutoDropBeEnacted: true,
        shouldAutoLiftInReverseBeEnacted: false,
        driveLoadTonnes: telemetry.driveAxlePayloadTonnes,
        interlockAdvisory: telemetry.isManualDashLiftSwitchHeld
            ? 'WARNING: Driver holding manual lift override switch above legal speed limit (${telemetry.vehicleRoadSpeedKmh.toStringAsFixed(0)} km/h). Auto-drop safety valve will override switch in 5 seconds.'
            : 'WARNING: Drive axle payload (${telemetry.drivePayloadTonnesFormatted} T) exceeds legal single-axle threshold. Deploying auxiliary axle automatically.',
      );
    }

    // 3. Normal armed logic operation
    return AutoDropAuxiliaryAxleAuditResult(
      vehicleId: vehicleId,
      status: AutoDropAuxiliaryAxleStatus.logicArmedNominal,
      isAxleDown: telemetry.isAuxiliaryAxleLoweredToPavement,
      shouldAutoDropBeEnacted: false,
      shouldAutoLiftInReverseBeEnacted: false,
      driveLoadTonnes: telemetry.driveAxlePayloadTonnes,
      interlockAdvisory:
          'NOMINAL: Automated auxiliary axle controller armed. Weight-sensing proportional valve and reverse auto-lift active.',
    );
  }
}

extension on AutoDropAuxiliaryAxleTelemetry {
  String get drivePayloadTonnesFormatted => driveAxlePayloadTonnes.toStringAsFixed(1);
}
