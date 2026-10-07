import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/vehicle_document.dart';

/// Compliance status summary for a vehicle or fleet
class DocumentComplianceSummary {
  final int totalDocuments;
  final int validCount;
  final int expiringSoonCount; // <= 30 days
  final int expiredCount;
  final bool isFullyCompliant;

  const DocumentComplianceSummary({
    required this.totalDocuments,
    required this.validCount,
    required this.expiringSoonCount,
    required this.expiredCount,
    required this.isFullyCompliant,
  });
}

/// Service managing vehicle document encryption checksums, lifecycle verification, and compliance alerts.
class DocumentVaultService {
  /// Calculate cryptographic SHA-256 checksum over byte payload
  static String calculateChecksum(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Calculate cryptographic SHA-256 checksum over string payload
  static String calculateStringChecksum(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// Verify if provided bytes match the stored SHA-256 checksum
  static bool verifyIntegrity(List<int> bytes, String expectedChecksum) {
    if (expectedChecksum.isEmpty) return false;
    final actual = calculateChecksum(bytes);
    return actual.toLowerCase() == expectedChecksum.toLowerCase();
  }

  /// Find all documents that are either expired or expiring within [daysAhead] days
  static List<VehicleDocument> getExpiringDocuments(
    List<VehicleDocument> documents, {
    int daysAhead = 30,
  }) {
    final now = DateTime.now();
    final threshold = now.add(Duration(days: daysAhead));

    final expiring = documents.where((d) {
      return d.expiryDate.isBefore(threshold);
    }).toList();

    // Sort by earliest expiry first
    expiring.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return expiring;
  }

  /// Generate a high-level compliance summary for a list of documents
  static DocumentComplianceSummary evaluateCompliance(List<VehicleDocument> documents) {
    if (documents.isEmpty) {
      return const DocumentComplianceSummary(
        totalDocuments: 0,
        validCount: 0,
        expiringSoonCount: 0,
        expiredCount: 0,
        isFullyCompliant: false,
      );
    }

    final now = DateTime.now();
    final soonThreshold = now.add(const Duration(days: 30));

    int valid = 0;
    int soon = 0;
    int expired = 0;

    for (final doc in documents) {
      if (doc.expiryDate.isBefore(now)) {
        expired++;
      } else if (doc.expiryDate.isBefore(soonThreshold)) {
        soon++;
      } else {
        valid++;
      }
    }

    return DocumentComplianceSummary(
      totalDocuments: documents.length,
      validCount: valid,
      expiringSoonCount: soon,
      expiredCount: expired,
      isFullyCompliant: expired == 0 && documents.isNotEmpty,
    );
  }
}
