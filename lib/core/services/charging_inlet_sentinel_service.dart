/// Electric vehicle conductive charging standard interface.
enum EvPlugStandard {
  ccsCombo2,
  ccsCombo1,
  chademo,
  gbt,
  teslaNacs,
}

/// Dynamic charging inlet pin temperature and lock pin telemetry sample.
class ChargingInletTelemetry {
  final EvPlugStandard plugStandard;
  final double dcPinPositiveTempCelsius;
  final double dcPinNegativeTempCelsius;
  final double proximityPilotResistanceOhms;
  final double controlPilotDutyCyclePercent;
  final bool isMotorizedLockPinEngaged;
  final double currentAmperes;
  final double chargingPowerKw;

  const ChargingInletTelemetry({
    required this.plugStandard,
    required this.dcPinPositiveTempCelsius,
    required this.dcPinNegativeTempCelsius,
    this.proximityPilotResistanceOhms = 220.0,
    required this.controlPilotDutyCyclePercent,
    required this.isMotorizedLockPinEngaged,
    required this.currentAmperes,
    required this.chargingPowerKw,
  });

  /// Maximum temperature across the DC high-power terminals.
  double get maxTerminalTempCelsius =>
      dcPinPositiveTempCelsius > dcPinNegativeTempCelsius ? dcPinPositiveTempCelsius : dcPinNegativeTempCelsius;
}

/// Charging session thermal and contact safety status.
enum EvInletSafetyStatus {
  normal,
  thermalDeratingRequested,
  emergencyTripStop,
}

/// Evaluation result for EV conductive charging port safety.
class ChargingInletSafetyResult {
  final String vehicleId;
  final EvInletSafetyStatus status;
  final double maxTerminalTemperatureCelsius;
  final double allowableChargeCurrentAmperes; // Throttled if contact resistance heats up
  final bool isLockPinSecure;
  final bool isImmediateEStopTriggered;
  final String safetyAdvisory;

  const ChargingInletSafetyResult({
    required this.vehicleId,
    required this.status,
    required this.maxTerminalTemperatureCelsius,
    required this.allowableChargeCurrentAmperes,
    required this.isLockPinSecure,
    required this.isImmediateEStopTriggered,
    required this.safetyAdvisory,
  });

  bool get isSafe => status == EvInletSafetyStatus.normal;
}

/// EV DC Fast Charging Port Inlet Thermal Overheat & Lock Pin Sentinel Service.
class ChargingInletSentinelService {
  const ChargingInletSentinelService();

  // Thresholds (IEC 62196 standard)
  static const double terminalThermalTripCelsius = 90.0;     // Emergency charge cut-off
  static const double terminalDeratingThresholdCelsius = 75.0; // Current reduction request

  ChargingInletSafetyResult evaluateInletSafety({
    required String vehicleId,
    required ChargingInletTelemetry telemetry,
  }) {
    final maxTemp = telemetry.maxTerminalTempCelsius;
    final lockSecure = telemetry.isMotorizedLockPinEngaged;

    EvInletSafetyStatus status;
    double allowedCurrent = telemetry.currentAmperes;
    bool emergencyStop = false;
    String advisory;

    if (!lockSecure) {
      status = EvInletSafetyStatus.emergencyTripStop;
      allowedCurrent = 0.0;
      emergencyStop = true;
      advisory = 'SAFETY INTERLOCK VIOLATION: Motorized charge plug lock disengaged. High-voltage arc hazard. Session terminated.';
    } else if (maxTemp >= terminalThermalTripCelsius) {
      status = EvInletSafetyStatus.emergencyTripStop;
      allowedCurrent = 0.0;
      emergencyStop = true;
      advisory = 'THERMAL OVERHEAT TRIP: Charging inlet pin temperature reached ${maxTemp.toStringAsFixed(1)}°C. Contact resistance degradation. Charging halted.';
    } else if (maxTemp >= terminalDeratingThresholdCelsius) {
      status = EvInletSafetyStatus.thermalDeratingRequested;
      allowedCurrent = (telemetry.currentAmperes * 0.50).clamp(0.0, 500.0); // 50% current throttle
      emergencyStop = false;
      advisory = 'THERMAL DERATING: Charge port warm (${maxTemp.toStringAsFixed(1)}°C). Current throttled to 50% to prevent connector melt.';
    } else {
      status = EvInletSafetyStatus.normal;
      emergencyStop = false;
      advisory = 'DC fast charge port locked, cooled, and operating within IEC 62196 thermal limits.';
    }

    return ChargingInletSafetyResult(
      vehicleId: vehicleId,
      status: status,
      maxTerminalTemperatureCelsius: double.parse(maxTemp.toStringAsFixed(1)),
      allowableChargeCurrentAmperes: double.parse(allowedCurrent.toStringAsFixed(1)),
      isLockPinSecure: lockSecure,
      isImmediateEStopTriggered: emergencyStop,
      safetyAdvisory: advisory,
    );
  }
}
