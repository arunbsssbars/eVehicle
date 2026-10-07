import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/journey.dart';
import '../models/vehicle.dart';
import '../models/vehicle_document.dart';

/// Versioned, cryptographically sealed backup snapshot of tenant data
class TenantDataSnapshot {
  final int snapshotVersion;
  final String tenantId;
  final DateTime exportedAt;
  final List<Vehicle> vehicles;
  final List<Journey> journeys;
  final List<VehicleDocument> documents;
  final String sha256Signature;

  const TenantDataSnapshot({
    required this.snapshotVersion,
    required this.tenantId,
    required this.exportedAt,
    required this.vehicles,
    required this.journeys,
    required this.documents,
    required this.sha256Signature,
  });

  Map<String, dynamic> toExportJson() {
    return {
      'version': snapshotVersion,
      'tenant_id': tenantId,
      'exported_at': exportedAt.toIso8601String(),
      'vehicles': vehicles.map((v) => v.toJson()).toList(),
      'journeys': journeys.map((j) => j.toJson()).toList(),
      'documents': documents.map((d) => d.toJson()).toList(),
      'sha256_signature': sha256Signature,
    };
  }
}

/// Service handling multi-tenant backup snapshots, cryptographic signing, and safe restore
class TenantBackupService {
  static const int currentSnapshotVersion = 1;

  /// Calculate SHA-256 signature for snapshot content
  static String calculatePayloadSignature({
    required int version,
    required String tenantId,
    required String vehiclesJson,
    required String journeysJson,
    required String documentsJson,
  }) {
    final raw = '$version|$tenantId|$vehiclesJson|$journeysJson|$documentsJson';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  /// Create a complete, signed snapshot of tenant data
  static TenantDataSnapshot createSnapshot({
    required String tenantId,
    required List<Vehicle> vehicles,
    required List<Journey> journeys,
    required List<VehicleDocument> documents,
  }) {
    final vJson = jsonEncode(vehicles.map((v) => v.toJson()).toList());
    final jJson = jsonEncode(journeys.map((j) => j.toJson()).toList());
    final dJson = jsonEncode(documents.map((d) => d.toJson()).toList());

    final signature = calculatePayloadSignature(
      version: currentSnapshotVersion,
      tenantId: tenantId,
      vehiclesJson: vJson,
      journeysJson: jJson,
      documentsJson: dJson,
    );

    return TenantDataSnapshot(
      snapshotVersion: currentSnapshotVersion,
      tenantId: tenantId,
      exportedAt: DateTime.now(),
      vehicles: vehicles,
      journeys: journeys,
      documents: documents,
      sha256Signature: signature,
    );
  }

  /// Validate and restore a tenant data snapshot
  /// Returns validated [TenantDataSnapshot] or throws [FormatException] if corrupted
  static TenantDataSnapshot restoreSnapshot(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 1;
    final tenantId = json['tenant_id'] as String? ?? 'default';
    final exportedAt = DateTime.parse(json['exported_at'] as String);
    final recordedSignature = json['sha256_signature'] as String? ?? '';

    final vListRaw = json['vehicles'] as List<dynamic>? ?? [];
    final jListRaw = json['journeys'] as List<dynamic>? ?? [];
    final dListRaw = json['documents'] as List<dynamic>? ?? [];

    final vJson = jsonEncode(vListRaw);
    final jJson = jsonEncode(jListRaw);
    final dJson = jsonEncode(dListRaw);

    final expectedSignature = calculatePayloadSignature(
      version: version,
      tenantId: tenantId,
      vehiclesJson: vJson,
      journeysJson: jJson,
      documentsJson: dJson,
    );

    if (recordedSignature.toLowerCase() != expectedSignature.toLowerCase()) {
      throw const FormatException('Snapshot signature verification failed: Corrupted or tampered backup payload.');
    }

    final vehicles = vListRaw.map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
    final journeys = jListRaw.map((e) => Journey.fromJson(e as Map<String, dynamic>)).toList();
    final documents = dListRaw.map((e) => VehicleDocument.fromJson(e as Map<String, dynamic>)).toList();

    return TenantDataSnapshot(
      snapshotVersion: version,
      tenantId: tenantId,
      exportedAt: exportedAt,
      vehicles: vehicles,
      journeys: journeys,
      documents: documents,
      sha256Signature: recordedSignature,
    );
  }
}
