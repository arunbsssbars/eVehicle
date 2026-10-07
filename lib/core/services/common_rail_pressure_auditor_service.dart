/// Fuel rail high-pressure delivery and rail relief valve (PRV) seal condition.
enum CommonRailPressureStatus {
  railPressureNominal,
  highPressurePumpWearWarning,
  criticalPrvLimpOrRailBlowoutRisk,
}

/// Dynamic micro-second telemetry from piezoresistive common-rail pressure sensor and metering valve.
class CommonRailPressureTelemetry {
  final double measuredRailPressureBar; // Normal idle: 350 - 500 bar. Full throttle: 1800 - 2500 bar.
  final double targetRailPressureBar;
  final double railPressureReliefValvePopCount; // PRV should pop 0 times. > 1 pop = valve seat erosion/leaking.
  final double fuelMeteringUnitCurrentMilliamps; // IMV/MPROP valve current duty cycle.
  final double railPressureOscillationBar; // Normal rail ripple: < 30 bar. Surge > 80 bar indicates pump cam wear.
  final double fuelRailTemperatureCelsius;

  const CommonRailPressureTelemetry({
    required this.measuredRailPressureBar,
    required this.targetRailPressureBar,
    required this.railPressureReliefValvePopCount,
    required this.fuelMeteringUnitCurrentMilliamps,
    required this.railPressureOscillationBar,
    required this.fuelRailTemperatureCelsius,
  });

  /// Rail pressure deviation delta from ECU setpoint.
  double get railPressureDeltaBar => (measuredRailPressureBar - targetRailPressureBar).abs();
}

/// Audit result for common rail fuel injection pressure, pump delivery, and relief valve integrity.
class CommonRailPressureAuditResult {
  final String vehicleId;
  final CommonRailPressureStatus status;
  final double actualBar;
  final double targetBar;
  final double deltaBar;
  final double prvPops;
  final double oscillationBar;
  final String diagnosticAdvisory;

  const CommonRailPressureAuditResult({
    required this.vehicleId,
    required this.status,
    required this.actualBar,
    required this.targetBar,
    required this.deltaBar,
    required this.prvPops,
    required this.oscillationBar,
    required this.diagnosticAdvisory,
  });

  bool get isRailPressureStable => status == CommonRailPressureStatus.railPressureNominal;
  bool get isCriticalRailFailure =>
      status == CommonRailPressureStatus.criticalPrvLimpOrRailBlowoutRisk;
}

/// Service that diagnoses common-rail pressure tracking error, detects high-pressure pump piston scoring, and prevents pressure relief valve blowout.
class CommonRailPressureAuditorService {
  const CommonRailPressureAuditorService();

  CommonRailPressureAuditResult auditFuelRail({
    required String vehicleId,
    required CommonRailPressureTelemetry telemetry,
  }) {
    final delta = telemetry.railPressureDeltaBar;

    // 1. Critical: Pressure delta > 250 bar under load, PRV popped > 0 times, or pressure over 2650 bar
    if (delta >= 250.0 ||
        telemetry.railPressureReliefValvePopCount >= 1.0 ||
        telemetry.measuredRailPressureBar >= 2650.0 ||
        telemetry.railPressureOscillationBar >= 100.0) {
      return CommonRailPressureAuditResult(
        vehicleId: vehicleId,
        status: CommonRailPressureStatus.criticalPrvLimpOrRailBlowoutRisk,
        actualBar: telemetry.measuredRailPressureBar,
        targetBar: telemetry.targetRailPressureBar,
        deltaBar: delta,
        prvPops: telemetry.railPressureReliefValvePopCount,
        oscillationBar: telemetry.railPressureOscillationBar,
        diagnosticAdvisory:
            'CRITICAL HAZARD: Common-rail pressure divergence (${delta.toStringAsFixed(0)} bar error) or PRV relief pop detected! High-pressure fuel atomization failure will cause injector needle seizure or manifold split.',
      );
    }

    // 2. Warning: Rail pressure tracking delta > 120 bar or oscillation > 50 bar
    if (delta >= 120.0 ||
        telemetry.railPressureOscillationBar >= 50.0 ||
        telemetry.fuelRailTemperatureCelsius >= 95.0) {
      return CommonRailPressureAuditResult(
        vehicleId: vehicleId,
        status: CommonRailPressureStatus.highPressurePumpWearWarning,
        actualBar: telemetry.measuredRailPressureBar,
        targetBar: telemetry.targetRailPressureBar,
        deltaBar: delta,
        prvPops: telemetry.railPressureReliefValvePopCount,
        oscillationBar: telemetry.railPressureOscillationBar,
        diagnosticAdvisory:
            'WARNING: Fuel rail pressure ripple elevated (Oscillation: ${telemetry.railPressureOscillationBar.toStringAsFixed(0)} bar). Inspect high-pressure fuel pump (HPFP) inlet metering valve and check for plunger wear.',
      );
    }

    // 3. Normal nominal common rail pressure
    return CommonRailPressureAuditResult(
      vehicleId: vehicleId,
      status: CommonRailPressureStatus.railPressureNominal,
      actualBar: telemetry.measuredRailPressureBar,
      targetBar: telemetry.targetRailPressureBar,
      deltaBar: delta,
      prvPops: telemetry.railPressureReliefValvePopCount,
      oscillationBar: telemetry.railPressureOscillationBar,
      diagnosticAdvisory:
          'NOMINAL: Common rail fuel pressure tracks engine ECU demand precisely with stable hydraulic ripple attenuation.',
    );
  }
}
