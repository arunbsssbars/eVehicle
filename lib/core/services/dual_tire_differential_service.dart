/// Dual tire pressure balance and blowout hazard status on heavy commercial dual assemblies.
enum DualTireDifferentialStatus {
  dualsBalanced,
  differentialPressureWarning,
  criticalInnerTireBlowoutFireRisk,
}

/// Real-time wireless TPMS telemetry pairing inner and outer dual wheel assemblies.
class DualTireDifferentialTelemetry {
  final double innerTireColdPressurePsi; // Recommended cold: 100 - 110 PSI.
  final double outerTireColdPressurePsi;
  final double recommendedPressurePsi;
  final double innerTireTemperatureCelsius; // Normal: 45 - 65°C. Overheating underload > 95°C.
  final double outerTireTemperatureCelsius;
  final double wheelHubSpeedKmh;

  const DualTireDifferentialTelemetry({
    required this.innerTireColdPressurePsi,
    required this.outerTireColdPressurePsi,
    this.recommendedPressurePsi = 105.0,
    required this.innerTireTemperatureCelsius,
    required this.outerTireTemperatureCelsius,
    required this.wheelHubSpeedKmh,
  });

  /// Pressure difference between companion dual tires (Max allowable delta: 5.0 PSI before outer tire carries 80% load).
  double get pressureDeltaPsi => (innerTireColdPressurePsi - outerTireColdPressurePsi).abs();

  /// Thermal delta between hidden inner tire and ventilated outer tire.
  double get temperatureDeltaCelsius => (innerTireTemperatureCelsius - outerTireTemperatureCelsius).abs();
}

/// Dual-tire pair differential balance and blowout prevention audit result.
class DualTireDifferentialAuditResult {
  final String vehicleId;
  final String axlePosition; // e.g. "Drive Axle 2 - Left Dual"
  final DualTireDifferentialStatus status;
  final double innerPsi;
  final double outerPsi;
  final double deltaPsi;
  final double innerTempCelsius;
  final double outerTempCelsius;
  final String safetyAdvisory;

  const DualTireDifferentialAuditResult({
    required this.vehicleId,
    required this.axlePosition,
    required this.status,
    required this.innerPsi,
    required this.outerPsi,
    required this.deltaPsi,
    required this.innerTempCelsius,
    required this.outerTempCelsius,
    required this.safetyAdvisory,
  });

  bool get isDualPairBalanced => status == DualTireDifferentialStatus.dualsBalanced;
  bool get isImminentBlowoutRisk =>
      status == DualTireDifferentialStatus.criticalInnerTireBlowoutFireRisk;
}

/// Evaluates companion tire pressure differential, hidden inner tire overheating, and thermal carcass blowout hazards.
class DualTireDifferentialService {
  const DualTireDifferentialService();

  DualTireDifferentialAuditResult auditDualAssembly({
    required String vehicleId,
    required String axlePosition,
    required DualTireDifferentialTelemetry telemetry,
  }) {
    final deltaPsi = telemetry.pressureDeltaPsi;
    final tempDelta = telemetry.temperatureDeltaCelsius;

    // 1. Critical: Delta >= 15 PSI, inner tire flat (< 75 PSI), or thermal runaway > 95°C
    if (deltaPsi >= 15.0 ||
        telemetry.innerTireColdPressurePsi <= 75.0 ||
        telemetry.outerTireColdPressurePsi <= 75.0 ||
        telemetry.innerTireTemperatureCelsius >= 95.0 ||
        tempDelta >= 25.0) {
      return DualTireDifferentialAuditResult(
        vehicleId: vehicleId,
        axlePosition: axlePosition,
        status: DualTireDifferentialStatus.criticalInnerTireBlowoutFireRisk,
        innerPsi: telemetry.innerTireColdPressurePsi,
        outerPsi: telemetry.outerTireColdPressurePsi,
        deltaPsi: deltaPsi,
        innerTempCelsius: telemetry.innerTireTemperatureCelsius,
        outerTempCelsius: telemetry.outerTireTemperatureCelsius,
        safetyAdvisory:
            'CRITICAL HAZARD: Severe dual pressure disparity (${deltaPsi.toStringAsFixed(0)} PSI delta)! Hidden inner tire under-inflation causes companion tire overloading, sidewall zipper rupture, and wheel well fire danger.',
      );
    }

    // 2. Warning: Delta >= 7.0 PSI or inner temp > 80°C
    if (deltaPsi >= 7.0 ||
        telemetry.innerTireTemperatureCelsius >= 80.0 ||
        tempDelta >= 15.0) {
      return DualTireDifferentialAuditResult(
        vehicleId: vehicleId,
        axlePosition: axlePosition,
        status: DualTireDifferentialStatus.differentialPressureWarning,
        innerPsi: telemetry.innerTireColdPressurePsi,
        outerPsi: telemetry.outerTireColdPressurePsi,
        deltaPsi: deltaPsi,
        innerTempCelsius: telemetry.innerTireTemperatureCelsius,
        outerTempCelsius: telemetry.outerTireTemperatureCelsius,
        safetyAdvisory:
            'WARNING: Companion tire pressure delta (${deltaPsi.toStringAsFixed(1)} PSI) exceeds TMC recommended 5 PSI limit. Equalize air pressure to stop unequal tread scrub.',
      );
    }

    // 3. Normal dual balance
    return DualTireDifferentialAuditResult(
      vehicleId: vehicleId,
      axlePosition: axlePosition,
      status: DualTireDifferentialStatus.dualsBalanced,
      innerPsi: telemetry.innerTireColdPressurePsi,
      outerPsi: telemetry.outerTireColdPressurePsi,
      deltaPsi: deltaPsi,
      innerTempCelsius: telemetry.innerTireTemperatureCelsius,
      outerTempCelsius: telemetry.outerTireTemperatureCelsius,
      safetyAdvisory:
          'NOMINAL: Companion dual tires are matched in pressure, temperature, and effective rolling radius.',
    );
  }
}
