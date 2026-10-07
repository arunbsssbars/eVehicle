/// Structural stability and footing settlement status of semi-trailer landing gear legs.
enum LandingGearLoadSplayStatus {
  plumbAndStable,
  splaySettlementWarning,
  criticalBucklingCollapseHazard,
}

/// Dynamic dual-leg telemetry measuring individual vertical ton load, ground penetration, and plumb angular deviation.
class LandingGearLoadTelemetry {
  final double curbsideLegLoadTonnes; // Rated capacity: ~25 tonnes per leg static.
  final double roadsideLegLoadTonnes;
  final double ratedLegCapacityTonnes;
  final double angularSplayDegrees; // Angular deflection from vertical plumb (Normal < 0.8°. Buckling > 2.5°).
  final double asphaltFootingPenetrationMm; // Settlement sinking into soft ground/hot asphalt (Normal < 10 mm. Sinking > 40 mm).
  final double crossShaftTorqueNewtonMetres; // Resistance when cranking gear (Binding > 80 Nm).

  const LandingGearLoadTelemetry({
    required this.curbsideLegLoadTonnes,
    required this.roadsideLegLoadTonnes,
    this.ratedLegCapacityTonnes = 25.0,
    required this.angularSplayDegrees,
    required this.asphaltFootingPenetrationMm,
    required this.crossShaftTorqueNewtonMetres,
  });

  /// Total static load resting on the landing gear dolly.
  double get totalDollyLoadTonnes => curbsideLegLoadTonnes + roadsideLegLoadTonnes;

  /// Load asymmetry delta between curbside and roadside legs (Load imbalance > 6.0 tonnes induces leg twisting).
  double get legLoadAsymmetryTonnes => (curbsideLegLoadTonnes - roadsideLegLoadTonnes).abs();
}

/// Landing gear stability and ground settlement audit result.
class LandingGearAuditResult {
  final String vehicleId;
  final LandingGearLoadSplayStatus status;
  final double totalLoadTonnes;
  final double loadAsymmetryTonnes;
  final double splayDegrees;
  final double groundSettlementMm;
  final String safetyAdvisory;

  const LandingGearAuditResult({
    required this.vehicleId,
    required this.status,
    required this.totalLoadTonnes,
    required this.loadAsymmetryTonnes,
    required this.splayDegrees,
    required this.groundSettlementMm,
    required this.safetyAdvisory,
  });

  bool get isLegPlumbAndSound => status == LandingGearLoadSplayStatus.plumbAndStable;
  bool get isImminentTipoverRisk =>
      status == LandingGearLoadSplayStatus.criticalBucklingCollapseHazard;
}

/// Evaluates decoupled semi-trailer landing gear vertical load, diagonal splay deflection, and asphalt punch-through.
class LandingGearLoadSplayService {
  const LandingGearLoadSplayService();

  LandingGearAuditResult auditLandingGear({
    required String vehicleId,
    required LandingGearLoadTelemetry telemetry,
  }) {
    final asymmetry = telemetry.legLoadAsymmetryTonnes;
    final totalLoad = telemetry.totalDollyLoadTonnes;

    // 1. Critical: Splay >= 2.5°, footing punch-through >= 50 mm, or leg overload > 25 tonnes
    if (telemetry.angularSplayDegrees >= 2.5 ||
        telemetry.asphaltFootingPenetrationMm >= 50.0 ||
        telemetry.curbsideLegLoadTonnes > telemetry.ratedLegCapacityTonnes ||
        telemetry.roadsideLegLoadTonnes > telemetry.ratedLegCapacityTonnes ||
        asymmetry >= 8.0) {
      return LandingGearAuditResult(
        vehicleId: vehicleId,
        status: LandingGearLoadSplayStatus.criticalBucklingCollapseHazard,
        totalLoadTonnes: totalLoad,
        loadAsymmetryTonnes: asymmetry,
        splayDegrees: telemetry.angularSplayDegrees,
        groundSettlementMm: telemetry.asphaltFootingPenetrationMm,
        safetyAdvisory:
            'CRITICAL HAZARD: Landing gear buckling or soft ground punch-through detected (${telemetry.asphaltFootingPenetrationMm.toStringAsFixed(0)} mm penetration, ${telemetry.angularSplayDegrees.toStringAsFixed(1)}° splay)! Extreme risk of trailer nose dive or side rollover during forklift loading.',
      );
    }

    // 2. Warning: Splay >= 1.2°, footing penetration >= 25 mm, or asymmetry >= 4.5 tonnes
    if (telemetry.angularSplayDegrees >= 1.2 ||
        telemetry.asphaltFootingPenetrationMm >= 25.0 ||
        asymmetry >= 4.5 ||
        telemetry.crossShaftTorqueNewtonMetres >= 70.0) {
      return LandingGearAuditResult(
        vehicleId: vehicleId,
        status: LandingGearLoadSplayStatus.splaySettlementWarning,
        totalLoadTonnes: totalLoad,
        loadAsymmetryTonnes: asymmetry,
        splayDegrees: telemetry.angularSplayDegrees,
        groundSettlementMm: telemetry.asphaltFootingPenetrationMm,
        safetyAdvisory:
            'WARNING: Landing leg settlement into unpaved pavement or cross-shaft binding (Asymmetry: ${asymmetry.toStringAsFixed(1)} tonnes). Deploy hardwood outrigger shoe pads and inspect diagonal brace bars.',
      );
    }

    // 3. Normal plumb stability
    return LandingGearAuditResult(
      vehicleId: vehicleId,
      status: LandingGearLoadSplayStatus.plumbAndStable,
      totalLoadTonnes: totalLoad,
      loadAsymmetryTonnes: asymmetry,
      splayDegrees: telemetry.angularSplayDegrees,
      groundSettlementMm: telemetry.asphaltFootingPenetrationMm,
      safetyAdvisory:
          'NOMINAL: Landing gear legs are plumb, vertical loads are balanced, and ground footing pads report firm soil bearing capacity.',
    );
  }
}
