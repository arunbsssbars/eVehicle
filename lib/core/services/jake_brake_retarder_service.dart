/// Jake Brake / compression retarder stage selection.
enum CompressionRetarderStage {
  off,
  lowStage1,    // 2 cylinders active (~33% retarding power)
  mediumStage2, // 4 cylinders active (~66% retarding power)
  highStage3,   // 6 cylinders active (100% retarding power)
}

/// Operational compliance status for engine compression braking.
enum RetarderNoiseZoneStatus {
  unrestrictedHighway,
  noiseOrdinanceRestricted,
  emergencyExemptionActive,
}

/// Downhill grade and engine compression retarder telemetry.
class RetarderGradeTelemetry {
  final double roadGradePercent;          // Downhill slope (e.g. -4% to -10%)
  final double vehicleGrossWeightKg;      // e.g. 38,000 kg
  final double currentVehicleSpeedKmh;    // e.g. 70 km/h
  final double targetDescentSpeedKmh;     // Desired equilibrium speed (e.g. 60 km/h)
  final bool inMuffledNoiseOrdinanceZone; // Municipal "No Engine Brakes" zone
  final CompressionRetarderStage activeStage;

  const RetarderGradeTelemetry({
    required this.roadGradePercent,
    required this.vehicleGrossWeightKg,
    required this.currentVehicleSpeedKmh,
    required this.targetDescentSpeedKmh,
    required this.inMuffledNoiseOrdinanceZone,
    required this.activeStage,
  });
}

/// Comprehensive engine retarder grade audit.
class RetarderGradeAudit {
  final CompressionRetarderStage recommendedStage;
  final double retardingPowerKw;
  final double gravitationalDownhillForceKn;
  final RetarderNoiseZoneStatus noiseZoneStatus;
  final String operationalAdvisory;
  final bool serviceBrakeAssistanceRequired;

  const RetarderGradeAudit({
    required this.recommendedStage,
    required this.retardingPowerKw,
    required this.gravitationalDownhillForceKn,
    required this.noiseZoneStatus,
    required this.operationalAdvisory,
    required this.serviceBrakeAssistanceRequired,
  });
}

/// Service optimizing engine compression braking stages on mountain grades while enforcing noise zones.
class JakeBrakeRetarderService {
  const JakeBrakeRetarderService();

  /// Maximum engine retarding power (typical 15L heavy diesel: ~400 kW at 2100 RPM)
  static const double maxRetarderPowerKw = 400.0;

  /// Evaluates mountain downhill descent and selects optimal compression retarder stage.
  RetarderGradeAudit evaluateRetarder(RetarderGradeTelemetry telemetry) {
    if (telemetry.roadGradePercent >= 0.0) {
      return const RetarderGradeAudit(
        recommendedStage: CompressionRetarderStage.off,
        retardingPowerKw: 0.0,
        gravitationalDownhillForceKn: 0.0,
        noiseZoneStatus: RetarderNoiseZoneStatus.unrestrictedHighway,
        operationalAdvisory: 'FLAT / UPHILL TERRAIN: Engine compression retarder disengaged.',
        serviceBrakeAssistanceRequired: false,
      );
    }

    final double slopeFraction = (telemetry.roadGradePercent.abs()) / 100.0;
    // Downhill gravitational component: F_g = m * g * sin(theta) approx m * g * slope in kN
    final double downhillKn = (telemetry.vehicleGrossWeightKg * 9.81 * slopeFraction) / 1000.0;

    // Power required to hold target speed: P = F * v in kW
    final double targetMps = telemetry.targetDescentSpeedKmh / 3.6;
    final double requiredPowerKw = downhillKn * targetMps;

    CompressionRetarderStage optimalStage;
    double deliverablePowerKw;

    if (requiredPowerKw > 270.0) {
      optimalStage = CompressionRetarderStage.highStage3;
      deliverablePowerKw = maxRetarderPowerKw;
    } else if (requiredPowerKw > 140.0) {
      optimalStage = CompressionRetarderStage.mediumStage2;
      deliverablePowerKw = maxRetarderPowerKw * 0.66;
    } else {
      optimalStage = CompressionRetarderStage.lowStage1;
      deliverablePowerKw = maxRetarderPowerKw * 0.33;
    }

    final bool speedExceeded = telemetry.currentVehicleSpeedKmh > (telemetry.targetDescentSpeedKmh + 5.0);
    final bool frictionBrakeNeeded = requiredPowerKw > maxRetarderPowerKw || speedExceeded;

    RetarderNoiseZoneStatus zoneStatus;
    String advisory;

    if (telemetry.inMuffledNoiseOrdinanceZone) {
      if (speedExceeded && telemetry.roadGradePercent <= -6.0) {
        zoneStatus = RetarderNoiseZoneStatus.emergencyExemptionActive;
        advisory = 'EMERGENCY GRADE EXEMPTION: Municipal noise zone active, but severe mountain slope (-${telemetry.roadGradePercent.abs().toStringAsFixed(1)}%) permits Jake Brake Stage 3 to prevent runaway.';
      } else {
        zoneStatus = RetarderNoiseZoneStatus.noiseOrdinanceRestricted;
        optimalStage = CompressionRetarderStage.off;
        deliverablePowerKw = 0.0;
        advisory = 'NOISE ORDINANCE RESTRICTION: Unmuffled compression braking prohibited in residential/city limits. Rely on driveline hydraulic retarder / service brakes.';
      }
    } else {
      zoneStatus = RetarderNoiseZoneStatus.unrestrictedHighway;
      advisory = 'MOUNTAIN DESCENT ACTIVE: ${optimalStage.name.toUpperCase()} holding equilibrium. Absorbing ${deliverablePowerKw.toStringAsFixed(0)} kW.';
    }

    return RetarderGradeAudit(
      recommendedStage: optimalStage,
      retardingPowerKw: double.parse(deliverablePowerKw.toStringAsFixed(1)),
      gravitationalDownhillForceKn: double.parse(downhillKn.toStringAsFixed(1)),
      noiseZoneStatus: zoneStatus,
      operationalAdvisory: advisory,
      serviceBrakeAssistanceRequired: frictionBrakeNeeded,
    );
  }
}
