/// DPF soot loading and thermal regeneration state.
enum DpfRegenState {
  sootCleanNormal,
  passiveRegenUnderway,
  activeRegenRequired,
  parkedRegenMandatory,
  dpfCrackedFilterAlarm,
}

/// Exhaust aftertreatment DPF telemetry sample.
class DpfExhaustTelemetry {
  final double differentialPressureMbar; // Delta P across DPF core (e.g. 10 to 180 mbar)
  final double sootMassGrams;              // Nominal max capacity: ~45 to 50g
  final double exhaustGasTempCelsius;      // Normal 280°C, active burn > 550°C
  final double vehicleSpeedKmh;
  final int engineOperatingHoursSinceLastRegen;

  const DpfExhaustTelemetry({
    required this.differentialPressureMbar,
    required this.sootMassGrams,
    required this.exhaustGasTempCelsius,
    required this.vehicleSpeedKmh,
    required this.engineOperatingHoursSinceLastRegen,
  });
}

/// Comprehensive DPF soot loading and regeneration safety audit.
class DpfHealthAudit {
  final DpfRegenState state;
  final double sootCapacityPercentage; // 0 to 100%
  final String statusSummary;
  final bool parkedRegenRequired;
  final bool activeBurnPermitted;

  const DpfHealthAudit({
    required this.state,
    required this.sootCapacityPercentage,
    required this.statusSummary,
    required this.parkedRegenRequired,
    required this.activeBurnPermitted,
  });
}

/// Service managing commercial diesel particulate filter soot loading and active burn cycles.
class DpfRegenGuardService {
  const DpfRegenGuardService();

  /// Maximum safe soot capacity before catastrophic thermal runaway / filter cracking
  static const double maxFilterSootGrams = 45.0;

  /// Audits DPF pressure drop, soot accumulation, and safe regeneration windows.
  DpfHealthAudit evaluateDpfHealth(DpfExhaustTelemetry telemetry) {
    final double capacityPercent = ((telemetry.sootMassGrams / maxFilterSootGrams) * 100.0).clamp(0.0, 150.0);

    // Delta P near zero under high load indicates a cracked or hollowed-out DPF core (tampering)
    if (telemetry.vehicleSpeedKmh > 60.0 && telemetry.differentialPressureMbar < 3.0) {
      return const DpfHealthAudit(
        state: DpfRegenState.dpfCrackedFilterAlarm,
        sootCapacityPercentage: 0.0,
        statusSummary: 'CRACKED / TAMPERED DPF: Zero backpressure detected under load. Particulate substrate compromised.',
        parkedRegenRequired: false,
        activeBurnPermitted: false,
      );
    }

    DpfRegenState state;
    String summary;
    bool parkedMandatory = false;
    bool activePermitted = false;

    if (capacityPercent >= 90.0 || telemetry.differentialPressureMbar >= 140.0) {
      state = DpfRegenState.parkedRegenMandatory;
      parkedMandatory = true;
      summary = 'CRITICAL SOOT LOAD: DPF at ${capacityPercent.toStringAsFixed(0)}% capacity (${telemetry.sootMassGrams.toStringAsFixed(0)}g). Engine de-rate imminent! Pull over to safe paved area and execute parked manual regeneration.';
    } else if (capacityPercent >= 70.0 || telemetry.differentialPressureMbar >= 85.0) {
      state = DpfRegenState.activeRegenRequired;
      activePermitted = telemetry.vehicleSpeedKmh >= 60.0;
      summary = activePermitted
          ? 'ACTIVE REGENERATION PERMITTED: Highway cruising conditions optimal. Elevating DOC exhaust temp to 580°C for soot oxidation.'
          : 'ACTIVE REGEN INHIBITED: Soot loading elevated (${capacityPercent.toStringAsFixed(0)}%). Vehicle speed too low for highway auto-regen. Maintain steady cruise.';
    } else if (telemetry.exhaustGasTempCelsius >= 450.0) {
      state = DpfRegenState.passiveRegenUnderway;
      summary = 'PASSIVE BURNOFF ACTIVE: High exhaust temperature (${telemetry.exhaustGasTempCelsius.toStringAsFixed(0)}°C) naturally oxidizing soot into CO₂.';
    } else {
      state = DpfRegenState.sootCleanNormal;
      summary = 'DPF OPERATIONAL: Soot mass low (${telemetry.sootMassGrams.toStringAsFixed(1)}g); backpressure within clean core threshold (${telemetry.differentialPressureMbar.toStringAsFixed(0)} mbar).';
    }

    return DpfHealthAudit(
      state: state,
      sootCapacityPercentage: double.parse(capacityPercent.toStringAsFixed(1)),
      statusSummary: summary,
      parkedRegenRequired: parkedMandatory,
      activeBurnPermitted: activePermitted,
    );
  }
}
