/// Axle position determines legal retread eligibility (ECE R109).
enum TyreAxlePosition {
  steerAxle,   // Steer axle: Retreads generally prohibited or restricted to virgin casing
  driveAxle,   // Drive axle: Max 2 retreads typically permitted
  trailerAxle, // Trailer axle: Up to 3 retreads permitted
}

/// Structural integrity status of the steel-belted tyre casing.
enum CasingIntegrityStatus {
  certifiedSound,
  casingFatigueWarning,
  steerAxleViolation,
  condemnedScrap,
}

/// Profile and inspection history of a commercial tyre casing.
class CommercialTyreCasing {
  final String casingSerial;
  final int retreadCount; // 0 = Virgin/Original tread, 1 = 1st retread, etc.
  final TyreAxlePosition axlePosition;
  final double casingIntegrityRatingPercent; // Non-destructive shearography rating (0-100%)
  final double currentTreadDepthMm;
  final double totalCasingMileageKm;

  const CommercialTyreCasing({
    required this.casingSerial,
    required this.retreadCount,
    required this.axlePosition,
    required this.casingIntegrityRatingPercent,
    required this.currentTreadDepthMm,
    required this.totalCasingMileageKm,
  });
}

/// Comprehensive casing audit and retread compliance result.
class TyreRetreadAudit {
  final CasingIntegrityStatus status;
  final bool legallyCompliant;
  final int maxAllowableRetreads;
  final int remainingRetreadCycles;
  final String complianceSummary;
  final bool requiresImmediateReplacement;

  const TyreRetreadAudit({
    required this.status,
    required this.legallyCompliant,
    required this.maxAllowableRetreads,
    required this.remainingRetreadCycles,
    required this.complianceSummary,
    required this.requiresImmediateReplacement,
  });
}

/// Service managing commercial tyre casing lifecycle, shearography inspection, and axle position rules.
class TyreRetreadTrackerService {
  const TyreRetreadTrackerService();

  /// Audits casing structural integrity and ECE R109 axle position compliance.
  TyreRetreadAudit auditCasing(CommercialTyreCasing casing) {
    int maxRetreads;
    switch (casing.axlePosition) {
      case TyreAxlePosition.steerAxle:
        maxRetreads = 0; // Virgin casing mandatory on primary steer axle
        break;
      case TyreAxlePosition.driveAxle:
        maxRetreads = 2;
        break;
      case TyreAxlePosition.trailerAxle:
        maxRetreads = 3;
        break;
    }

    final remainingCycles = (maxRetreads - casing.retreadCount).clamp(0, maxRetreads);

    // Steer axle safety violation check
    if (casing.axlePosition == TyreAxlePosition.steerAxle && casing.retreadCount > 0) {
      return const TyreRetreadAudit(
        status: CasingIntegrityStatus.steerAxleViolation,
        legallyCompliant: false,
        maxAllowableRetreads: 0,
        remainingRetreadCycles: 0,
        complianceSummary: 'CRITICAL REGULATORY VIOLATION: Retreaded tyre fitted to steer axle! Prohibited under fleet safety guidelines.',
        requiresImmediateReplacement: true,
      );
    }

    // Structural failure / belt separation check
    if (casing.casingIntegrityRatingPercent < 60.0 || casing.retreadCount > maxRetreads) {
      return TyreRetreadAudit(
        status: CasingIntegrityStatus.condemnedScrap,
        legallyCompliant: false,
        maxAllowableRetreads: maxRetreads,
        remainingRetreadCycles: 0,
        complianceSummary: 'CASING CONDEMNED: Shearography reveals internal ply separation or max retread limit exceeded. Scrap casing.',
        requiresImmediateReplacement: true,
      );
    }

    if (casing.casingIntegrityRatingPercent < 75.0 || casing.totalCasingMileageKm > 400000.0) {
      return TyreRetreadAudit(
        status: CasingIntegrityStatus.casingFatigueWarning,
        legallyCompliant: true,
        maxAllowableRetreads: maxRetreads,
        remainingRetreadCycles: remainingCycles,
        complianceSummary: 'CASING FATIGUE: High cumulative mileage (${(casing.totalCasingMileageKm / 1000).toStringAsFixed(0)}k km). Perform ultrasonic bead inspection before next buffing.',
        requiresImmediateReplacement: false,
      );
    }

    return TyreRetreadAudit(
      status: CasingIntegrityStatus.certifiedSound,
      legallyCompliant: true,
      maxAllowableRetreads: maxRetreads,
      remainingRetreadCycles: remainingCycles,
      complianceSummary: 'CASING SOUND: Structural belt integrity certified at ${casing.casingIntegrityRatingPercent.toStringAsFixed(0)}%. $remainingCycles retreads remaining.',
      requiresImmediateReplacement: false,
    );
  }
}
