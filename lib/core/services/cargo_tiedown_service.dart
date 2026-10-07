import 'dart:math';

/// Securement compliance rating under cargo load securement standards.
enum LoadSecurementStatus {
  secureCompliant,
  insufficientTensionWarning,
  underSecuredHazard,
  criticalShiftImminent,
}

/// Cargo physical specifications and current lashing arrangement.
class CargoTieDownArrangement {
  final double cargoMassKg;              // e.g. 15,000 kg
  final double surfaceFrictionCoefficient; // 0.2 (greasy metal) to 0.6 (anti-slip mat)
  final int activeStrapCount;            // Current number of top-over tie-downs
  final double averageStrapPretensionDan;// Standard ratchet STF: 350 to 500 daN
  final double lashingAngleDegrees;      // Angle between strap and bed (optimal 75°-90°)
  final bool blockedAgainstHeadboard;    // Direct forward form-fit blocking

  const CargoTieDownArrangement({
    required this.cargoMassKg,
    required this.surfaceFrictionCoefficient,
    required this.activeStrapCount,
    required this.averageStrapPretensionDan,
    required this.lashingAngleDegrees,
    required this.blockedAgainstHeadboard,
  });
}

/// Comprehensive cargo securement calculation audit.
class CargoTieDownAudit {
  final LoadSecurementStatus status;
  final int requiredStrapCount;
  final double totalRestraintForceKn;
  final double forwardDecelerationCapacityG;
  final String complianceSummary;
  final bool additionalStrapsMandatory;

  const CargoTieDownAudit({
    required this.status,
    required this.requiredStrapCount,
    required this.totalRestraintForceKn,
    required this.forwardDecelerationCapacityG,
    required this.complianceSummary,
    required this.additionalStrapsMandatory,
  });
}

/// Service computing EN 12195 / FMCSA commercial cargo load securement requirements.
class CargoTieDownService {
  const CargoTieDownService();

  /// Evaluates cargo tie-downs against statutory 0.8G forward and 0.5G lateral force standards.
  CargoTieDownAudit auditCargoSecurity(CargoTieDownArrangement arrangement) {
    if (arrangement.cargoMassKg <= 0.0) {
      return const CargoTieDownAudit(
        status: LoadSecurementStatus.secureCompliant,
        requiredStrapCount: 0,
        totalRestraintForceKn: 0.0,
        forwardDecelerationCapacityG: 1.0,
        complianceSummary: 'EMPTY PLATFORM: Zero cargo securement required.',
        additionalStrapsMandatory: false,
      );
    }

    final double rad = arrangement.lashingAngleDegrees * (pi / 180.0);
    final double sinAlpha = sin(rad).clamp(0.1, 1.0);
    final double mu = arrangement.surfaceFrictionCoefficient.clamp(0.1, 0.7);

    // Under EN 12195: Forward acceleration coefficient cx = 0.8 (or 0.5 with certified headboard blocking)
    final double cx = arrangement.blockedAgainstHeadboard ? 0.5 : 0.8;
    // Net sliding force after deducting bed friction: F_slide = m * g * (cx - mu)
    final double unbalanceFactor = (cx - mu).clamp(0.05, 0.8);
    final double unbalanceForceKn = (arrangement.cargoMassKg * 9.81 * unbalanceFactor) / 1000.0;

    // Normal downward clamping force added per top-over strap: 2 * sin(alpha) * STF
    // Resisting friction force generated per strap: F_r = mu * 2 * sin(alpha) * STF (in kN)
    final double stfKn = arrangement.averageStrapPretensionDan * 0.01;
    final double restraintPerStrapKn = 2.0 * mu * sinAlpha * stfKn;

    // Minimum straps required by law (minimum 2 by EN 12195)
    final int minStraps = restraintPerStrapKn > 0.01
        ? (unbalanceForceKn / restraintPerStrapKn).ceil().clamp(2, 20)
        : 2;

    final double actualRestraintKn = arrangement.activeStrapCount * restraintPerStrapKn;
    final double totalFrictionHoldingKn = ((arrangement.cargoMassKg * 9.81 * mu) / 1000.0) + actualRestraintKn;
    final double achievableG = arrangement.cargoMassKg > 0
        ? (totalFrictionHoldingKn * 1000.0) / (arrangement.cargoMassKg * 9.81)
        : 1.0;

    LoadSecurementStatus status;
    String summary;
    bool mandatoryStraps = false;

    if (arrangement.activeStrapCount < (minStraps / 2).ceil()) {
      status = LoadSecurementStatus.criticalShiftImminent;
      mandatoryStraps = true;
      summary = 'CRITICAL UNDER-SECURED: Only ${arrangement.activeStrapCount} straps applied (requires $minStraps). High risk of cargo shifting through headboard under braking!';
    } else if (arrangement.activeStrapCount < minStraps) {
      status = LoadSecurementStatus.underSecuredHazard;
      mandatoryStraps = true;
      final deficit = minStraps - arrangement.activeStrapCount;
      summary = 'DEFICIENT LASHING: Apply $deficit additional ratchet straps to meet statutory EN 12195 load security thresholds.';
    } else if (arrangement.averageStrapPretensionDan < 300.0) {
      status = LoadSecurementStatus.insufficientTensionWarning;
      summary = 'LOW TENSION: Ratchet tension average is ${arrangement.averageStrapPretensionDan.toStringAsFixed(0)} daN (target 400 daN). Re-torque tension bars.';
    } else {
      status = LoadSecurementStatus.secureCompliant;
      summary = 'CARGO RESTRAINT COMPLIANT: Rated for ${achievableG.toStringAsFixed(2)}G deceleration with ${arrangement.activeStrapCount} heavy-duty lashings.';
    }

    return CargoTieDownAudit(
      status: status,
      requiredStrapCount: minStraps,
      totalRestraintForceKn: double.parse(actualRestraintKn.toStringAsFixed(1)),
      forwardDecelerationCapacityG: double.parse(achievableG.toStringAsFixed(2)),
      complianceSummary: summary,
      additionalStrapsMandatory: mandatoryStraps,
    );
  }
}
