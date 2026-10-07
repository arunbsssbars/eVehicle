import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Enterprise application roles
enum UserEnterpriseRole {
  superAdmin('Super Admin', 'Platform Master & Multi-Tenant Authority', 0xFF7C3AED),
  companyAdmin('Company Admin', 'Fleet & Driver Management', 0xFF004AC6),
  manager('Department Manager', 'Operational Approvals & Dispatch', 0xFF0284C7),
  driver('Field Driver', 'Trip Execution & Telemetry Logging', 0xFF16A34A),
  auditor('Independent Auditor', 'Read-Only Regulatory & Cryptographic Inspector', 0xFFEA580C);

  final String title;
  final String description;
  final int colorValue;
  const UserEnterpriseRole(this.title, this.description, this.colorValue);
}

/// Granular capability permissions
enum AppPermission {
  approveJourneys,
  rejectJourneys,
  lockRecords,
  deleteRecords,
  manageVehicles,
  manageDrivers,
  viewFinancials,
  exportData,
  verifyCryptographicChain,
  overrideTamperFlag,
}

/// Immutable cryptographic audit log entry in a chained ledger
class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String actorId;
  final String action;
  final String entityId;
  final String previousHash;
  final String currentHash;

  const AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.actorId,
    required this.action,
    required this.entityId,
    required this.previousHash,
    required this.currentHash,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'actor_id': actorId,
        'action': action,
        'entity_id': entityId,
        'previous_hash': previousHash,
        'current_hash': currentHash,
      };

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        actorId: json['actor_id'] as String,
        action: json['action'] as String,
        entityId: json['entity_id'] as String,
        previousHash: json['previous_hash'] as String,
        currentHash: json['current_hash'] as String,
      );
}

/// Service governing enterprise authorization guards and tamper-proof audit hash chaining
class RbacGuardService {
  /// Check if a given role has a specific capability permission
  static bool hasPermission(UserEnterpriseRole role, AppPermission permission) {
    switch (role) {
      case UserEnterpriseRole.superAdmin:
        return true; // Super admin has all permissions

      case UserEnterpriseRole.companyAdmin:
        return permission != AppPermission.overrideTamperFlag;

      case UserEnterpriseRole.manager:
        return permission == AppPermission.approveJourneys ||
            permission == AppPermission.rejectJourneys ||
            permission == AppPermission.exportData;

      case UserEnterpriseRole.driver:
        return false; // Field drivers log journeys but cannot approve, delete or manage others

      case UserEnterpriseRole.auditor:
        return permission == AppPermission.exportData ||
            permission == AppPermission.verifyCryptographicChain;
    }
  }

  /// Genesis block hash for starting the ledger chain
  static const String genesisHash = '0000000000000000000000000000000000000000000000000000000000000000';

  /// Calculate SHA-256 hash for an audit log entry chained to previous hash
  static String calculateEntryHash({
    required String previousHash,
    required DateTime timestamp,
    required String actorId,
    required String action,
    required String entityId,
  }) {
    final payload = '$previousHash|${timestamp.toIso8601String()}|$actorId|$action|$entityId';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  /// Create a new cryptographically chained audit log entry
  static AuditLogEntry createChainedEntry({
    required String id,
    required String actorId,
    required String action,
    required String entityId,
    required String previousHash,
    DateTime? timestamp,
  }) {
    final ts = timestamp ?? DateTime.now();
    final currentHash = calculateEntryHash(
      previousHash: previousHash,
      timestamp: ts,
      actorId: actorId,
      action: action,
      entityId: entityId,
    );

    return AuditLogEntry(
      id: id,
      timestamp: ts,
      actorId: actorId,
      action: action,
      entityId: entityId,
      previousHash: previousHash,
      currentHash: currentHash,
    );
  }

  /// Verify complete cryptographic integrity of an audit ledger chain
  /// Returns true if all hashes are valid and perfectly linked, false if tampered
  static bool verifyChainIntegrity(List<AuditLogEntry> chain) {
    if (chain.isEmpty) return true;

    for (int i = 0; i < chain.length; i++) {
      final entry = chain[i];

      // Check previous hash linkage
      if (i == 0) {
        if (entry.previousHash != genesisHash) return false;
      } else {
        if (entry.previousHash != chain[i - 1].currentHash) return false;
      }

      // Check current hash authenticity
      final expectedHash = calculateEntryHash(
        previousHash: entry.previousHash,
        timestamp: entry.timestamp,
        actorId: entry.actorId,
        action: entry.action,
        entityId: entry.entityId,
      );

      if (entry.currentHash != expectedHash) return false;
    }

    return true;
  }
}
