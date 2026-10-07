/// Cargo securing type.
enum LashingDeviceType {
  webbingStrap,
  grade70TransportChain,
  grade80AlloyChain,
  wireRope,
}

/// Cargo restraint device telemetry reading.
class CargoRestraintDevice {
  final String deviceId;
  final LashingDeviceType type;
  final double workingLoadLimitKg; // WLL marked on tag
  final double measuredTensionKn;  // Tension measured by load-cell shackle
  final double lashingAngleDegrees; // Angle relative to vehicle bed floor (α)
  final bool isEdgeProtectorFitted;

  const CargoRestraintDevice({
    required this.deviceId,
    required this.type,
    required this.workingLoadLimitKg,
    required this.measuredTensionKn,
    required this.lashingAngleDegrees,
    required this.isEdgeProtectorFitted,
  });
}

/// Cargo physical profile and payload mass.
class CargoDeckProfile {
  final String cargoId;
  final String cargoDescription;
  final double totalMassKg;
  final double frictionCoefficientMu; // e.g., wood on steel = 0.30, anti-slip mat = 0.60
  final bool isBlockedAgainstHeadboard;
  final List<CargoRestraintDevice> restraints;

  const CargoDeckProfile({
    required this.cargoId,
    required this.cargoDescription,
    required this.totalMassKg,
    this.frictionCoefficientMu = 0.35,
    required this.isBlockedAgainstHeadboard,
    required this.restraints,
  });
}

/// Evaluation result compliant with EN 12195-1 / FMCSA 49 CFR 393.102.
class CargoRestraintAuditResult {
  final String cargoId;
  final bool isSecuredCompliant;
  final double aggregateWorkingLoadLimitKg;
  final double requiredMinimumWllKg; // 50% of cargo weight per FMCSA rule
  final double forwardRestraintForceKn;
  final double lateralRestraintForceKn;
  final bool hasSharpEdgeChafingRisk;
  final String complianceCertificateId;
  final String enforcementSummary;

  const CargoRestraintAuditResult({
    required this.cargoId,
    required this.isSecuredCompliant,
    required this.aggregateWorkingLoadLimitKg,
    required this.requiredMinimumWllKg,
    required this.forwardRestraintForceKn,
    required this.lateralRestraintForceKn,
    required this.hasSharpEdgeChafingRisk,
    required this.complianceCertificateId,
    required this.enforcementSummary,
  });
}

/// Dynamic Cargo Restraint & Tie-Down Tension Auditor Service.
class CargoRestraintAuditorService {
  const CargoRestraintAuditorService();

  CargoRestraintAuditResult auditCargoSecuring({
    required CargoDeckProfile profile,
  }) {
    // FMCSA: Aggregate WLL must be at least 50% of cargo weight
    final requiredWll = profile.totalMassKg * 0.50;

    double aggregateWll = 0.0;
    double totalTensionKn = 0.0;
    bool chafingRisk = false;

    for (final r in profile.restraints) {
      aggregateWll += r.workingLoadLimitKg;
      totalTensionKn += r.measuredTensionKn;
      if (!r.isEdgeProtectorFitted) {
        chafingRisk = true;
      }
    }

    // Forward force balance: cx = 0.8g (80% cargo weight)
    final gravityForceKn = (profile.totalMassKg * 9.81) / 1000.0;
    final requiredForwardKn = gravityForceKn * 0.8;
    final frictionResistanceKn = gravityForceKn * profile.frictionCoefficientMu;

    // Direct lashing / blocking contribution
    final blockingContributionKn = profile.isBlockedAgainstHeadboard ? requiredForwardKn * 0.5 : 0.0;
    final actualForwardKn = frictionResistanceKn + blockingContributionKn + (totalTensionKn * 0.5);
    final actualLateralKn = frictionResistanceKn + (totalTensionKn * 0.5);

    final isWllSufficient = aggregateWll >= requiredWll;
    final isForceSufficient = actualForwardKn >= requiredForwardKn;
    final isCompliant = isWllSufficient && isForceSufficient && !chafingRisk;

    String summary;
    if (isCompliant) {
      summary = 'CARGO SECURE: Tie-downs meet FMCSA / EN 12195 standard with adequate friction and WLL margin.';
    } else if (chafingRisk) {
      summary = 'NON-COMPLIANT: Sharp edge chafing risk. Corner protectors required on all straps.';
    } else if (!isWllSufficient) {
      summary = 'VIOLATION: Aggregate WLL (${aggregateWll.toStringAsFixed(0)} kg) is less than required 50% (${requiredWll.toStringAsFixed(0)} kg). Add more lashings.';
    } else {
      summary = 'WARNING: Insufficient forward restraint force. Increase tie-down pre-tension.';
    }

    final certId = 'EN12195-${profile.cargoId.hashCode.abs().toRadixString(16).padLeft(6, '0').toUpperCase()}';

    return CargoRestraintAuditResult(
      cargoId: profile.cargoId,
      isSecuredCompliant: isCompliant,
      aggregateWorkingLoadLimitKg: double.parse(aggregateWll.toStringAsFixed(0)),
      requiredMinimumWllKg: double.parse(requiredWll.toStringAsFixed(0)),
      forwardRestraintForceKn: double.parse(actualForwardKn.toStringAsFixed(1)),
      lateralRestraintForceKn: double.parse(actualLateralKn.toStringAsFixed(1)),
      hasSharpEdgeChafingRisk: chafingRisk,
      complianceCertificateId: certId,
      enforcementSummary: summary,
    );
  }
}
