/// Status of dynamic cabin positive pressure and hazardous environmental air filtration.
enum PositiveCabPressureStatus {
  cabPressurizedNominalClean,
  filterRestrictionAirLeakWarning,
  criticalDustIntrusionDepressurizationHazard,
}

/// Dynamic micro-manometer telemetry measuring cabin positive differential pressure, HEPA filter restriction, and VOC/silica dust particulates.
class PositiveCabPressureTelemetry {
  final double cabinOverpressurePascals; // Nominal sealed: +50 to +120 Pa. Minimum safety seal > +20 Pa.
  final double hepaFilterDifferentialPressurePascals; // Clean filter: 80 - 180 Pa. Plugged > 400 Pa.
  final double ambientParticulatePm25MicrogramsPerM3; // Outside quarry dust level (e.g. 500 µg/m³)
  final double cabinInternalParticulatePm25MicrogramsPerM3; // Safe inside cabin: < 15 µg/m³. Hazardous > 50 µg/m³.
  final double blowerMotorVoltageVolts; // HVAC fan excitation: 12V or 24V nominal.
  final bool isDoorOrWindowMagneticReedOpen; // Door/window ajar sensor.

  const PositiveCabPressureTelemetry({
    required this.cabinOverpressurePascals,
    required this.hepaFilterDifferentialPressurePascals,
    required this.ambientParticulatePm25MicrogramsPerM3,
    required this.cabinInternalParticulatePm25MicrogramsPerM3,
    required this.blowerMotorVoltageVolts,
    required this.isDoorOrWindowMagneticReedOpen,
  });

  /// Infiltration seal integrity: True if positive barrier is sustained against exterior dust.
  bool get isPositivePressureBarrierActive =>
      !isDoorOrWindowMagneticReedOpen && cabinOverpressurePascals >= 20.0;
}

/// Audit result for mining/quarry positive cabin air pressure, silica dust exclusion, and HEPA filter life.
class PositiveCabPressureAuditResult {
  final String vehicleId;
  final PositiveCabPressureStatus status;
  final double cabinPressurePa;
  final double hepaDeltaPa;
  final double internalDustPm25;
  final bool isSealed;
  final String safetyAdvisory;

  const PositiveCabPressureAuditResult({
    required this.vehicleId,
    required this.status,
    required this.cabinPressurePa,
    required this.hepaDeltaPa,
    required this.internalDustPm25,
    required this.isSealed,
    required this.safetyAdvisory,
  });

  bool get isCabinSafeAndPure => status == PositiveCabPressureStatus.cabPressurizedNominalClean;
  bool get isDepressurizedHazard =>
      status == PositiveCabPressureStatus.criticalDustIntrusionDepressurizationHazard;
}

/// Evaluates heavy mining/quarry vehicle cabin overpressure seal, HEPA intake resistance, and hazardous respirable silica dust exclusion.
class PositiveCabPressureAuditorService {
  const PositiveCabPressureAuditorService();

  PositiveCabPressureAuditResult auditCabinPressure({
    required String vehicleId,
    required PositiveCabPressureTelemetry telemetry,
  }) {
    // 1. Critical: Depressurization (<20 Pa while doors closed) or respirable silica dust intrusion (>50 µg/m³)
    if ((!telemetry.isDoorOrWindowMagneticReedOpen && telemetry.cabinOverpressurePascals < 20.0) ||
        telemetry.cabinInternalParticulatePm25MicrogramsPerM3 >= 50.0 ||
        telemetry.hepaFilterDifferentialPressurePascals >= 450.0) {
      return PositiveCabPressureAuditResult(
        vehicleId: vehicleId,
        status: PositiveCabPressureStatus.criticalDustIntrusionDepressurizationHazard,
        cabinPressurePa: telemetry.cabinOverpressurePascals,
        hepaDeltaPa: telemetry.hepaFilterDifferentialPressurePascals,
        internalDustPm25: telemetry.cabinInternalParticulatePm25MicrogramsPerM3,
        isSealed: false,
        safetyAdvisory:
            'CRITICAL RESPIRATORY HAZARD: Cab positive pressure lost (${telemetry.cabinOverpressurePascals.toStringAsFixed(0)} Pa) or respirable dust intrusion! Inspect cabin door foam weatherstripping and replace plugged HEPA filter cartridge.',
      );
    }

    // 2. Warning: Marginal pressure (20 - 40 Pa), door ajar, or filter restriction elevated
    if (telemetry.isDoorOrWindowMagneticReedOpen ||
        telemetry.cabinOverpressurePascals < 40.0 ||
        telemetry.hepaFilterDifferentialPressurePascals >= 300.0 ||
        telemetry.cabinInternalParticulatePm25MicrogramsPerM3 >= 25.0) {
      return PositiveCabPressureAuditResult(
        vehicleId: vehicleId,
        status: PositiveCabPressureStatus.filterRestrictionAirLeakWarning,
        cabinPressurePa: telemetry.cabinOverpressurePascals,
        hepaDeltaPa: telemetry.hepaFilterDifferentialPressurePascals,
        internalDustPm25: telemetry.cabinInternalParticulatePm25MicrogramsPerM3,
        isSealed: telemetry.isPositivePressureBarrierActive,
        safetyAdvisory: telemetry.isDoorOrWindowMagneticReedOpen
            ? 'WARNING: Cab window/door reed switch open. Close all apertures to restore +50 Pa dust barrier.'
            : 'WARNING: Cabin HEPA filter restriction rising (${telemetry.hepaFilterDifferentialPressurePascals.toStringAsFixed(0)} Pa). Pulse-jet clean intake filter or increase blower fan speed.',
      );
    }

    // 3. Normal nominal pressurization
    return PositiveCabPressureAuditResult(
      vehicleId: vehicleId,
      status: PositiveCabPressureStatus.cabPressurizedNominalClean,
      cabinPressurePa: telemetry.cabinOverpressurePascals,
      hepaDeltaPa: telemetry.hepaFilterDifferentialPressurePascals,
      internalDustPm25: telemetry.cabinInternalParticulatePm25MicrogramsPerM3,
      isSealed: true,
      safetyAdvisory:
          'NOMINAL: Cabin positive overpressure barrier (+${telemetry.cabinOverpressurePascals.toStringAsFixed(0)} Pa) maintains clean, respirable air purity against environmental dust.',
    );
  }
}
