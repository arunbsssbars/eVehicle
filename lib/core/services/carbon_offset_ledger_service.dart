import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// A verified carbon offset credit batch retired on a public registry (e.g. Verra, Gold Standard).
class OffsetCreditBatch {
  final String batchId;
  final String projectName;
  final double metricTonsOffset;
  final double pricePerTonUsd;
  final DateTime retirementDate;
  final String registrySerialNumber;

  const OffsetCreditBatch({
    required this.batchId,
    required this.projectName,
    required this.metricTonsOffset,
    required this.pricePerTonUsd,
    required this.retirementDate,
    required this.registrySerialNumber,
  });

  /// Computes a tamper-evident SHA-256 hash for corporate ESG auditor verification.
  String generateCertificateHash() {
    final payload = '$batchId:$registrySerialNumber:$metricTonsOffset:${retirementDate.toIso8601String()}';
    return sha256.convert(utf8.encode(payload)).toString().substring(0, 16);
  }
}

/// Consolidated ESG Scope 1 fleet emissions and offset ledger audit.
class EsgCarbonLedgerAudit {
  final double grossEmissionsTonsCo2;
  final double totalOffsetTonsCo2;
  final double netEmissionsTonsCo2;
  final double offsetCoveragePercentage;
  final double totalOffsetExpenditureUsd;
  final bool isCarbonNeutralCertified;
  final List<OffsetCreditBatch> retiredBatches;
  final String certificateHash;
  final String esgStatusSummary;

  const EsgCarbonLedgerAudit({
    required this.grossEmissionsTonsCo2,
    required this.totalOffsetTonsCo2,
    required this.netEmissionsTonsCo2,
    required this.offsetCoveragePercentage,
    required this.totalOffsetExpenditureUsd,
    required this.isCarbonNeutralCertified,
    required this.retiredBatches,
    required this.certificateHash,
    required this.esgStatusSummary,
  });
}

/// Enterprise Dynamic Fleet Carbon Offset & Scope 1 ESG Ledger Engine.
class CarbonOffsetLedgerService {
  const CarbonOffsetLedgerService();

  /// Calculates Scope 1 mobile emissions:
  /// Standard diesel factor: 2.68 kg CO2e / liter = 0.00268 metric tons / liter
  double computeGrossEmissions(double totalFuelLiters) {
    return totalFuelLiters * 0.00268;
  }

  /// Audits gross fleet emissions against retired certified offset batches.
  EsgCarbonLedgerAudit reconcileOffsetLedger({
    required double totalFuelLiters,
    required List<OffsetCreditBatch> creditBatches,
  }) {
    final grossTons = computeGrossEmissions(totalFuelLiters);
    double retiredTons = 0.0;
    double totalSpent = 0.0;

    for (final b in creditBatches) {
      retiredTons += b.metricTonsOffset;
      totalSpent += (b.metricTonsOffset * b.pricePerTonUsd);
    }

    final netTons = max(0.0, grossTons - retiredTons);
    final coveragePct = grossTons > 0 ? (retiredTons / grossTons) * 100.0 : 100.0;
    final isNeutral = coveragePct >= 100.0;

    // Master certificate hash combining all batch hashes
    final combinedHashes = creditBatches.map((b) => b.generateCertificateHash()).join('-');
    final masterHash = sha256.convert(utf8.encode(combinedHashes.isNotEmpty ? combinedHashes : 'ZERO_OFFSETS')).toString().substring(0, 16).toUpperCase();

    String summary;
    if (isNeutral) {
      summary = 'VERIFIED NET-ZERO: Scope 1 fleet emissions 100% neutralized under GHG Protocol standards.';
    } else if (coveragePct >= 50.0) {
      summary = 'PARTIAL OFFSET: ${coveragePct.toStringAsFixed(1)}% of fleet carbon sequestered. Additional credits required.';
    } else {
      summary = 'LOW OFFSET COVERAGE: High residual Scope 1 carbon footprint (${netTons.toStringAsFixed(2)} tCO₂e).';
    }

    return EsgCarbonLedgerAudit(
      grossEmissionsTonsCo2: double.parse(grossTons.toStringAsFixed(2)),
      totalOffsetTonsCo2: double.parse(retiredTons.toStringAsFixed(2)),
      netEmissionsTonsCo2: double.parse(netTons.toStringAsFixed(2)),
      offsetCoveragePercentage: double.parse(coveragePct.clamp(0.0, 100.0).toStringAsFixed(1)),
      totalOffsetExpenditureUsd: double.parse(totalSpent.toStringAsFixed(2)),
      isCarbonNeutralCertified: isNeutral,
      retiredBatches: creditBatches,
      certificateHash: masterHash,
      esgStatusSummary: summary,
    );
  }
}
