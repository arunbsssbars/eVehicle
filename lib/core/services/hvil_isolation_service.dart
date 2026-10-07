/// High-voltage interlock circuit status.
enum HvilCircuitStatus {
  closedSecure,
  highResistanceDegraded,
  openCircuitEmergencyShutdown,
}

/// EV high-voltage isolation health (ISO 6469-1 / UNECE R100 standard: >= 500 Ohms/Volt for DC systems).
enum HvIsolationStatus {
  normalHighIsolation,
  warningDegradation,
  criticalIsolationFaultLockout,
}

/// High-Voltage Interlock Loop & Chassis Isolation telemetry.
class HvilIsolationTelemetry {
  final double busVoltageVdc;                 // e.g. 400V or 800V architecture
  final double hvilLoopResistanceOhms;         // Nominal closed: < 5.0 Ohms
  final double posChassisIsolationResistanceKOhms; // Positive rail to chassis
  final double negChassisIsolationResistanceKOhms; // Negative rail to chassis
  final double pyrofuseResistanceOhms;        // Active pyrofuse squib integrity: ~2.0 Ohms
  final bool manualServiceDisconnectPlugged;  // MSD interlock switch

  const HvilIsolationTelemetry({
    required this.busVoltageVdc,
    required this.hvilLoopResistanceOhms,
    required this.posChassisIsolationResistanceKOhms,
    required this.negChassisIsolationResistanceKOhms,
    required this.pyrofuseResistanceOhms,
    required this.manualServiceDisconnectPlugged,
  });
}

/// Comprehensive HV safety diagnosis result.
class HvilIsolationAudit {
  final HvilCircuitStatus hvilStatus;
  final HvIsolationStatus isolationStatus;
  final double minimumIsolationOhmsPerVolt;
  final bool contactorsPermittedToClose;
  final bool activeHighVoltageHazard;
  final String safetyAdvisory;
  final String recommendedAction;

  const HvilIsolationAudit({
    required this.hvilStatus,
    required this.isolationStatus,
    required this.minimumIsolationOhmsPerVolt,
    required this.contactorsPermittedToClose,
    required this.activeHighVoltageHazard,
    required this.safetyAdvisory,
    required this.recommendedAction,
  });
}

/// Service monitoring high-voltage interlock loops (HVIL), pyrofuse squib continuity, and chassis isolation resistance.
class HvilIsolationService {
  const HvilIsolationService();

  // Regulatory safety thresholds (ISO 6469-1 & UNECE R100)
  static const double minMandatoryIsolationOhmsPerVolt = 500.0;
  static const double warningIsolationOhmsPerVolt = 1000.0;
  static const double maxHvilClosedResistanceOhms = 10.0;
  static const double maxHvilHighResistanceDegradedOhms = 50.0;

  HvilIsolationAudit evaluateHvSafety(HvilIsolationTelemetry telemetry) {
    // 1. Evaluate HVIL circuit loop
    HvilCircuitStatus hvilState;
    if (!telemetry.manualServiceDisconnectPlugged || telemetry.hvilLoopResistanceOhms > maxHvilHighResistanceDegradedOhms) {
      hvilState = HvilCircuitStatus.openCircuitEmergencyShutdown;
    } else if (telemetry.hvilLoopResistanceOhms > maxHvilClosedResistanceOhms) {
      hvilState = HvilCircuitStatus.highResistanceDegraded;
    } else {
      hvilState = HvilCircuitStatus.closedSecure;
    }

    // 2. Evaluate Chassis Isolation Resistance (Ohms per Volt)
    final double lowerRailIsolationKOhms = telemetry.posChassisIsolationResistanceKOhms < telemetry.negChassisIsolationResistanceKOhms
        ? telemetry.posChassisIsolationResistanceKOhms
        : telemetry.negChassisIsolationResistanceKOhms;

    final double actualIsolationTotalOhms = lowerRailIsolationKOhms * 1000.0;
    final double isolationOhmsPerVolt = telemetry.busVoltageVdc > 0.0
        ? actualIsolationTotalOhms / telemetry.busVoltageVdc
        : 10000.0;

    HvIsolationStatus isolationState;
    if (isolationOhmsPerVolt < minMandatoryIsolationOhmsPerVolt) {
      isolationState = HvIsolationStatus.criticalIsolationFaultLockout;
    } else if (isolationOhmsPerVolt < warningIsolationOhmsPerVolt) {
      isolationState = HvIsolationStatus.warningDegradation;
    } else {
      isolationState = HvIsolationStatus.normalHighIsolation;
    }

    // 3. Contactor interlock and hazard logic
    final bool isHvilSafe = hvilState == HvilCircuitStatus.closedSecure || hvilState == HvilCircuitStatus.highResistanceDegraded;
    final bool isIsolationSafe = isolationState != HvIsolationStatus.criticalIsolationFaultLockout;
    final bool pyrofuseHealthy = telemetry.pyrofuseResistanceOhms >= 1.5 && telemetry.pyrofuseResistanceOhms <= 3.5;

    final bool contactorsPermitted = isHvilSafe && isIsolationSafe && pyrofuseHealthy;
    final bool activeHazard = hvilState == HvilCircuitStatus.openCircuitEmergencyShutdown ||
        isolationState == HvIsolationStatus.criticalIsolationFaultLockout ||
        !pyrofuseHealthy;

    String advisory;
    String action;

    if (!telemetry.manualServiceDisconnectPlugged) {
      advisory = 'EMERGENCY DISCONNECT OPEN: Manual Service Disconnect (MSD) pulled. HV battery contactors physically inhibited.';
      action = 'Verify service plug seated and interlock lever latched before closing contactors.';
    } else if (isolationState == HvIsolationStatus.criticalIsolationFaultLockout) {
      advisory = 'CRITICAL CHASSIS LEAKAGE (${isolationOhmsPerVolt.toStringAsFixed(0)} Ω/V): Breach below ISO 6469-1 500 Ω/V threshold! Electrocution risk!';
      action = 'Lockout-Tagout (LOTO) active. HV main contactors locked open. Dispatch EV certified technician.';
    } else if (hvilState == HvilCircuitStatus.openCircuitEmergencyShutdown) {
      advisory = 'HVIL CIRCUIT BREAK: High-voltage loop open or severed. Potential exposed HV connector or cover breach.';
      action = 'De-energize inverter DC-link immediately. Inspect HV harness and connector microswitches.';
    } else if (!pyrofuseHealthy) {
      advisory = 'PYROFUSE SQUIB ANOMALY: Squib circuit open or degraded (${telemetry.pyrofuseResistanceOhms.toStringAsFixed(1)} Ω). Fast-blow pyro-switch unverified.';
      action = 'Replace pyro-switch actuator module prior to high-power DC fast charging.';
    } else if (isolationState == HvIsolationStatus.warningDegradation) {
      advisory = 'ISOLATION DEGRADATION WARNING: Moisture or coolant intrusion detected. Leakage at ${isolationOhmsPerVolt.toStringAsFixed(0)} Ω/V.';
      action = 'Inspect battery enclosure desiccants and coolant jacket integrity at next maintenance.';
    } else {
      advisory = 'HIGH VOLTAGE SECURE: HVIL closed (${telemetry.hvilLoopResistanceOhms.toStringAsFixed(1)} Ω), isolation robust (${isolationOhmsPerVolt.toStringAsFixed(0)} Ω/V).';
      action = 'Vehicle HV powertrain fully operational and contactors energized safely.';
    }

    return HvilIsolationAudit(
      hvilStatus: hvilState,
      isolationStatus: isolationState,
      minimumIsolationOhmsPerVolt: double.parse(isolationOhmsPerVolt.toStringAsFixed(1)),
      contactorsPermittedToClose: contactorsPermitted,
      activeHighVoltageHazard: activeHazard,
      safetyAdvisory: advisory,
      recommendedAction: action,
    );
  }
}
