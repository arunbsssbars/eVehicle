/// Status of continuous CAN bus message transmission integrity and node health.
enum CanBusHealthStatus {
  busNominalZeroErrorFrames,
  warningFrameDropJitterThreshold,
  criticalBusOffDominantLockout,
}

/// Real-time micro-controller CAN transceiver telemetry measuring bus load, bit errors, and voltage differential.
class CanBusDiagnosticTelemetry {
  final double busUtilizationPercent; // Healthy: < 45%. Saturated / frame collision: > 75%.
  final int transmitErrorCounter; // TEC: Normal < 96. Error passive > 127. Bus-off >= 256.
  final int receiveErrorCounter; // REC: Normal < 96. Error passive > 127.
  final int errorFramesPerSecond; // Nominal = 0. Jitter/chaff > 15/s.
  final double canHighVoltageVolts; // Dominant: ~3.5V, Recessive: ~2.5V.
  final double canLowVoltageVolts; // Dominant: ~1.5V, Recessive: ~2.5V.
  final double busDifferentialVoltageVolts; // Vdiff = CAN_H - CAN_L. Dominant: ~2.0V, Recessive: ~0.0V.

  const CanBusDiagnosticTelemetry({
    required this.busUtilizationPercent,
    required this.transmitErrorCounter,
    required this.receiveErrorCounter,
    required this.errorFramesPerSecond,
    required this.canHighVoltageVolts,
    required this.canLowVoltageVolts,
    required this.busDifferentialVoltageVolts,
  });

  /// True if CAN transceiver controller has entered the autonomous Bus-Off shutdown state.
  bool get isBusOffHardwareHalted => transmitErrorCounter >= 256;

  /// True if CAN high/low physical harness is shorted together or pulled to chassis ground.
  bool get isPhysicalBusShortCircuit =>
      (canHighVoltageVolts - canLowVoltageVolts).abs() < 0.2 && busDifferentialVoltageVolts < 0.3;
}

/// Evaluation result for vehicular network physical layer and J1939/CAN-FD protocol stability.
class CanBusDiagnosticAuditResult {
  final String networkSegment; // e.g. "Powertrain CAN (J1939 - 500k)"
  final CanBusHealthStatus status;
  final double busLoadPercent;
  final int tec;
  final int rec;
  final int errorFramesPerSec;
  final double diffVolts;
  final String networkAdvisory;

  const CanBusDiagnosticAuditResult({
    required this.networkSegment,
    required this.status,
    required this.busLoadPercent,
    required this.tec,
    required this.rec,
    required this.errorFramesPerSec,
    required this.diffVolts,
    required this.networkAdvisory,
  });

  bool get isBusHealthy => status == CanBusHealthStatus.busNominalZeroErrorFrames;
  bool get isNetworkDisabled => status == CanBusHealthStatus.criticalBusOffDominantLockout;
}

/// Service that diagnoses vehicular multiplex network topology, detects physical wiring harness chafing, and prevents ECU Bus-Off lockouts.
class CanBusHealthDiagnosticService {
  const CanBusHealthDiagnosticService();

  CanBusDiagnosticAuditResult auditNetwork({
    required String networkSegment,
    required CanBusDiagnosticTelemetry telemetry,
  }) {
    // 1. Critical: Bus-Off state (TEC >= 256), continuous error frames > 40/s, or shorted harness
    if (telemetry.isBusOffHardwareHalted ||
        telemetry.errorFramesPerSecond >= 40 ||
        telemetry.isPhysicalBusShortCircuit) {
      return CanBusDiagnosticAuditResult(
        networkSegment: networkSegment,
        status: CanBusHealthStatus.criticalBusOffDominantLockout,
        busLoadPercent: telemetry.busUtilizationPercent,
        tec: telemetry.transmitErrorCounter,
        rec: telemetry.receiveErrorCounter,
        errorFramesPerSec: telemetry.errorFramesPerSecond,
        diffVolts: telemetry.busDifferentialVoltageVolts,
        networkAdvisory:
            'CRITICAL NETWORK FAILURE: CAN controller entered BUS-OFF hardware disconnect or harness short detected! Inter-ECU communication dropped. Powertrain and brake communications isolated.',
      );
    }

    // 2. Warning: Bus utilization > 70%, TEC/REC > 96, or packet errors occurring
    if (telemetry.busUtilizationPercent >= 70.0 ||
        telemetry.transmitErrorCounter >= 96 ||
        telemetry.receiveErrorCounter >= 96 ||
        telemetry.errorFramesPerSecond >= 8) {
      return CanBusDiagnosticAuditResult(
        networkSegment: networkSegment,
        status: CanBusHealthStatus.warningFrameDropJitterThreshold,
        busLoadPercent: telemetry.busUtilizationPercent,
        tec: telemetry.transmitErrorCounter,
        rec: telemetry.receiveErrorCounter,
        errorFramesPerSec: telemetry.errorFramesPerSecond,
        diffVolts: telemetry.busDifferentialVoltageVolts,
        networkAdvisory:
            'WARNING: Heavy CAN bus loading (${telemetry.busUtilizationPercent.toStringAsFixed(0)}% load) and error frame jitter detected (TEC: ${telemetry.transmitErrorCounter}). Check terminating resistors (120Ω) and grounding.',
      );
    }

    // 3. Normal nominal multiplex bus transmission
    return CanBusDiagnosticAuditResult(
      networkSegment: networkSegment,
      status: CanBusHealthStatus.busNominalZeroErrorFrames,
      busLoadPercent: telemetry.busUtilizationPercent,
      tec: telemetry.transmitErrorCounter,
      rec: telemetry.receiveErrorCounter,
      errorFramesPerSec: telemetry.errorFramesPerSecond,
      diffVolts: telemetry.busDifferentialVoltageVolts,
      networkAdvisory:
          'NOMINAL: CAN-FD and J1939 network transceiver telemetry is optimal. Zero frame retries or differential voltage skew.',
    );
  }
}
