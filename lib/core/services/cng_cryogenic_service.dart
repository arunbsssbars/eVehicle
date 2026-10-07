/// Pressure and boil-off risk status of CNG/LNG fuel systems.
enum CngSystemStatus {
  normalOperational,
  ventingPressureWarning,
  methaneLeakAlarm,
  recertificationExpired,
}

/// Cryogenic / high-pressure fuel tank telemetry.
class GasTankTelemetrySample {
  final double cylinderPressureBar;        // Nominal 200 bar (CNG) or 6-12 bar (LNG)
  final double maxRatedPressureBar;        // e.g. 250 bar (CNG) or 16 bar (LNG)
  final double tankTemperatureKelvin;      // e.g. 111 K (-162°C) for LNG
  final double methaneDetectorPpm;         // Sensor in engine bay (alert > 500 ppm, LEL > 50,000 ppm)
  final DateTime hydrostaticCertExpiry;

  const GasTankTelemetrySample({
    required this.cylinderPressureBar,
    required this.maxRatedPressureBar,
    required this.tankTemperatureKelvin,
    required this.methaneDetectorPpm,
    required this.hydrostaticCertExpiry,
  });
}

/// Comprehensive fuel safety and pressure vessel compliance audit.
class GasSystemSafetyAudit {
  final CngSystemStatus status;
  final double pressureFillPercent;
  final bool boilOffVentingImminent;
  final int daysUntilCertExpiry;
  final String statusSummary;
  final bool requiresEmergencyVentOrShutoff;

  const GasSystemSafetyAudit({
    required this.status,
    required this.pressureFillPercent,
    required this.boilOffVentingImminent,
    required this.daysUntilCertExpiry,
    required this.statusSummary,
    required this.requiresEmergencyVentOrShutoff,
  });
}

/// Service managing CNG/LNG high-pressure and cryogenic boil-off gas safety.
class CngCryogenicService {
  const CngCryogenicService();

  /// Audits cylinder pressure, methane leakage, and hydrostatic vessel expiry.
  GasSystemSafetyAudit auditGasSafety({
    required GasTankTelemetrySample sample,
    DateTime? checkTime,
  }) {
    final now = checkTime ?? DateTime.now();
    final daysToExpiry = sample.hydrostaticCertExpiry.difference(now).inDays;
    final fillPercent = (sample.cylinderPressureBar / sample.maxRatedPressureBar) * 100.0;
    final bool ventingRisk = fillPercent >= 92.0;

    CngSystemStatus status;
    String summary;
    bool emergencyAction = false;

    if (sample.methaneDetectorPpm >= 1200.0) {
      status = CngSystemStatus.methaneLeakAlarm;
      emergencyAction = true;
      summary = 'CRITICAL METHANE LEAK: Under-hood gas detector at ${sample.methaneDetectorPpm.toStringAsFixed(0)} ppm. Shut off tank manual valves immediately!';
    } else if (ventingRisk) {
      status = CngSystemStatus.ventingPressureWarning;
      emergencyAction = true;
      summary = 'OVERPRESSURE WARNING: Tank at ${fillPercent.toStringAsFixed(0)}% rated pressure. Boil-off gas relief valve approaching pop-off threshold.';
    } else if (daysToExpiry <= 0) {
      status = CngSystemStatus.recertificationExpired;
      emergencyAction = false;
      summary = 'CYLINDER RECERTIFICATION EXPIRED: ECE R110 hydrostatic test overdue. Fueling prohibited.';
    } else {
      status = CngSystemStatus.normalOperational;
      summary = 'GAS PRESSURE NORMAL: Cylinder holding stable at ${sample.cylinderPressureBar.toStringAsFixed(0)} bar; zero methane slip.';
    }

    return GasSystemSafetyAudit(
      status: status,
      pressureFillPercent: double.parse(fillPercent.clamp(0.0, 150.0).toStringAsFixed(1)),
      boilOffVentingImminent: ventingRisk,
      daysUntilCertExpiry: daysToExpiry,
      statusSummary: summary,
      requiresEmergencyVentOrShutoff: emergencyAction,
    );
  }
}
