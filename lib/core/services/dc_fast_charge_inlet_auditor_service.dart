/// High-voltage direct current (DC) fast-charging coupler communication, pin heating, and isolation latch status.
enum DcFastChargeInletStatus {
  chargingProtocolNominal,
  thermalDeratingPinWarning,
  criticalThermalRunawayArcHazard,
}

/// Dynamic telemetry measuring CCS Combo 2 / NACS DC pin temperatures, contact resistance, and latch locking solenoid.
class DcFastChargeInletTelemetry {
  final double dcPositivePinTemperatureCelsius; // Normal: 40 - 75°C. Warning: > 90°C. Critical: >= 110°C.
  final double dcNegativePinTemperatureCelsius;
  final double chargingCurrentAmperes; // Heavy fast charge: 250 - 500 A.
  final double inletContactResistanceMicroOhms; // Normal < 15 µΩ. Oxidation/wear > 45 µΩ.
  final bool isElectronicLockSolenoidEngaged; // High-voltage interlock latch (Must be locked when current > 0A).
  final double isolationResistanceMegaOhms; // Normal > 500 MΩ. Fault < 100 MΩ.
  final double liquidCoolantFlowLitersPerMin; // Cooled cable/inlet loop: Nominal > 3.0 L/min.

  const DcFastChargeInletTelemetry({
    required this.dcPositivePinTemperatureCelsius,
    required this.dcNegativePinTemperatureCelsius,
    required this.chargingCurrentAmperes,
    required this.inletContactResistanceMicroOhms,
    required this.isElectronicLockSolenoidEngaged,
    required this.isolationResistanceMegaOhms,
    required this.liquidCoolantFlowLitersPerMin,
  });

  /// The highest temperature among the two high-current terminal pins.
  double get maxPinTemperatureCelsius =>
      dcPositivePinTemperatureCelsius > dcNegativePinTemperatureCelsius
          ? dcPositivePinTemperatureCelsius
          : dcNegativePinTemperatureCelsius;

  /// Pin thermal differential between positive and negative terminals.
  double get pinThermalDeltaCelsius =>
      (dcPositivePinTemperatureCelsius - dcNegativePinTemperatureCelsius).abs();
}

/// Audit result for DC fast charging terminal safety, automatic current derating, and arcing prevention.
class DcFastChargeInletAuditResult {
  final String vehicleId;
  final DcFastChargeInletStatus status;
  final double maxPinTempCelsius;
  final double thermalDeltaCelsius;
  final double chargeCurrentAmps;
  final double contactResistanceUOhms;
  final double recommendedChargeCurrentLimitAmps;
  final String safetyAdvisory;

  const DcFastChargeInletAuditResult({
    required this.vehicleId,
    required this.status,
    required this.maxPinTempCelsius,
    required this.thermalDeltaCelsius,
    required this.chargeCurrentAmps,
    required this.contactResistanceUOhms,
    required this.recommendedChargeCurrentLimitAmps,
    required this.safetyAdvisory,
  });

  bool get isChargeSessionSafe => status == DcFastChargeInletStatus.chargingProtocolNominal;
  bool get isEmergencyCutoffMandatory =>
      status == DcFastChargeInletStatus.criticalThermalRunawayArcHazard;
}

/// Evaluates high-power DC fast-charging inlet coupler terminal heating, unlatched disconnect arcing, and contact resistance.
class DcFastChargeInletAuditorService {
  const DcFastChargeInletAuditorService();

  DcFastChargeInletAuditResult auditChargingSession({
    required String vehicleId,
    required DcFastChargeInletTelemetry telemetry,
  }) {
    final maxPinTemp = telemetry.maxPinTemperatureCelsius;
    final thermalDelta = telemetry.pinThermalDeltaCelsius;

    // 1. Critical: Unlatched connector while current flowing (>10A), pin >= 110°C, or isolation loss
    if ((!telemetry.isElectronicLockSolenoidEngaged && telemetry.chargingCurrentAmperes > 10.0) ||
        maxPinTemp >= 110.0 ||
        telemetry.inletContactResistanceMicroOhms >= 50.0 ||
        telemetry.isolationResistanceMegaOhms < 100.0) {
      return DcFastChargeInletAuditResult(
        vehicleId: vehicleId,
        status: DcFastChargeInletStatus.criticalThermalRunawayArcHazard,
        maxPinTempCelsius: maxPinTemp,
        thermalDeltaCelsius: thermalDelta,
        chargeCurrentAmps: telemetry.chargingCurrentAmperes,
        contactResistanceUOhms: telemetry.inletContactResistanceMicroOhms,
        recommendedChargeCurrentLimitAmps: 0.0,
        safetyAdvisory:
            'CRITICAL SAFETY FAULT: DC inlet terminal pin thermal limit exceeded (${maxPinTemp.toStringAsFixed(1)}°C) or coupler lock disengaged under live load! Emergency contactor open commanded to abort DC arc flash.',
      );
    }

    // 2. Warning: Pin temperature > 88°C, thermal split > 15°C, or contact resistance elevated -> Derate current
    if (maxPinTemp >= 88.0 ||
        thermalDelta >= 15.0 ||
        telemetry.inletContactResistanceMicroOhms >= 30.0 ||
        telemetry.liquidCoolantFlowLitersPerMin < 2.0) {
      // Calculate derated current to keep pin below 95°C
      final deratedAmps = (telemetry.chargingCurrentAmperes * 0.60).clamp(50.0, 200.0);

      return DcFastChargeInletAuditResult(
        vehicleId: vehicleId,
        status: DcFastChargeInletStatus.thermalDeratingPinWarning,
        maxPinTempCelsius: maxPinTemp,
        thermalDeltaCelsius: thermalDelta,
        chargeCurrentAmps: telemetry.chargingCurrentAmperes,
        contactResistanceUOhms: telemetry.inletContactResistanceMicroOhms,
        recommendedChargeCurrentLimitAmps: deratedAmps,
        safetyAdvisory:
            'WARNING: Charging inlet pin heating elevated (Pin: ${maxPinTemp.toStringAsFixed(1)}°C). Automated EVSE current derated to ${deratedAmps.toStringAsFixed(0)}A. Inspect coupler terminals for socket fretting corrosion.',
      );
    }

    // 3. Normal fast charging operation
    return DcFastChargeInletAuditResult(
      vehicleId: vehicleId,
      status: DcFastChargeInletStatus.chargingProtocolNominal,
      maxPinTempCelsius: maxPinTemp,
      thermalDeltaCelsius: thermalDelta,
      chargeCurrentAmps: telemetry.chargingCurrentAmperes,
      contactResistanceUOhms: telemetry.inletContactResistanceMicroOhms,
      recommendedChargeCurrentLimitAmps: telemetry.chargingCurrentAmperes,
      safetyAdvisory:
          'NOMINAL: DC fast charge inlet thermal dissipation and motorized locking latch are fully secured.',
    );
  }
}
