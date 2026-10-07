/// International UN Hazard Class division.
enum HazmatDivision {
  class1Explosives,
  class2Gases,
  class3FlammableLiquids,
  class4FlammableSolids,
  class5Oxidizers,
  class6Toxics,
  class7Radioactive,
  class8Corrosives,
  class9Miscellaneous,
}

/// ADR European & international tunnel restriction categories.
enum TunnelCategory {
  categoryA, // No restrictions
  categoryB, // Restriction for dangerous goods with very large explosion risk
  categoryC, // Restriction for large explosion risk + toxic release
  categoryD, // Restriction for dangerous goods with risk of large fire/explosion
  categoryE, // Total ban on all hazardous materials
}

/// Dangerous good shipment item in vehicle cargo.
class HazmatConsignment {
  final String unNumber; // e.g. "UN 1203" for Gasoline
  final String shippingName;
  final HazmatDivision division;
  final int packingGroup; // 1 = high danger, 2 = medium, 3 = low
  final double quantityKg;
  final String ergGuideNumber; // Emergency Response Guidebook page

  const HazmatConsignment({
    required this.unNumber,
    required this.shippingName,
    required this.division,
    this.packingGroup = 2,
    required this.quantityKg,
    required this.ergGuideNumber,
  });
}

/// Consolidated audit of hazmat placarding and tunnel passage authorization.
class HazmatRouteAudit {
  final List<HazmatConsignment> consignments;
  final double totalHazmatWeightKg;
  final TunnelCategory strictestTunnelAllowed;
  final List<String> requiredPlacards;
  final bool hasExplosivesOrToxics;
  final String emergencyResponseGuideSummary;
  final String complianceStatus;

  const HazmatRouteAudit({
    required this.consignments,
    required this.totalHazmatWeightKg,
    required this.strictestTunnelAllowed,
    required this.requiredPlacards,
    required this.hasExplosivesOrToxics,
    required this.emergencyResponseGuideSummary,
    required this.complianceStatus,
  });

  /// Validates whether this vehicle is permitted to enter a specific tunnel category.
  bool canTraverseTunnel(TunnelCategory tunnel) {
    if (consignments.isEmpty) return true;
    if (tunnel == TunnelCategory.categoryE) return false; // Cat E bans all hazmat
    // If strictest allowed is B, it cannot enter B, C, D, or E
    return tunnel.index < strictestTunnelAllowed.index;
  }
}

/// Enterprise Hazardous Materials (HAZMAT) Placarding & Tunnel Restriction Engine.
class HazmatComplianceService {
  const HazmatComplianceService();

  /// Audits cargo consignments and determines required placarding and tunnel permissions.
  HazmatRouteAudit evaluateHazmatCargo(List<HazmatConsignment> consignments) {
    if (consignments.isEmpty) {
      return const HazmatRouteAudit(
        consignments: [],
        totalHazmatWeightKg: 0.0,
        strictestTunnelAllowed: TunnelCategory.categoryE,
        requiredPlacards: [],
        hasExplosivesOrToxics: false,
        emergencyResponseGuideSummary: 'NO HAZMAT: Standard general freight.',
        complianceStatus: 'CLEARED FOR ALL TUNNELS',
      );
    }

    double totalWeight = 0.0;
    final Set<String> placards = {};
    bool hasExplosives = false;
    TunnelCategory strictest = TunnelCategory.categoryE;

    for (final c in consignments) {
      totalWeight += c.quantityKg;
      placards.add('${c.unNumber} (${_divisionName(c.division)})');

      if (c.division == HazmatDivision.class1Explosives) {
        hasExplosives = true;
        strictest = TunnelCategory.categoryB;
      } else if (c.division == HazmatDivision.class2Gases || c.division == HazmatDivision.class3FlammableLiquids) {
        if (strictest.index > TunnelCategory.categoryD.index) {
          strictest = TunnelCategory.categoryD;
        }
      } else if (c.division == HazmatDivision.class6Toxics) {
        if (strictest.index > TunnelCategory.categoryC.index) {
          strictest = TunnelCategory.categoryC;
        }
      }
    }

    final ergSummary = 'ERG Guide #${consignments.first.ergGuideNumber}: Standard initial isolation distance 100m.';

    return HazmatRouteAudit(
      consignments: consignments,
      totalHazmatWeightKg: double.parse(totalWeight.toStringAsFixed(1)),
      strictestTunnelAllowed: strictest,
      requiredPlacards: placards.toList(),
      hasExplosivesOrToxics: hasExplosives,
      emergencyResponseGuideSummary: ergSummary,
      complianceStatus: 'RESTRICTED: Tunnel Ban on Categories >= ${_tunnelName(strictest)}',
    );
  }

  String _divisionName(HazmatDivision d) {
    switch (d) {
      case HazmatDivision.class1Explosives:
        return 'Class 1 Explosives';
      case HazmatDivision.class2Gases:
        return 'Class 2 Gases';
      case HazmatDivision.class3FlammableLiquids:
        return 'Class 3 Flammables';
      case HazmatDivision.class4FlammableSolids:
        return 'Class 4 Solids';
      case HazmatDivision.class5Oxidizers:
        return 'Class 5 Oxidizers';
      case HazmatDivision.class6Toxics:
        return 'Class 6 Toxics';
      case HazmatDivision.class7Radioactive:
        return 'Class 7 Radioactive';
      case HazmatDivision.class8Corrosives:
        return 'Class 8 Corrosives';
      case HazmatDivision.class9Miscellaneous:
        return 'Class 9 Misc';
    }
  }

  String _tunnelName(TunnelCategory t) {
    switch (t) {
      case TunnelCategory.categoryA:
        return 'A (Unrestricted)';
      case TunnelCategory.categoryB:
        return 'B (Severe Explosives Ban)';
      case TunnelCategory.categoryC:
        return 'C (Toxic / Explosive Ban)';
      case TunnelCategory.categoryD:
        return 'D (Flammable Cargo Ban)';
      case TunnelCategory.categoryE:
        return 'E (Total Hazmat Ban)';
    }
  }
}
