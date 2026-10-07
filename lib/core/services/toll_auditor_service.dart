/// Electronic toll gantry / plaza passage record.
class TollPlazaPassage {
  final String plazaId;
  final String plazaName;
  final String highwayCode; // e.g. 'NH-48', 'NE-4'
  final DateTime passageTime;
  final double billedAmount;
  final double standardSingleFare;
  final double standardReturnFare24h;
  final String vehicleClassCharged; // e.g., 'Car/Jeep', 'LCV', 'Bus/Truck 2-Axle', 'MAV 3-Axle'
  final String registeredVehicleClass;

  const TollPlazaPassage({
    required this.plazaId,
    required this.plazaName,
    required this.highwayCode,
    required this.passageTime,
    required this.billedAmount,
    required this.standardSingleFare,
    required this.standardReturnFare24h,
    required this.vehicleClassCharged,
    required this.registeredVehicleClass,
  });
}

/// Discrepancy or overcharge flag identified by auditor.
class TollDiscrepancy {
  final String plazaName;
  final DateTime passageTime;
  final double expectedFare;
  final double actualBilledFare;
  final double refundEntitlement;
  final String issueDescription;

  const TollDiscrepancy({
    required this.plazaName,
    required this.passageTime,
    required this.expectedFare,
    required this.actualBilledFare,
    required this.refundEntitlement,
    required this.issueDescription,
  });
}

/// Comprehensive toll audit summary.
class TollAuditSummary {
  final String vehicleId;
  final String registrationNumber;
  final int totalPlazasPassed;
  final double totalBilledAmount;
  final double legitimateExpectedAmount;
  final double totalRefundEntitlement;
  final bool hasOverchargeDiscrepancies;
  final List<TollDiscrepancy> discrepancies;

  const TollAuditSummary({
    required this.vehicleId,
    required this.registrationNumber,
    required this.totalPlazasPassed,
    required this.totalBilledAmount,
    required this.legitimateExpectedAmount,
    required this.totalRefundEntitlement,
    required this.hasOverchargeDiscrepancies,
    required this.discrepancies,
  });
}

/// Automated Multi-Jurisdiction Toll Expense Calculator & ERP Auditor.
class TollAuditorService {
  const TollAuditorService();

  /// Audits electronic toll transactions against statutory tariffs and return-trip discounts.
  TollAuditSummary auditTollPassages({
    required String vehicleId,
    required String registrationNumber,
    required List<TollPlazaPassage> passages,
  }) {
    if (passages.isEmpty) {
      return TollAuditSummary(
        vehicleId: vehicleId,
        registrationNumber: registrationNumber,
        totalPlazasPassed: 0,
        totalBilledAmount: 0.0,
        legitimateExpectedAmount: 0.0,
        totalRefundEntitlement: 0.0,
        hasOverchargeDiscrepancies: false,
        discrepancies: const [],
      );
    }

    // Sort passages chronologically
    final sortedPassages = List<TollPlazaPassage>.from(passages)
      ..sort((a, b) => a.passageTime.compareTo(b.passageTime));

    double totalBilled = 0.0;
    double totalExpected = 0.0;
    double totalRefund = 0.0;
    final List<TollDiscrepancy> discrepancies = [];

    // Track plaza visits for 24-hour return trip discount
    final Map<String, DateTime> lastPlazaVisits = {};

    for (final p in sortedPassages) {
      totalBilled += p.billedAmount;
      double expectedFare = p.standardSingleFare;
      String? issue;

      // 1. Check Misclassification (Charged higher vehicle category)
      if (p.vehicleClassCharged != p.registeredVehicleClass) {
        issue = 'Miscalibrated Tag Reader: Billed as ${p.vehicleClassCharged} instead of registered ${p.registeredVehicleClass}.';
      }

      // 2. Check 24-hour return discount
      if (lastPlazaVisits.containsKey(p.plazaId)) {
        final lastTime = lastPlazaVisits[p.plazaId]!;
        final diffHours = p.passageTime.difference(lastTime).inMinutes / 60.0;
        if (diffHours <= 24.0) {
          // Qualified for return trip concession
          expectedFare = p.standardReturnFare24h - p.standardSingleFare;
          if (expectedFare < 0) expectedFare = p.standardReturnFare24h * 0.5;

          if (p.billedAmount > expectedFare && issue == null) {
            issue = 'Missed 24-Hour Return Journey Concession: Re-billed at full single rate within ${diffHours.toStringAsFixed(1)}h.';
          }
        }
      }

      totalExpected += expectedFare;
      lastPlazaVisits[p.plazaId] = p.passageTime;

      // Check if actual was greater than expected
      if (p.billedAmount > expectedFare + 1.0) {
        final refund = p.billedAmount - expectedFare;
        totalRefund += refund;
        discrepancies.add(TollDiscrepancy(
          plazaName: p.plazaName,
          passageTime: p.passageTime,
          expectedFare: double.parse(expectedFare.toStringAsFixed(2)),
          actualBilledFare: double.parse(p.billedAmount.toStringAsFixed(2)),
          refundEntitlement: double.parse(refund.toStringAsFixed(2)),
          issueDescription: issue ?? 'Unexplained Overcharge beyond statutory schedule.',
        ));
      }
    }

    return TollAuditSummary(
      vehicleId: vehicleId,
      registrationNumber: registrationNumber,
      totalPlazasPassed: passages.length,
      totalBilledAmount: double.parse(totalBilled.toStringAsFixed(2)),
      legitimateExpectedAmount: double.parse(totalExpected.toStringAsFixed(2)),
      totalRefundEntitlement: double.parse(totalRefund.toStringAsFixed(2)),
      hasOverchargeDiscrepancies: discrepancies.isNotEmpty,
      discrepancies: discrepancies,
    );
  }
}
