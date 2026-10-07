/// Dangerous Goods (DG) Class per UN Model Regulations.
enum DgClassCode {
  class1Explosives,
  class2Gases,
  class3FlammableLiquids,
  class4FlammableSolids,
  class5Oxidizers,
  class6ToxicAndInfectious,
  class7Radioactive,
  class8Corrosives,
  class9Miscellaneous,
}

/// A DG package or bulk parcel loaded on a transport unit.
class HazmatPackage {
  final String unNumber; // e.g. "UN1203" (Gasoline)
  final String properShippingName;
  final DgClassCode primaryClass;
  final DgClassCode? subsidiaryRisk;
  final double quantityKg;
  final bool isPackingGroup1;

  const HazmatPackage({
    required this.unNumber,
    required this.properShippingName,
    required this.primaryClass,
    this.subsidiaryRisk,
    required this.quantityKg,
    this.isPackingGroup1 = false,
  });
}

/// Pairwise segregation conflict evaluation between incompatible classes.
class IncompatibilityConflict {
  final String unNumberA;
  final String unNumberB;
  final String reason;
  final String statutoryRegulationRef;

  const IncompatibilityConflict({
    required this.unNumberA,
    required this.unNumberB,
    required this.reason,
    required this.statutoryRegulationRef,
  });
}

/// Dangerous goods co-loading compliance audit result.
class HazmatSegregationAuditResult {
  final String vehicleOrTrailerId;
  final bool isCoLoadingPermitted;
  final List<IncompatibilityConflict> segregationConflicts;
  final double totalHazmatWeightKg;
  final bool isPlacardingMandatory;
  final String segregationSummary;

  const HazmatSegregationAuditResult({
    required this.vehicleOrTrailerId,
    required this.isCoLoadingPermitted,
    required this.segregationConflicts,
    required this.totalHazmatWeightKg,
    required this.isPlacardingMandatory,
    required this.segregationSummary,
  });

  bool get isSafe => isCoLoadingPermitted && segregationConflicts.isEmpty;
}

/// Dangerous Goods Co-Loading Incompatibility & Segregation Matrix Auditor Service.
class HazmatSegregationAuditorService {
  const HazmatSegregationAuditorService();

  static const double placardingWeightThresholdKg = 454.0; // 1,000 lbs threshold

  HazmatSegregationAuditResult auditCoLoading({
    required String vehicleOrTrailerId,
    required List<HazmatPackage> packages,
  }) {
    if (packages.length <= 1) {
      final totalKg = packages.isNotEmpty ? packages.first.quantityKg : 0.0;
      return HazmatSegregationAuditResult(
        vehicleOrTrailerId: vehicleOrTrailerId,
        isCoLoadingPermitted: true,
        segregationConflicts: [],
        totalHazmatWeightKg: totalKg,
        isPlacardingMandatory: totalKg >= placardingWeightThresholdKg,
        segregationSummary: 'Single or zero hazardous materials packages. No co-loading conflicts.',
      );
    }

    final conflicts = <IncompatibilityConflict>[];
    double totalWeight = 0.0;

    for (int i = 0; i < packages.length; i++) {
      totalWeight += packages[i].quantityKg;
      for (int j = i + 1; j < packages.length; j++) {
        final a = packages[i];
        final b = packages[j];

        // Conflict Rules:
        // Rule 1: Class 1 (Explosives) cannot co-load with Class 3 (Flammable Liquids) or Class 5 (Oxidizers)
        if (a.primaryClass == DgClassCode.class1Explosives &&
            (b.primaryClass == DgClassCode.class3FlammableLiquids || b.primaryClass == DgClassCode.class5Oxidizers)) {
          conflicts.add(IncompatibilityConflict(
            unNumberA: a.unNumber,
            unNumberB: b.unNumber,
            reason: 'Explosives (Class 1) strictly prohibited from co-loading with Flammables or Oxidizers.',
            statutoryRegulationRef: '49 CFR 177.848(e) Table 1',
          ));
        }

        // Rule 2: Class 3 (Flammable Liquids) cannot co-load with Class 5.1 (Oxidizers)
        if ((a.primaryClass == DgClassCode.class3FlammableLiquids && b.primaryClass == DgClassCode.class5Oxidizers) ||
            (b.primaryClass == DgClassCode.class3FlammableLiquids && a.primaryClass == DgClassCode.class5Oxidizers)) {
          conflicts.add(IncompatibilityConflict(
            unNumberA: a.unNumber,
            unNumberB: b.unNumber,
            reason: 'Flammable Liquids and Strong Oxidizers react vigorously upon contact.',
            statutoryRegulationRef: 'IMDG Code Section 7.2.4',
          ));
        }

        // Rule 3: Class 8 (Corrosives - Cyanides/Acids) cannot co-load with toxic gas generators
        if (a.primaryClass == DgClassCode.class8Corrosives && b.primaryClass == DgClassCode.class6ToxicAndInfectious) {
          conflicts.add(IncompatibilityConflict(
            unNumberA: a.unNumber,
            unNumberB: b.unNumber,
            reason: 'Corrosives and Toxic poisons require separate compartments to prevent vapor hazard.',
            statutoryRegulationRef: 'ADR Chapter 7.5.2',
          ));
        }
      }
    }

    final permitted = conflicts.isEmpty;
    String summary;
    if (permitted) {
      summary = 'CO-LOADING APPROVED: All dangerous goods classes compatible under segregation table.';
    } else {
      summary = 'SEGREGATION VIOLATION: ${conflicts.length} incompatible DG classes detected. Separate transport units required.';
    }

    return HazmatSegregationAuditResult(
      vehicleOrTrailerId: vehicleOrTrailerId,
      isCoLoadingPermitted: permitted,
      segregationConflicts: conflicts,
      totalHazmatWeightKg: double.parse(totalWeight.toStringAsFixed(1)),
      isPlacardingMandatory: totalWeight >= placardingWeightThresholdKg,
      segregationSummary: summary,
    );
  }
}
