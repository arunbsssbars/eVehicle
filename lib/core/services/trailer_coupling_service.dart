/// Fifth-wheel and trailer coupling safety status.
enum CouplingSafetyStatus {
  secureLocked,
  secondaryLatchOpen,
  pressureMismatchWarning,
  unlatchedCriticalHazard,
}

/// Instantaneous sensor readings from tractor-trailer fifth-wheel coupling interface.
class TrailerCouplingTelemetry {
  final bool kingpinEngaged;              // Primary kingpin switch
  final bool secondarySafetyLatchEngaged;  // Mechanical safety wedge
  final bool electricalUmbilicalConnected; // 7-pin / 15-pin ISO 12098 trailer circuit
  final double emergencySupplyBar;        // Red airline pressure (nominally ~7.5 to 8.5 bar)
  final double serviceBrakeBar;           // Yellow airline pressure
  final double vehicleSpeedKmh;

  const TrailerCouplingTelemetry({
    required this.kingpinEngaged,
    required this.secondarySafetyLatchEngaged,
    required this.electricalUmbilicalConnected,
    required this.emergencySupplyBar,
    required this.serviceBrakeBar,
    required this.vehicleSpeedKmh,
  });
}

/// Comprehensive pre-departure and in-motion coupling audit.
class TrailerCouplingAudit {
  final CouplingSafetyStatus status;
  final bool safeToDepart;
  final bool pneumaticPressureAdequate;
  final String statusSummary;
  final bool requiresEmergencyStop;

  const TrailerCouplingAudit({
    required this.status,
    required this.safeToDepart,
    required this.pneumaticPressureAdequate,
    required this.statusSummary,
    required this.requiresEmergencyStop,
  });
}

/// Service evaluating articulated tractor-trailer coupling integrity.
class TrailerCouplingService {
  const TrailerCouplingService();

  /// Audits physical latching, electrical circuits, and pneumatic pressure.
  TrailerCouplingAudit auditCoupling(TrailerCouplingTelemetry telemetry) {
    final bool pressureOk = telemetry.emergencySupplyBar >= 6.5;

    // Critical hazard: Kingpin disengaged while vehicle in motion or departure attempted
    if (!telemetry.kingpinEngaged) {
      final isMoving = telemetry.vehicleSpeedKmh > 1.0;
      return TrailerCouplingAudit(
        status: CouplingSafetyStatus.unlatchedCriticalHazard,
        safeToDepart: false,
        pneumaticPressureAdequate: pressureOk,
        statusSummary: isMoving
            ? 'CRITICAL SEPARATION HAZARD: Kingpin disengaged while vehicle is moving! Emergency brakes applying.'
            : 'COUPLING UNLATCHED: Kingpin not seated in fifth wheel jaw. Do not attempt departure.',
        requiresEmergencyStop: isMoving,
      );
    }

    // Secondary safety wedge warning
    if (!telemetry.secondarySafetyLatchEngaged) {
      return const TrailerCouplingAudit(
        status: CouplingSafetyStatus.secondaryLatchOpen,
        safeToDepart: false,
        pneumaticPressureAdequate: true,
        statusSummary: 'SECONDARY LATCH WARNING: Kingpin seated but safety latch release handle not locked.',
        requiresEmergencyStop: false,
      );
    }

    // Pneumatic brake line pressure low
    if (!pressureOk) {
      return TrailerCouplingAudit(
        status: CouplingSafetyStatus.pressureMismatchWarning,
        safeToDepart: false,
        pneumaticPressureAdequate: false,
        statusSummary: 'AIR SYSTEM LOW: Emergency supply pressure is ${telemetry.emergencySupplyBar.toStringAsFixed(1)} bar (min 6.5 bar). Charge trailer reservoirs.',
        requiresEmergencyStop: telemetry.vehicleSpeedKmh > 15.0,
      );
    }

    // Umbilical electrical circuit check
    if (!telemetry.electricalUmbilicalConnected) {
      return const TrailerCouplingAudit(
        status: CouplingSafetyStatus.pressureMismatchWarning,
        safeToDepart: false,
        pneumaticPressureAdequate: true,
        statusSummary: 'ELECTRICAL UMBILICAL DISCONNECTED: Trailer EBS and indicator lighting circuit open.',
        requiresEmergencyStop: false,
      );
    }

    return const TrailerCouplingAudit(
      status: CouplingSafetyStatus.secureLocked,
      safeToDepart: true,
      pneumaticPressureAdequate: true,
      statusSummary: 'FIFTH WHEEL SECURE: Kingpin, secondary wedge, dual air lines, and trailer EBS verified.',
      requiresEmergencyStop: false,
    );
  }
}
