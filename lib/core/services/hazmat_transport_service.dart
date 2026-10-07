/// Primary UN Hazardous Materials Classification.
enum HazmatClass {
  class1Explosives,
  class2Gases,
  class3FlammableLiquids,
  class4FlammableSolids,
  class5Oxidizing,
  class6ToxicInfectious,
  class7Radioactive,
  class8Corrosives,
  class9Miscellaneous,
}

/// Tunnel restriction category according to ADR.
enum TunnelRestrictionCode {
  codeA, // No restrictions
  codeB, // Restriction for very severe explosion hazards
  codeC, // Restriction for severe explosions and toxic releases
  codeD, // Restriction for bulk flammables and severe hazards
  codeE, // All hazardous materials prohibited except very small quantities
}

/// Cargo consignment details for hazardous freight.
class HazmatConsignment {
  final String unNumber; // e.g., 'UN 1202' (Diesel), 'UN 1075' (LPG)
  final String properShippingName;
  final HazmatClass primaryClass;
  final String packingGroup; // 'I' (high danger), 'II' (medium), 'III' (minor)
  final double netQuantityKg;
  final bool hasTremcardCarried;
  final bool hasPlacardsMounted;
  final bool isDriverAdrHazmatCertified;

  const HazmatConsignment({
    required this.unNumber,
    required this.properShippingName,
    required this.primaryClass,
    required this.packingGroup,
    required this.netQuantityKg,
    this.hasTremcardCarried = true,
    this.hasPlacardsMounted = true,
    this.isDriverAdrHazmatCertified = true,
  });
}

/// Emergency Response Guidebook (ERG) protocol for first responders.
class EmergencyResponseProtocol {
  final int ergGuideNumber;
  final int initialIsolationRadiusMeters;
  final int downwindEvacuationDayMeters;
  final int downwindEvacuationNightMeters;
  final String firefightingExtinguisher;
  final String personalProtectiveEquipment;
  final String immediateSpillAction;

  const EmergencyResponseProtocol({
    required this.ergGuideNumber,
    required this.initialIsolationRadiusMeters,
    required this.downwindEvacuationDayMeters,
    required this.downwindEvacuationNightMeters,
    required this.firefightingExtinguisher,
    required this.personalProtectiveEquipment,
    required this.immediateSpillAction,
  });
}

/// HAZMAT Transport compliance audit result.
class HazmatAuditResult {
  final HazmatConsignment consignment;
  final bool isManifestValid;
  final bool isPermittedInTunnel;
  final EmergencyResponseProtocol emergencyProtocol;
  final List<String> complianceDefects;

  const HazmatAuditResult({
    required this.consignment,
    required this.isManifestValid,
    required this.isPermittedInTunnel,
    required this.emergencyProtocol,
    required this.complianceDefects,
  });

  bool get isDispatchAuthorized => isManifestValid && complianceDefects.isEmpty;
}

/// Real-Time Hazardous Materials (HAZMAT) Transport Compliance & ERG Engine.
class HazmatTransportService {
  const HazmatTransportService();

  /// Audits hazardous freight dispatch and determines emergency response protocols.
  HazmatAuditResult auditConsignment({
    required HazmatConsignment consignment,
    TunnelRestrictionCode intendedTunnelCategory = TunnelRestrictionCode.codeA,
  }) {
    final List<String> defects = [];

    if (!consignment.hasTremcardCarried) {
      defects.add('Safety Violation: Mandatory Physical Transport Emergency Card (TREMCARD) missing.');
    }
    if (!consignment.hasPlacardsMounted) {
      defects.add('Statutory Violation: Hazard class diamond placards and orange plates not affixed.');
    }
    if (!consignment.isDriverAdrHazmatCertified) {
      defects.add('Driver Certification Gap: Driver lacks valid Dangerous Goods (ADR/HAZMAT) license endorsement.');
    }

    // Tunnel restrictions
    bool tunnelPermitted = true;
    if (intendedTunnelCategory == TunnelRestrictionCode.codeE) {
      tunnelPermitted = false;
      defects.add('Route Hazard: Tunnel Category E forbids dangerous goods transit.');
    } else if (intendedTunnelCategory == TunnelRestrictionCode.codeD &&
        (consignment.primaryClass == HazmatClass.class1Explosives ||
            consignment.primaryClass == HazmatClass.class2Gases ||
            consignment.primaryClass == HazmatClass.class3FlammableLiquids)) {
      tunnelPermitted = false;
      defects.add('Route Hazard: Tunnel Category D forbids bulk flammables/explosives.');
    }

    final protocol = _lookupEmergencyProtocol(consignment);

    return HazmatAuditResult(
      consignment: consignment,
      isManifestValid: defects.isEmpty,
      isPermittedInTunnel: tunnelPermitted,
      emergencyProtocol: protocol,
      complianceDefects: defects,
    );
  }

  EmergencyResponseProtocol _lookupEmergencyProtocol(HazmatConsignment consignment) {
    switch (consignment.primaryClass) {
      case HazmatClass.class1Explosives:
        return const EmergencyResponseProtocol(
          ergGuideNumber: 112,
          initialIsolationRadiusMeters: 500,
          downwindEvacuationDayMeters: 1000,
          downwindEvacuationNightMeters: 1600,
          firefightingExtinguisher: 'Flood with water from maximum distance. Do not move cargo.',
          personalProtectiveEquipment: 'Full positive pressure SCBA & explosion blast shield.',
          immediateSpillAction: 'Eliminate all ignition sources; clear area for 1,000 meters.',
        );
      case HazmatClass.class2Gases:
        return const EmergencyResponseProtocol(
          ergGuideNumber: 115,
          initialIsolationRadiusMeters: 100,
          downwindEvacuationDayMeters: 800,
          downwindEvacuationNightMeters: 1200,
          firefightingExtinguisher: 'Water fog or spray to cool tanks; dry chemical extinguisher.',
          personalProtectiveEquipment: 'Thermal vapor barrier and self-contained breathing apparatus.',
          immediateSpillAction: 'Isolate gas leak source if safe without personal risk.',
        );
      case HazmatClass.class3FlammableLiquids:
        return const EmergencyResponseProtocol(
          ergGuideNumber: 128,
          initialIsolationRadiusMeters: 50,
          downwindEvacuationDayMeters: 300,
          downwindEvacuationNightMeters: 500,
          firefightingExtinguisher: 'Alcohol-resistant foam (AFFF) or dry chemical powder.',
          personalProtectiveEquipment: 'Standard firefighter turnout gear and nitrile/butyl gloves.',
          immediateSpillAction: 'Contain liquid runoff with sand/earth barriers; prevent storm drain entry.',
        );
      case HazmatClass.class8Corrosives:
        return const EmergencyResponseProtocol(
          ergGuideNumber: 154,
          initialIsolationRadiusMeters: 50,
          downwindEvacuationDayMeters: 200,
          downwindEvacuationNightMeters: 400,
          firefightingExtinguisher: 'Dry chemical, CO2, or water spray.',
          personalProtectiveEquipment: 'Chemical vapor protective suit & face shield.',
          immediateSpillAction: 'Neutralize with lime/soda ash; prevent contact with bare soil/waterway.',
        );
      default:
        return const EmergencyResponseProtocol(
          ergGuideNumber: 171,
          initialIsolationRadiusMeters: 25,
          downwindEvacuationDayMeters: 100,
          downwindEvacuationNightMeters: 200,
          firefightingExtinguisher: 'Universal chemical foam or water spray.',
          personalProtectiveEquipment: 'Safety goggles and heavy-duty nitrile protective gloves.',
          immediateSpillAction: 'Absorb spill with inert binder and deposit in sealed drums.',
        );
    }
  }
}
