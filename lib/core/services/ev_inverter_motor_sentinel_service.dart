import 'dart:math';

/// Electric drive motor type.
enum EvMotorType {
  permanentMagnetSynchronous,
  acInduction,
  switchedReluctance,
}

/// Dynamic motor stator and inverter telemetry sample.
class EvInverterMotorTelemetry {
  final EvMotorType motorType;
  final double statorWindingTempCelsius;
  final double inverterIgbtTempCelsius;
  final double rotorSpeedRpm;
  final double torqueDemandNm;
  final double actualDeliveredTorqueNm;
  final double dcBusVoltage;
  final double phaseCurrentAmperes;

  const EvInverterMotorTelemetry({
    required this.motorType,
    required this.statorWindingTempCelsius,
    required this.inverterIgbtTempCelsius,
    required this.rotorSpeedRpm,
    required this.torqueDemandNm,
    required this.actualDeliveredTorqueNm,
    required this.dcBusVoltage,
    required this.phaseCurrentAmperes,
  });

  /// Inverter electrical input power in kW.
  double get electricInputPowerKw => (dcBusVoltage * phaseCurrentAmperes * sqrt(3)) / 1000.0;

  /// Mechanical output power in kW: P = (Torque * RPM) / 9549
  double get mechanicalOutputPowerKw =>
      rotorSpeedRpm > 0 ? (actualDeliveredTorqueNm * rotorSpeedRpm) / 9549.0 : 0.0;

  /// Instantaneous electromechanical powertrain efficiency percentage.
  double get conversionEfficiencyPercent {
    if (electricInputPowerKw <= 0.1 || mechanicalOutputPowerKw <= 0) return 90.0;
    final eff = (mechanicalOutputPowerKw / electricInputPowerKw) * 100.0;
    return eff.clamp(50.0, 98.5);
  }
}

/// Operational state of EV motor & silicon-carbide inverter.
enum EvInverterHealthStatus {
  nominal,
  thermalDeratingActive,
  criticalOverheatTrip,
}

/// Evaluation result for EV motor torque output, IGBT thermal envelope & efficiency.
class EvInverterHealthResult {
  final String vehicleId;
  final EvInverterHealthStatus status;
  final double statorTempCelsius;
  final double igbtTempCelsius;
  final double powertrainEfficiencyPercent;
  final double allowableTorquePercentage; // Derated if hot (e.g. 70%)
  final bool isCoolantPumpBoostRequired;
  final String advisory;

  const EvInverterHealthResult({
    required this.vehicleId,
    required this.status,
    required this.statorTempCelsius,
    required this.igbtTempCelsius,
    required this.powertrainEfficiencyPercent,
    required this.allowableTorquePercentage,
    required this.isCoolantPumpBoostRequired,
    required this.advisory,
  });

  bool get isSafe => status == EvInverterHealthStatus.nominal;
}

/// EV Inverter Silicon-Carbide (SiC) / IGBT Thermal & Motor Flux Sentinel Service.
class EvInverterMotorSentinelService {
  const EvInverterMotorSentinelService();

  // Thresholds
  static const double igbtOverheatLimitCelsius = 110.0;
  static const double statorOverheatLimitCelsius = 135.0; // Class H winding insulation limit
  static const double igbtDerateWarningCelsius = 95.0;

  EvInverterHealthResult evaluateInverterHealth({
    required String vehicleId,
    required EvInverterMotorTelemetry telemetry,
  }) {
    final igbt = telemetry.inverterIgbtTempCelsius;
    final stator = telemetry.statorWindingTempCelsius;

    EvInverterHealthStatus status;
    double allowedTorque = 100.0;
    bool boostPump = false;
    String advisory;

    if (igbt >= igbtOverheatLimitCelsius || stator >= statorOverheatLimitCelsius) {
      status = EvInverterHealthStatus.criticalOverheatTrip;
      allowedTorque = 25.0; // Limp home emergency mode
      boostPump = true;
      advisory = 'CRITICAL: Inverter/Stator junction temperature exceedance (${igbt.toStringAsFixed(0)}°C IGBT). Drive torque collapsed to limp mode.';
    } else if (igbt >= igbtDerateWarningCelsius || stator >= 115.0) {
      status = EvInverterHealthStatus.thermalDeratingActive;
      allowedTorque = 70.0; // 30% thermal derating applied
      boostPump = true;
      advisory = 'THERMAL DERATING: High inverter temperature. Torque restricted to 70% to protect silicon switches.';
    } else {
      status = EvInverterHealthStatus.nominal;
      allowedTorque = 100.0;
      boostPump = false;
      advisory = 'Electric traction motor and inverter thermal envelope optimal.';
    }

    return EvInverterHealthResult(
      vehicleId: vehicleId,
      status: status,
      statorTempCelsius: double.parse(stator.toStringAsFixed(1)),
      igbtTempCelsius: double.parse(igbt.toStringAsFixed(1)),
      powertrainEfficiencyPercent: double.parse(telemetry.conversionEfficiencyPercent.toStringAsFixed(1)),
      allowableTorquePercentage: allowedTorque,
      isCoolantPumpBoostRequired: boostPump,
      advisory: advisory,
    );
  }
}
