/// Work-zone compliance status.
enum WorkZoneComplianceStatus {
  compliantNormal,
  cautionApproachingZone,
  speedExceededAdvisory,
  severeViolationEnforcementRisk,
}

/// Active highway / municipal construction work zone details.
class WorkZoneGeometry {
  final String zoneId;
  final String zoneName;
  final double variableSpeedLimitKmh; // Posted temporary work zone limit (e.g. 40 or 60 km/h)
  final double startPostKm;
  final double endPostKm;
  final bool workersPresentOnRoadway;
  final bool automatedSpeedCameraActive;

  const WorkZoneGeometry({
    required this.zoneId,
    required this.zoneName,
    required this.variableSpeedLimitKmh,
    required this.startPostKm,
    required this.endPostKm,
    required this.workersPresentOnRoadway,
    required this.automatedSpeedCameraActive,
  });
}

/// Telemetry input for fleet vehicle inside or near work zones.
class VehicleWorkZoneTelemetry {
  final double currentVehicleSpeedKmh;
  final double currentMilepostKm;
  final bool approachingWarningBeaconDetected;
  final double distanceToZoneEntryMeters;

  const VehicleWorkZoneTelemetry({
    required this.currentVehicleSpeedKmh,
    required this.currentMilepostKm,
    required this.approachingWarningBeaconDetected,
    required this.distanceToZoneEntryMeters,
  });
}

/// Compliance assessment output.
class WorkZoneComplianceAudit {
  final WorkZoneComplianceStatus status;
  final double speedDeltaKmh; // (currentSpeed - speedLimit)
  final bool isInsideZone;
  final double doubleFineMultiplier; // 2x or 3x fine when workers present
  final String driverAlertNotice;
  final String actionRequired;

  const WorkZoneComplianceAudit({
    required this.status,
    required this.speedDeltaKmh,
    required this.isInsideZone,
    required this.doubleFineMultiplier,
    required this.driverAlertNotice,
    required this.actionRequired,
  });
}

/// Service auditing vehicle speed against dynamic variable work zones, beacon warnings, and worker safety zones.
class WorkZoneComplianceService {
  const WorkZoneComplianceService();

  WorkZoneComplianceAudit assessCompliance({
    required WorkZoneGeometry zone,
    required VehicleWorkZoneTelemetry telemetry,
  }) {
    final bool isInside = telemetry.currentMilepostKm >= zone.startPostKm &&
        telemetry.currentMilepostKm <= zone.endPostKm;

    final double speedDelta = telemetry.currentVehicleSpeedKmh - zone.variableSpeedLimitKmh;
    final double fineMultiplier = zone.workersPresentOnRoadway ? 2.0 : 1.0;

    WorkZoneComplianceStatus status;
    String alert;
    String action;

    if (isInside) {
      if (speedDelta > 15.0) {
        status = WorkZoneComplianceStatus.severeViolationEnforcementRisk;
        alert = 'SEVERE WORK ZONE OVERSPEED: Travelling ${telemetry.currentVehicleSpeedKmh.toStringAsFixed(0)} km/h in ${zone.variableSpeedLimitKmh.toStringAsFixed(0)} km/h zone (${speedDelta.toStringAsFixed(0)} km/h over)!';
        action = zone.automatedSpeedCameraActive
            ? 'Brake immediately. Automated work-zone speed cameras active (Double fine ${fineMultiplier.toStringAsFixed(0)}x)!'
            : 'Reduce speed immediately to protect construction workers on roadway.';
      } else if (speedDelta > 2.0) {
        status = WorkZoneComplianceStatus.speedExceededAdvisory;
        alert = 'SPEED LIMIT EXCEEDED: ${telemetry.currentVehicleSpeedKmh.toStringAsFixed(0)} km/h in active work zone.';
        action = 'Disengage cruise control and decelerate to ${zone.variableSpeedLimitKmh.toStringAsFixed(0)} km/h.';
      } else {
        status = WorkZoneComplianceStatus.compliantNormal;
        alert = 'WORK ZONE COMPLIANT: Speed ${telemetry.currentVehicleSpeedKmh.toStringAsFixed(0)} km/h within safe ${zone.variableSpeedLimitKmh.toStringAsFixed(0)} km/h limit.';
        action = 'Maintain cautious distance and watch for construction ingress/egress.';
      }
    } else {
      // Approaching
      if (telemetry.approachingWarningBeaconDetected || telemetry.distanceToZoneEntryMeters < 500.0) {
        status = WorkZoneComplianceStatus.cautionApproachingZone;
        alert = 'APPROACHING WORK ZONE: ${zone.zoneName} ahead (${telemetry.distanceToZoneEntryMeters.toStringAsFixed(0)}m). Limit: ${zone.variableSpeedLimitKmh.toStringAsFixed(0)} km/h.';
        action = 'Begin progressive deceleration ahead of work zone taper.';
      } else {
        status = WorkZoneComplianceStatus.compliantNormal;
        alert = 'OPEN HIGHWAY: No active work zone restrictions.';
        action = 'Observe standard highway speed limit.';
      }
    }

    return WorkZoneComplianceAudit(
      status: status,
      speedDeltaKmh: double.parse(speedDelta.toStringAsFixed(1)),
      isInsideZone: isInside,
      doubleFineMultiplier: fineMultiplier,
      driverAlertNotice: alert,
      actionRequired: action,
    );
  }
}
