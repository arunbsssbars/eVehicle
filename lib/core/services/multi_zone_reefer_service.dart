/// Operational mode of the multi-zone refrigeration system.
enum ReeferOperatingMode {
  coolingPullDown,
  setpointSatisfied,
  defrostCycleActive,
  temperatureDeviationAlarm,
}

/// Reading from an individual isolated temperature zone.
class ReeferZoneReading {
  final String zoneName;
  final double currentTempCelsius;
  final double setpointTempCelsius;
  final double allowableToleranceCelsius; // e.g. ±1.5°C

  const ReeferZoneReading({
    required this.zoneName,
    required this.currentTempCelsius,
    required this.setpointTempCelsius,
    this.allowableToleranceCelsius = 1.5,
  });

  bool isViolated() {
    return (currentTempCelsius - setpointTempCelsius).abs() > allowableToleranceCelsius;
  }
}

/// Multi-zone telemetry status and evaporator coil parameters.
class MultiZoneReeferTelemetry {
  final List<ReeferZoneReading> zones;
  final double evaporatorFrostThicknessMm; // Above 3.5mm requires hot-gas defrost
  final int compressorHoursSinceLastDefrost;
  final double engineFuelBurnLitersPerHour;

  const MultiZoneReeferTelemetry({
    required this.zones,
    required this.evaporatorFrostThicknessMm,
    required this.compressorHoursSinceLastDefrost,
    required this.engineFuelBurnLitersPerHour,
  });
}

/// Comprehensive multi-zone reefer audit result.
class MultiZoneReeferAudit {
  final ReeferOperatingMode mode;
  final bool hotGasDefrostNeeded;
  final int violatedZoneCount;
  final String statusSummary;
  final bool requiresEmergencyInspection;

  const MultiZoneReeferAudit({
    required this.mode,
    required this.hotGasDefrostNeeded,
    required this.violatedZoneCount,
    required this.statusSummary,
    required this.requiresEmergencyInspection,
  });
}

/// Service managing multi-zone commercial reefer setpoints, thermal gradients, and defrost cycles.
class MultiZoneReeferService {
  const MultiZoneReeferService();

  /// Evaluates 3-zone temperatures and evaporator coil frost accretion.
  MultiZoneReeferAudit evaluateReefer(MultiZoneReeferTelemetry telemetry) {
    int violations = 0;
    for (final z in telemetry.zones) {
      if (z.isViolated()) {
        violations++;
      }
    }

    final bool defrostRequired = telemetry.evaporatorFrostThicknessMm >= 3.5 ||
        telemetry.compressorHoursSinceLastDefrost >= 8;

    ReeferOperatingMode mode;
    String summary;
    bool emergency = false;

    if (violations > 0) {
      mode = ReeferOperatingMode.temperatureDeviationAlarm;
      emergency = true;
      summary = 'TEMPERATURE DEVIATION: $violations cargo compartment(s) breached HACCP setpoint tolerance!';
    } else if (defrostRequired) {
      mode = ReeferOperatingMode.defrostCycleActive;
      summary = 'HOT-GAS DEFROST REQUIRED: Coil frost thickness at ${telemetry.evaporatorFrostThicknessMm.toStringAsFixed(1)} mm. Initiating 15-min defrost cycle.';
    } else {
      mode = ReeferOperatingMode.setpointSatisfied;
      summary = 'ALL ZONES OPTIMAL: Multi-compartment temperatures locked within ±1.5°C setpoints.';
    }

    return MultiZoneReeferAudit(
      mode: mode,
      hotGasDefrostNeeded: defrostRequired,
      violatedZoneCount: violations,
      statusSummary: summary,
      requiresEmergencyInspection: emergency,
    );
  }
}
