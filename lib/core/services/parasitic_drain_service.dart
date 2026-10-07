/// Operational health of 12V/24V electrical generation and storage.
enum ElectricalHealthStatus {
  normalHoldingCharge,
  parasiticDrainExcessive,
  alternatorCurrentMismatch,
  criticalStartingRisk,
}

/// Electrical system sensor reading during parking or engine running.
class ElectricalTelemetrySample {
  final double starterBatteryVoltage;    // Nominal 12.6V (12V) or 25.2V (24V)
  final double keyOffParasiticDrainMilliAmps; // Acceptable < 50 mA; excessive > 120 mA
  final double primaryAlternatorAmps;   // Alternator A output
  final double secondaryAlternatorAmps; // Alternator B output (dual setup)
  final bool engineRunning;
  final int consecutiveParkedHours;

  const ElectricalTelemetrySample({
    required this.starterBatteryVoltage,
    required this.keyOffParasiticDrainMilliAmps,
    required this.primaryAlternatorAmps,
    required this.secondaryAlternatorAmps,
    required this.engineRunning,
    required this.consecutiveParkedHours,
  });
}

/// Diagnostic evaluation of electrical parasitic leakage and battery state-of-charge.
class ElectricalHealthAudit {
  final ElectricalHealthStatus status;
  final double estimatedStateOfChargePercent;
  final int estimatedHoursUntilNoStart;
  final String statusSummary;
  final bool isolationRelayTripRecommended;

  const ElectricalHealthAudit({
    required this.status,
    required this.estimatedStateOfChargePercent,
    required this.estimatedHoursUntilNoStart,
    required this.statusSummary,
    required this.isolationRelayTripRecommended,
  });
}

/// Service auditing key-off parasitic vampire drains and dual-alternator current splits.
class ParasiticDrainService {
  const ParasiticDrainService();

  /// Audits battery reserve capacity and parasitic drain rate to prevent no-start dead batteries.
  ElectricalHealthAudit evaluateElectricalHealth(ElectricalTelemetrySample sample) {
    // Lead-acid 12V reference curve: 12.7V = 100%, 12.4V = 75%, 12.2V = 50%, 11.9V = 0%
    // Normalize if 24V system
    final normalizedVoltage = sample.starterBatteryVoltage > 18.0
        ? sample.starterBatteryVoltage / 2.0
        : sample.starterBatteryVoltage;

    double socPercent = 0.0;
    if (normalizedVoltage >= 12.7) {
      socPercent = 100.0;
    } else if (normalizedVoltage <= 11.8) {
      socPercent = 5.0;
    } else {
      socPercent = ((normalizedVoltage - 11.8) / 0.9) * 100.0;
    }
    socPercent = socPercent.clamp(0.0, 100.0);

    // Reserve capacity estimate for typical 100Ah commercial battery
    // Safe drain capacity before engine cranking fails: ~40 Ah
    final double safeCapacityAh = 40.0 * (socPercent / 100.0);
    final double drainAmps = sample.keyOffParasiticDrainMilliAmps / 1000.0;
    final int hoursToDead = drainAmps > 0.01
        ? (safeCapacityAh / drainAmps).round().clamp(1, 720)
        : 720;

    ElectricalHealthStatus status;
    String summary;
    bool tripRelay = false;

    if (!sample.engineRunning && (normalizedVoltage <= 12.0 || hoursToDead <= 12)) {
      status = ElectricalHealthStatus.criticalStartingRisk;
      tripRelay = true;
      summary = 'CRITICAL BATTERY DEPLETION: Starter voltage at ${sample.starterBatteryVoltage.toStringAsFixed(1)}V. Cranking failure imminent within $hoursToDead hours! Tripping low-voltage disconnect relay.';
    } else if (!sample.engineRunning && sample.keyOffParasiticDrainMilliAmps > 150.0) {
      status = ElectricalHealthStatus.parasiticDrainExcessive;
      tripRelay = hoursToDead <= 24;
      summary = 'EXCESSIVE VAMPIRE DRAIN: Quiescent draw is ${sample.keyOffParasiticDrainMilliAmps.toStringAsFixed(0)} mA (max spec 50 mA). Telematic unit or auxiliary inverter short suspect.';
    } else if (sample.engineRunning && (sample.primaryAlternatorAmps - sample.secondaryAlternatorAmps).abs() > 45.0) {
      status = ElectricalHealthStatus.alternatorCurrentMismatch;
      summary = 'DUAL ALTERNATOR IMBALANCE: Diode rectifier mismatch between Alt A (${sample.primaryAlternatorAmps.toStringAsFixed(0)}A) and Alt B (${sample.secondaryAlternatorAmps.toStringAsFixed(0)}A).';
    } else {
      status = ElectricalHealthStatus.normalHoldingCharge;
      summary = 'ELECTRICAL SYSTEM HEALTHY: Parasitic quiescent draw within normal standby range (${sample.keyOffParasiticDrainMilliAmps.toStringAsFixed(0)} mA).';
    }

    return ElectricalHealthAudit(
      status: status,
      estimatedStateOfChargePercent: double.parse(socPercent.toStringAsFixed(1)),
      estimatedHoursUntilNoStart: hoursToDead,
      statusSummary: summary,
      isolationRelayTripRecommended: tripRelay,
    );
  }
}
