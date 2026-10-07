/// EV High-Voltage Isolation State.
enum HvIsolationStatus {
  normalHighResistance,
  degradedEarlyWarning,
  criticalIsolationFaultChassisLeak,
}

/// Dynamic isolation sensor telemetry from the on-board BMS / IMD.
class HvIsolationTelemetry {
  final double positiveRailToChassisKohm; // Positive pole isolation resistance (R+)
  final double negativeRailToChassisKohm; // Negative pole isolation resistance (R-)
  final double tractionPackVoltageVolts; // Typically 400V or 800V
  final double inverterAcLeakageMilliamps;
  final bool isContactorWelded;

  const HvIsolationTelemetry({
    required this.positiveRailToChassisKohm,
    required this.negativeRailToChassisKohm,
    required this.tractionPackVoltageVolts,
    required this.inverterAcLeakageMilliamps,
    this.isContactorWelded = false,
  });

  /// The minimum isolation resistance between either rail and vehicle ground.
  double get minIsolationResistanceKohm =>
      positiveRailToChassisKohm < negativeRailToChassisKohm
          ? positiveRailToChassisKohm
          : negativeRailToChassisKohm;

  /// Isolation resistance normalized per volt of battery potential (Ohm/Volt standard, min 500 Ohm/V).
  double get isolationOhmsPerVolt => (minIsolationResistanceKohm * 1000.0) / tractionPackVoltageVolts;
}

/// Comprehensive high-voltage chassis isolation audit result.
class HvIsolationAuditResult {
  final String vehicleId;
  final HvIsolationStatus status;
  final double minIsolationKohm;
  final double isolationOhmsPerVolt;
  final double leakageMilliamps;
  final bool isContactorWelded;
  final String safetyInterlockAction;

  const HvIsolationAuditResult({
    required this.vehicleId,
    required this.status,
    required this.minIsolationKohm,
    required this.isolationOhmsPerVolt,
    required this.leakageMilliamps,
    required this.isContactorWelded,
    required this.safetyInterlockAction,
  });

  bool get isSafeToOperate => status == HvIsolationStatus.normalHighResistance;
  bool get isHighVoltageInterlockTripped => status == HvIsolationStatus.criticalIsolationFaultChassisLeak;
}

/// Service that evaluates EV traction bus dielectric resistance and chassis ground leakage.
class HvIsolationMonitorService {
  const HvIsolationMonitorService();

  HvIsolationAuditResult auditHvIsolation({
    required String vehicleId,
    required HvIsolationTelemetry telemetry,
  }) {
    final ohmsPerVolt = telemetry.isolationOhmsPerVolt;
    final minKohm = telemetry.minIsolationResistanceKohm;

    // Critical: < 100 Ohms/Volt (ISO 6469-1 / UNECE R100 standard) or contactor welded
    if (ohmsPerVolt < 100.0 || minKohm < 50.0 || telemetry.isContactorWelded || telemetry.inverterAcLeakageMilliamps > 10.0) {
      return HvIsolationAuditResult(
        vehicleId: vehicleId,
        status: HvIsolationStatus.criticalIsolationFaultChassisLeak,
        minIsolationKohm: minKohm,
        isolationOhmsPerVolt: ohmsPerVolt,
        leakageMilliamps: telemetry.inverterAcLeakageMilliamps,
        isContactorWelded: telemetry.isContactorWelded,
        safetyInterlockAction:
            'CRITICAL HAZARD: HV Chassis isolation breakdown (<100 Ω/V) or contactor welded. Open pyrofuse / HVIL interlock immediately.',
      );
    }

    // Degraded: < 500 Ohms/Volt (warning zone)
    if (ohmsPerVolt < 500.0 || minKohm < 200.0 || telemetry.inverterAcLeakageMilliamps > 3.5) {
      return HvIsolationAuditResult(
        vehicleId: vehicleId,
        status: HvIsolationStatus.degradedEarlyWarning,
        minIsolationKohm: minKohm,
        isolationOhmsPerVolt: ohmsPerVolt,
        leakageMilliamps: telemetry.inverterAcLeakageMilliamps,
        isContactorWelded: false,
        safetyInterlockAction:
            'WARNING: Moisture ingress or cable sheath aging causing low isolation resistance (<500 Ω/V). Inspect junction boxes.',
      );
    }

    return HvIsolationAuditResult(
      vehicleId: vehicleId,
      status: HvIsolationStatus.normalHighResistance,
      minIsolationKohm: minKohm,
      isolationOhmsPerVolt: ohmsPerVolt,
      leakageMilliamps: telemetry.inverterAcLeakageMilliamps,
      isContactorWelded: false,
      safetyInterlockAction:
          'NOMINAL: High-voltage bus isolation exceeds UNECE R100 safety requirements (>500 Ω/V).',
    );
  }
}
