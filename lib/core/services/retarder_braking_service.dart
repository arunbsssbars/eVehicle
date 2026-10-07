/// Condition of hydraulic/electric retarder and driveline brake absorption.
enum RetarderBrakingStatus {
  retarderCoolNominal,
  thermalChokeDerateWarning,
  criticalRotorCavitationOilFireHazard,
}

/// Dynamic high-torque telemetry measuring retarder stator oil temperature, braking torque, and rotor cavitation pressure.
class RetarderBrakingTelemetry {
  final double requestedRetarderTorqueNm; // Heavy haul retarder: 1000 - 3500 Nm.
  final double deliveredRetarderTorqueNm;
  final double retarderOilTemperatureCelsius; // Normal: 80 - 110°C. Warning > 130°C. Critical > 155°C.
  final double transmissionCoolantInletTempCelsius;
  final double rotorInternalFluidPressureKPa; // Cavitation occurs if fluid pressure collapses < 350 kPa under full churn.
  final double continuousBrakingDurationSeconds; // Long grade downhill descent.

  const RetarderBrakingTelemetry({
    required this.requestedRetarderTorqueNm,
    required this.deliveredRetarderTorqueNm,
    required this.retarderOilTemperatureCelsius,
    required this.transmissionCoolantInletTempCelsius,
    required this.rotorInternalFluidPressureKPa,
    required this.continuousBrakingDurationSeconds,
  });

  /// Retarder thermal absorption derate ratio (Delivered vs Requested torque).
  double get retarderThermalEfficiencyPercent {
    if (requestedRetarderTorqueNm <= 0.0) return 100.0;
    return ((deliveredRetarderTorqueNm / requestedRetarderTorqueNm) * 100.0).clamp(0.0, 100.0);
  }
}

/// Audit result for driveline hydraulic retarder downhill thermal endurance and rotor cavitation.
class RetarderBrakingAuditResult {
  final String vehicleId;
  final RetarderBrakingStatus status;
  final double actualTorqueNm;
  final double requestedTorqueNm;
  final double retarderOilTempCelsius;
  final double efficiencyPercent;
  final double rotorPressureKPa;
  final String mountainSafetyAdvisory;

  const RetarderBrakingAuditResult({
    required this.vehicleId,
    required this.status,
    required this.actualTorqueNm,
    required this.requestedTorqueNm,
    required this.retarderOilTempCelsius,
    required this.efficiencyPercent,
    required this.rotorPressureKPa,
    required this.mountainSafetyAdvisory,
  });

  bool get isRetarderEffective => status == RetarderBrakingStatus.retarderCoolNominal;
  bool get isRetarderBoilingCritical =>
      status == RetarderBrakingStatus.criticalRotorCavitationOilFireHazard;
}

/// Evaluates driveline hydrodynamic retarder fluid overheating, downhill brake fade prevention, and cavitation air lock.
class RetarderBrakingService {
  const RetarderBrakingService();

  RetarderBrakingAuditResult auditRetarder({
    required String vehicleId,
    required RetarderBrakingTelemetry telemetry,
  }) {
    final efficiency = telemetry.retarderThermalEfficiencyPercent;

    // 1. Critical: Retarder oil temp >= 155°C, fluid pressure collapse < 350 kPa, or severe cavitation fade
    if (telemetry.retarderOilTemperatureCelsius >= 155.0 ||
        telemetry.rotorInternalFluidPressureKPa < 350.0 ||
        (efficiency < 50.0 && telemetry.requestedRetarderTorqueNm > 1500.0)) {
      return RetarderBrakingAuditResult(
        vehicleId: vehicleId,
        status: RetarderBrakingStatus.criticalRotorCavitationOilFireHazard,
        actualTorqueNm: telemetry.deliveredRetarderTorqueNm,
        requestedTorqueNm: telemetry.requestedRetarderTorqueNm,
        retarderOilTempCelsius: telemetry.retarderOilTemperatureCelsius,
        efficiencyPercent: efficiency,
        rotorPressureKPa: telemetry.rotorInternalFluidPressureKPa,
        mountainSafetyAdvisory:
            'CRITICAL DOWNHILL BRAKE FADE: Retarder oil boiling (${telemetry.retarderOilTemperatureCelsius.toStringAsFixed(1)}°C) or rotor cavitation! Auxiliary hydraulic braking disabled. Downshift transmission gear and use foundation air brakes with caution.',
      );
    }

    // 2. Warning: Retarder oil > 130°C or thermal choke derating
    if (telemetry.retarderOilTemperatureCelsius >= 130.0 ||
        efficiency <= 80.0 ||
        telemetry.transmissionCoolantInletTempCelsius >= 105.0) {
      return RetarderBrakingAuditResult(
        vehicleId: vehicleId,
        status: RetarderBrakingStatus.thermalChokeDerateWarning,
        actualTorqueNm: telemetry.deliveredRetarderTorqueNm,
        requestedTorqueNm: telemetry.requestedRetarderTorqueNm,
        retarderOilTempCelsius: telemetry.retarderOilTemperatureCelsius,
        efficiencyPercent: efficiency,
        rotorPressureKPa: telemetry.rotorInternalFluidPressureKPa,
        mountainSafetyAdvisory:
            'WARNING: Retarder thermal absorption throttling (Temp: ${telemetry.retarderOilTemperatureCelsius.toStringAsFixed(1)}°C, Delivery: ${efficiency.toStringAsFixed(0)}%). Downshift engine RPM to speed up water pump cooling flow.',
      );
    }

    // 3. Normal nominal retarder operation
    return RetarderBrakingAuditResult(
      vehicleId: vehicleId,
      status: RetarderBrakingStatus.retarderCoolNominal,
      actualTorqueNm: telemetry.deliveredRetarderTorqueNm,
      requestedTorqueNm: telemetry.requestedRetarderTorqueNm,
      retarderOilTempCelsius: telemetry.retarderOilTemperatureCelsius,
      efficiencyPercent: efficiency,
      rotorPressureKPa: telemetry.rotorInternalFluidPressureKPa,
      mountainSafetyAdvisory:
          'NOMINAL: Hydrodynamic retarder stator and heat exchanger maintain full downhill auxiliary holding torque.',
    );
  }
}
