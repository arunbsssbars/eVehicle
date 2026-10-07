import 'dart:math';

/// A completed domestic cabotage leg inside a foreign country.
class DomesticCabotageTrip {
  final String tripId;
  final String originCity;
  final String destinationCity;
  final DateTime completionTimestamp;
  final double cargoWeightKg;

  const DomesticCabotageTrip({
    required this.tripId,
    required this.originCity,
    required this.destinationCity,
    required this.completionTimestamp,
    required this.cargoWeightKg,
  });
}

/// Consolidated audit of international transit, cabotage operations, and customs seals.
class CabotageAuditResult {
  final String hostCountry;
  final DateTime internationalEntryDate;
  final int completedOperationsCount;
  final int maxAllowedOperations; // Statutory limit is 3 operations
  final int remainingAllowedOperations;
  final bool isWithin7DayWindow;
  final bool isCoolingOffPeriodActive;
  final bool isCustomsSealVerified;
  final bool isLegallyCompliant;
  final String complianceAdvisory;

  const CabotageAuditResult({
    required this.hostCountry,
    required this.internationalEntryDate,
    required this.completedOperationsCount,
    required this.maxAllowedOperations,
    required this.remainingAllowedOperations,
    required this.isWithin7DayWindow,
    required this.isCoolingOffPeriodActive,
    required this.isCustomsSealVerified,
    required this.isLegallyCompliant,
    required this.complianceAdvisory,
  });
}

/// Enterprise Cross-Border Customs & Cabotage Regulatory Compliance Engine.
class CrossBorderComplianceService {
  const CrossBorderComplianceService();

  /// Evaluates statutory cabotage quotas under EU / US-Mexico-Canada cross-border rules:
  /// Rule: Max 3 domestic cabotage operations within 7 consecutive days of international inbound delivery.
  CabotageAuditResult evaluateCabotage({
    required String hostCountry,
    required DateTime internationalEntryDate,
    required List<DomesticCabotageTrip> completedCabotageTrips,
    required DateTime currentTimestamp,
    String? declaredCustomsSeal,
    String? observedCustomsSeal,
  }) {
    final daysElapsed = currentTimestamp.difference(internationalEntryDate).inDays;
    final isWithinWindow = daysElapsed >= 0 && daysElapsed <= 7;
    final opCount = completedCabotageTrips.length;
    const maxOps = 3;
    final remaining = max(0, maxOps - opCount);

    final sealVerified = declaredCustomsSeal != null &&
        observedCustomsSeal != null &&
        declaredCustomsSeal.trim() == observedCustomsSeal.trim();

    // Cooling off period: 4 days required after completing 3 operations before re-entry
    final coolingOff = opCount >= maxOps || !isWithinWindow;
    final isCompliant = isWithinWindow && opCount <= maxOps && sealVerified;

    String advisory;
    if (!sealVerified) {
      advisory = 'CUSTOMS VIOLATION: Cargo security seal mismatch or broken tamper seal. Detain for inspection.';
    } else if (opCount > maxOps) {
      advisory = 'ILLEGAL CABOTAGE BREACH: Exceeded statutory limit of 3 domestic operations. Regulatory fine imminent.';
    } else if (!isWithinWindow) {
      advisory = 'WINDOW EXPIRED: 7-day post-border entry period elapsed. Mandatory 4-day cooling off period applies.';
    } else {
      advisory = 'PERMITTED: $remaining cabotage domestic operations remaining in $hostCountry until day ${7 - daysElapsed}.';
    }

    return CabotageAuditResult(
      hostCountry: hostCountry,
      internationalEntryDate: internationalEntryDate,
      completedOperationsCount: opCount,
      maxAllowedOperations: maxOps,
      remainingAllowedOperations: remaining,
      isWithin7DayWindow: isWithinWindow,
      isCoolingOffPeriodActive: coolingOff,
      isCustomsSealVerified: sealVerified,
      isLegallyCompliant: isCompliant,
      complianceAdvisory: advisory,
    );
  }
}
