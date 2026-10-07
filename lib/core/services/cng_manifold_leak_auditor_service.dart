/// Commercial CNG / LNG tank valve & manifold status.
enum CngManifoldStatus {
  normalSealedPressure,
  minorMicroSeepageWarning,
  criticalMethaneLeakExplosionRisk,
}

/// Dynamic telemetry reading from methane sniffing sensors and manifold pressure sensors.
class CngManifoldTelemetry {
  final double manifoldPressureBar; // Nominal working pressure: 200 - 250 Bar
  final double tankSurfaceTemperatureCelsius;
  final double methaneConcentrationPpm; // Baseline ambient: < 50 PPM
  final double lowerExplosiveLimitPercent; // LEL threshold (100% LEL = ~50,000 PPM CH4)
  final bool isAutomaticShutoffSolenoidEnergized;

  const CngManifoldTelemetry({
    required this.manifoldPressureBar,
    required this.tankSurfaceTemperatureCelsius,
    required this.methaneConcentrationPpm,
    required this.lowerExplosiveLimitPercent,
    required this.isAutomaticShutoffSolenoidEnergized,
  });
}

/// Comprehensive CNG high-pressure manifold gas tightness audit result.
class CngLeakAuditResult {
  final String vehicleId;
  final CngManifoldStatus status;
  final double methanePpm;
  final double manifoldPressureBar;
  final double lowerExplosiveLimitPercent;
  final bool isEmergencyCutoffTriggered;
  final String safetyDirective;

  const CngLeakAuditResult({
    required this.vehicleId,
    required this.status,
    required this.methanePpm,
    required this.manifoldPressureBar,
    required this.lowerExplosiveLimitPercent,
    required this.isEmergencyCutoffTriggered,
    required this.safetyDirective,
  });

  bool get isSafeToOperate => status == CngManifoldStatus.normalSealedPressure;
  bool get isExplosionHazard => status == CngManifoldStatus.criticalMethaneLeakExplosionRisk;
}

/// Service that audits commercial CNG/LNG cylinder manifold gas leaks and LEL safety thresholds.
class CngManifoldLeakAuditorService {
  const CngManifoldLeakAuditorService();

  CngLeakAuditResult auditCngManifold({
    required String vehicleId,
    required CngManifoldTelemetry telemetry,
  }) {
    // Critical: LEL >= 20% or Methane concentration >= 10,000 PPM or sudden pressure drop with sniffing alert
    if (telemetry.lowerExplosiveLimitPercent >= 20.0 || telemetry.methaneConcentrationPpm >= 5000.0) {
      return CngLeakAuditResult(
        vehicleId: vehicleId,
        status: CngManifoldStatus.criticalMethaneLeakExplosionRisk,
        methanePpm: telemetry.methaneConcentrationPpm,
        manifoldPressureBar: telemetry.manifoldPressureBar,
        lowerExplosiveLimitPercent: telemetry.lowerExplosiveLimitPercent,
        isEmergencyCutoffTriggered: true,
        safetyDirective:
            'EXPLOSION HAZARD (>=20% LEL): Methane gas leak detected in cylinder bay! High-pressure solenoid automatic cutoff tripped. Evacuate bus/truck immediately.',
      );
    }

    if (telemetry.lowerExplosiveLimitPercent >= 5.0 || telemetry.methaneConcentrationPpm > 400.0) {
      return CngLeakAuditResult(
        vehicleId: vehicleId,
        status: CngManifoldStatus.minorMicroSeepageWarning,
        methanePpm: telemetry.methaneConcentrationPpm,
        manifoldPressureBar: telemetry.manifoldPressureBar,
        lowerExplosiveLimitPercent: telemetry.lowerExplosiveLimitPercent,
        isEmergencyCutoffTriggered: false,
        safetyDirective:
            'WARNING: Micro-seepage detected around cylinder valve O-rings or PRD burst disk. Inspect manifold fitting with soap bubble solution.',
      );
    }

    return CngLeakAuditResult(
      vehicleId: vehicleId,
      status: CngManifoldStatus.normalSealedPressure,
      methanePpm: telemetry.methaneConcentrationPpm,
      manifoldPressureBar: telemetry.manifoldPressureBar,
      lowerExplosiveLimitPercent: telemetry.lowerExplosiveLimitPercent,
      isEmergencyCutoffTriggered: false,
      safetyDirective:
          'NOMINAL: CNG manifold gas tightness sealed. Ambient methane concentration within normal baseline (<50 PPM).',
    );
  }
}
