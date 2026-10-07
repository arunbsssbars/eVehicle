/// High-voltage battery pack bidirectional contactor weld and pre-charge resistor status.
enum BatteryContactorWeldStatus {
  contactorsNominalCycleSound,
  preChargeThermalStressWarning,
  criticalMainContactorWeldHazard,
}

/// Dynamic micro-second telemetry from battery pack high-voltage main positive (+), main negative (-), and pre-charge contactors.
class BatteryContactorWeldTelemetry {
  final bool isMainPositiveAuxiliaryFeedbackOpen; // True = relay physically open. False = closed.
  final bool isMainNegativeAuxiliaryFeedbackOpen;
  final bool isContactorCommandedClosed; // ECU coil command (True = energize coil, False = de-energize to disconnect).
  final double packVoltageVolts; // Battery side voltage (e.g. 780V)
  final double inverterLinkVoltageVolts; // Inverter link side voltage (Should decay to 0V when contactors open)
  final double preChargeResistorTemperatureCelsius; // Normal < 60°C. Inrush stress > 110°C.
  final double coilPullInCurrentAmperes; // Normal coil current: 0.8 - 1.5 A.

  const BatteryContactorWeldTelemetry({
    required this.isMainPositiveAuxiliaryFeedbackOpen,
    required this.isMainNegativeAuxiliaryFeedbackOpen,
    required this.isContactorCommandedClosed,
    required this.packVoltageVolts,
    required this.inverterLinkVoltageVolts,
    required this.preChargeResistorTemperatureCelsius,
    required this.coilPullInCurrentAmperes,
  });

  /// True if bus voltage remains high after contactors commanded open, indicating silver contact fusion/welding.
  bool get isPositiveContactorWelded =>
      !isContactorCommandedClosed &&
      !isMainPositiveAuxiliaryFeedbackOpen &&
      inverterLinkVoltageVolts > 50.0;

  bool get isNegativeContactorWelded =>
      !isContactorCommandedClosed && !isMainNegativeAuxiliaryFeedbackOpen;
}

/// Evaluation result for high-voltage contactor contact erosion, silver welding, and pre-charge protection.
class BatteryContactorWeldAuditResult {
  final String vehicleId;
  final BatteryContactorWeldStatus status;
  final bool isPositiveWelded;
  final bool isNegativeWelded;
  final double linkVoltageVolts;
  final double preChargeTempCelsius;
  final String safetyAdvisory;

  const BatteryContactorWeldAuditResult({
    required this.vehicleId,
    required this.status,
    required this.isPositiveWelded,
    required this.isNegativeWelded,
    required this.linkVoltageVolts,
    required this.preChargeTempCelsius,
    required this.safetyAdvisory,
  });

  bool get isIsolationSound => status == BatteryContactorWeldStatus.contactorsNominalCycleSound;
  bool get isWeldedCriticalFault =>
      status == BatteryContactorWeldStatus.criticalMainContactorWeldHazard;
}

/// Evaluates high-voltage battery main contactor micro-weld detection, arc pitting, and pre-charge resistor thermal protection.
class BatteryContactorWeldAuditorService {
  const BatteryContactorWeldAuditorService();

  BatteryContactorWeldAuditResult auditContactors({
    required String vehicleId,
    required BatteryContactorWeldTelemetry telemetry,
  }) {
    final posWelded = telemetry.isPositiveContactorWelded;
    final negWelded = telemetry.isNegativeContactorWelded;

    // 1. Critical: Contactor welded shut when commanded open -> Live lethal HV remaining on external inverter bus
    if (posWelded || negWelded || (!telemetry.isContactorCommandedClosed && telemetry.inverterLinkVoltageVolts > 60.0)) {
      return BatteryContactorWeldAuditResult(
        vehicleId: vehicleId,
        status: BatteryContactorWeldStatus.criticalMainContactorWeldHazard,
        isPositiveWelded: posWelded,
        isNegativeWelded: negWelded,
        linkVoltageVolts: telemetry.inverterLinkVoltageVolts,
        preChargeTempCelsius: telemetry.preChargeResistorTemperatureCelsius,
        safetyAdvisory:
            'CRITICAL SAFETY FAULT: High-voltage main contactor silver contact weld detected (Link bus live at ${telemetry.inverterLinkVoltageVolts.toStringAsFixed(0)}V)! Inverter isolated fail-safe commanded; service pack only with class-0 insulated safety gear.',
      );
    }

    // 2. Warning: Pre-charge resistor overheating > 95°C or high cycle resistance
    if (telemetry.preChargeResistorTemperatureCelsius >= 95.0 ||
        telemetry.coilPullInCurrentAmperes > 2.2 ||
        telemetry.coilPullInCurrentAmperes < 0.5) {
      return BatteryContactorWeldAuditResult(
        vehicleId: vehicleId,
        status: BatteryContactorWeldStatus.preChargeThermalStressWarning,
        isPositiveWelded: false,
        isNegativeWelded: false,
        linkVoltageVolts: telemetry.inverterLinkVoltageVolts,
        preChargeTempCelsius: telemetry.preChargeResistorTemperatureCelsius,
        safetyAdvisory:
            'WARNING: Pre-charge circuit thermal stress detected (${telemetry.preChargeResistorTemperatureCelsius.toStringAsFixed(1)}°C). Inrush current surge suggests inverter DC-link capacitance pre-charge timing lag.',
      );
    }

    // 3. Normal nominal contactor operation
    return BatteryContactorWeldAuditResult(
      vehicleId: vehicleId,
      status: BatteryContactorWeldStatus.contactorsNominalCycleSound,
      isPositiveWelded: false,
      isNegativeWelded: false,
      linkVoltageVolts: telemetry.inverterLinkVoltageVolts,
      preChargeTempCelsius: telemetry.preChargeResistorTemperatureCelsius,
      safetyAdvisory:
          'NOMINAL: Battery pack high-voltage main contactors open and close cleanly with zero contact welding or arc erosion.',
    );
  }
}
