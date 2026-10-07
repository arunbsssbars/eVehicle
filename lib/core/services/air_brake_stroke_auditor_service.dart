/// Operational condition of the automatic slack adjuster and foundation brake drum.
enum SlackAdjusterStatus {
  withinDotSafetyLimit,
  nearingAdjustmentThreshold,
  outOfAdjustmentDanger,
}

/// S-Cam brake chamber telemetry reading.
class AirBrakeChamberTelemetry {
  final int chamberType; // e.g. Type 20, 24, 30
  final double pushrodStrokeMm; // Nominal stroke limit (Type 30: 50.8 mm / 2.0 inches)
  final double ratedStrokeLimitMm; // Max legal re-adjustment limit (Type 30: 50.8 mm)
  final double applicationAirPressurePsi; // Standard test applied at 90 - 100 PSI
  final double drumTemperatureCelsius; // Rotor/drum thermal load

  const AirBrakeChamberTelemetry({
    this.chamberType = 30,
    required this.pushrodStrokeMm,
    this.ratedStrokeLimitMm = 50.8,
    required this.applicationAirPressurePsi,
    required this.drumTemperatureCelsius,
  });

  /// Pushrod stroke ratio relative to maximum legal DOT threshold.
  double get strokeUtilizationPercent => (pushrodStrokeMm / ratedStrokeLimitMm) * 100.0;
}

/// Comprehensive foundation brake stroke audit result.
class BrakeStrokeAuditResult {
  final String vehicleId;
  final SlackAdjusterStatus status;
  final double pushrodStrokeMm;
  final double ratedStrokeLimitMm;
  final double strokeUtilizationPercent;
  final bool isDrumOverheated;
  final String safetyDirective;

  const BrakeStrokeAuditResult({
    required this.vehicleId,
    required this.status,
    required this.pushrodStrokeMm,
    required this.ratedStrokeLimitMm,
    required this.strokeUtilizationPercent,
    required this.isDrumOverheated,
    required this.safetyDirective,
  });

  bool get isSafeForHighway => status == SlackAdjusterStatus.withinDotSafetyLimit;
  bool get isOutOfServiceCondition => status == SlackAdjusterStatus.outOfAdjustmentDanger;
}

/// Service that evaluates heavy vehicle air brake pushrod stroke and slack adjuster wear.
class AirBrakeStrokeAuditorService {
  const AirBrakeStrokeAuditorService();

  BrakeStrokeAuditResult auditBrakeChamber({
    required String vehicleId,
    required AirBrakeChamberTelemetry telemetry,
  }) {
    final strokePercent = telemetry.strokeUtilizationPercent;
    final isDrumOverheated = telemetry.drumTemperatureCelsius > 280.0;

    if (telemetry.pushrodStrokeMm >= telemetry.ratedStrokeLimitMm || strokePercent >= 100.0) {
      return BrakeStrokeAuditResult(
        vehicleId: vehicleId,
        status: SlackAdjusterStatus.outOfAdjustmentDanger,
        pushrodStrokeMm: telemetry.pushrodStrokeMm,
        ratedStrokeLimitMm: telemetry.ratedStrokeLimitMm,
        strokeUtilizationPercent: strokePercent,
        isDrumOverheated: isDrumOverheated,
        safetyDirective:
            'OUT OF SERVICE (OOS): Brake pushrod stroke exceeds DOT legal readjustment limit. Severe brake fade and loss of stopping distance.',
      );
    }

    if (strokePercent >= 85.0 || isDrumOverheated) {
      return BrakeStrokeAuditResult(
        vehicleId: vehicleId,
        status: SlackAdjusterStatus.nearingAdjustmentThreshold,
        pushrodStrokeMm: telemetry.pushrodStrokeMm,
        ratedStrokeLimitMm: telemetry.ratedStrokeLimitMm,
        strokeUtilizationPercent: strokePercent,
        isDrumOverheated: isDrumOverheated,
        safetyDirective:
            'WARNING: Slack adjuster stroke at 85%+ threshold or drum hot. Inspect automatic slack adjuster pawl and s-cam bushings.',
      );
    }

    return BrakeStrokeAuditResult(
      vehicleId: vehicleId,
      status: SlackAdjusterStatus.withinDotSafetyLimit,
      pushrodStrokeMm: telemetry.pushrodStrokeMm,
      ratedStrokeLimitMm: telemetry.ratedStrokeLimitMm,
      strokeUtilizationPercent: strokePercent,
      isDrumOverheated: false,
      safetyDirective:
          'NOMINAL: Pushrod stroke within compliant DOT commercial foundation brake limits.',
    );
  }
}
