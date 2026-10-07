import 'dart:math' as math;

/// Thermal brake fade risk severity.
enum BrakeFadeRiskLevel {
  nominalCool,
  moderateThermalLoad,
  imminentBrakeFadeWarning,
  criticalThermalRunawayLockout,
}

/// Dynamic descent telemetry for heavy commercial and towing vehicles.
class MountainDescentTelemetry {
  final double grossVehicleWeightKg;
  final double roadGradePercent; // e.g. -6.0% downhill
  final double descentSpeedKmh;
  final double descentDistanceMeters;
  final double ambientTemperatureCelsius;
  final double initialBrakeRotorTempCelsius;
  final double auxiliaryRetarderRetardationKw; // Retarder/Jake brake absorption

  const MountainDescentTelemetry({
    required this.grossVehicleWeightKg,
    required this.roadGradePercent,
    required this.descentSpeedKmh,
    required this.descentDistanceMeters,
    required this.ambientTemperatureCelsius,
    required this.initialBrakeRotorTempCelsius,
    this.auxiliaryRetarderRetardationKw = 0.0,
  });
}

/// Predictive brake thermal absorption and fade assessment.
class BrakeThermalAudit {
  final double estimatedRotorTempCelsius;
  final double cumulativeDissipatedEnergyMegaJoules;
  final double brakingThermalAbsorptionKw;
  final BrakeFadeRiskLevel riskLevel;
  final double recommendedSafeDescentSpeedKmh;
  final String safetyAdvisory;
  final bool runawayRampRequired;

  const BrakeThermalAudit({
    required this.estimatedRotorTempCelsius,
    required this.cumulativeDissipatedEnergyMegaJoules,
    required this.brakingThermalAbsorptionKw,
    required this.riskLevel,
    required this.recommendedSafeDescentSpeedKmh,
    required this.safetyAdvisory,
    required this.runawayRampRequired,
  });
}

/// Service predicting heavy vehicle foundation brake fade, friction loss, and downhill thermal saturation.
class BrakeFadeThermalService {
  const BrakeFadeThermalService();

  // Lumped rotor thermal parameters (typical commercial disc brake assembly: ~80kg effective rotor mass per axle)
  static const double rotorEffectiveHeatCapacityJPerKgC = 500.0; // Cast iron heat capacity
  static const double estimatedRotorMassKgPerVehicle = 160.0;     // Approx twin drive axle brake mass
  static const double brakeFrictionFadeThresholdCelsius = 450.0;  // Severe fade starts
  static const double runawayCriticalTempCelsius = 650.0;         // Fluid boiling / lining vaporization

  BrakeThermalAudit predictThermalLoad(MountainDescentTelemetry telemetry) {
    // Gravitational potential energy release rate: P_gravity = m * g * v * sin(theta)
    const double g = 9.80665;
    final double vMps = telemetry.descentSpeedKmh / 3.6;
    final double gradeFraction = (telemetry.roadGradePercent.abs()) / 100.0;
    final double gradeAngleRad = math.atan(gradeFraction);

    // Aerodynamic + rolling drag counter-power (approximate baseline resistance)
    final double rollingAndAeroResistanceKw = (telemetry.grossVehicleWeightKg * 0.012 * 9.81 * vMps +
            0.5 * 1.225 * 6.5 * 0.7 * math.pow(vMps, 3)) /
        1000.0;

    // Total gravitational descent power in kW
    final double totalDescentPowerKw =
        (telemetry.grossVehicleWeightKg * g * vMps * math.sin(gradeAngleRad)) / 1000.0;

    // Net power entering foundation friction brakes after aero, rolling drag, and auxiliary retarders
    final double netBrakePowerKw = math.max(
      0.0,
      totalDescentPowerKw - rollingAndAeroResistanceKw - telemetry.auxiliaryRetarderRetardationKw,
    );

    // Duration of descent in seconds
    final double descentDurationSeconds = vMps > 0.1 ? (telemetry.descentDistanceMeters / vMps) : 0.0;

    // Total dissipated mechanical friction energy in MJ
    final double totalEnergyMj = (netBrakePowerKw * descentDurationSeconds) / 1000.0;

    // Heat transfer calculation: deltaT = Energy_absorbed / (mass * Cp)
    // Convective air cooling rate during descent
    final double coolingCoeff = 1.0 + (telemetry.descentSpeedKmh * 0.02);
    final double convectiveDissipationJoules =
        coolingCoeff * 85.0 * descentDurationSeconds * math.max(10.0, telemetry.initialBrakeRotorTempCelsius - telemetry.ambientTemperatureCelsius);

    final double netEnergyJoulesToRotor = math.max(0.0, (netBrakePowerKw * 1000.0 * descentDurationSeconds) - convectiveDissipationJoules);
    final double tempRiseCelsius = netEnergyJoulesToRotor / (estimatedRotorMassKgPerVehicle * rotorEffectiveHeatCapacityJPerKgC);

    final double predictedRotorTemp = telemetry.initialBrakeRotorTempCelsius + tempRiseCelsius;

    BrakeFadeRiskLevel risk;
    String advisory;
    bool runawayRamp = false;
    double safeSpeed = telemetry.descentSpeedKmh;

    if (predictedRotorTemp >= runawayCriticalTempCelsius) {
      risk = BrakeFadeRiskLevel.criticalThermalRunawayLockout;
      runawayRamp = true;
      safeSpeed = math.min(telemetry.descentSpeedKmh, 25.0);
      advisory = 'CRITICAL BRAKE TEMPERATURE: Rotor temp ${predictedRotorTemp.toStringAsFixed(0)}°C exceeds lining vaporization limits! Prepare for emergency runaway truck ramp.';
    } else if (predictedRotorTemp >= brakeFrictionFadeThresholdCelsius) {
      risk = BrakeFadeRiskLevel.imminentBrakeFadeWarning;
      safeSpeed = math.min(telemetry.descentSpeedKmh, 40.0);
      advisory = 'IMMINENT BRAKE FADE: High thermal saturation (${predictedRotorTemp.toStringAsFixed(0)}°C). Friction coefficient dropping rapidly. Downshift immediately and maximize auxiliary retarder.';
    } else if (predictedRotorTemp >= 280.0) {
      risk = BrakeFadeRiskLevel.moderateThermalLoad;
      safeSpeed = telemetry.descentSpeedKmh;
      advisory = 'MODERATE THERMAL LOAD: Rotors warm (${predictedRotorTemp.toStringAsFixed(0)}°C). Maintain steady gear selection and snub braking.';
    } else {
      risk = BrakeFadeRiskLevel.nominalCool;
      safeSpeed = telemetry.descentSpeedKmh;
      advisory = 'BRAKES NOMINAL: Stable operating rotor temperature (${predictedRotorTemp.toStringAsFixed(0)}°C).';
    }

    return BrakeThermalAudit(
      estimatedRotorTempCelsius: double.parse(predictedRotorTemp.toStringAsFixed(1)),
      cumulativeDissipatedEnergyMegaJoules: double.parse(totalEnergyMj.toStringAsFixed(2)),
      brakingThermalAbsorptionKw: double.parse(netBrakePowerKw.toStringAsFixed(1)),
      riskLevel: risk,
      recommendedSafeDescentSpeedKmh: double.parse(safeSpeed.toStringAsFixed(0)),
      safetyAdvisory: advisory,
      runawayRampRequired: runawayRamp,
    );
  }
}
