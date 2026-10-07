enum ConflictResolutionStrategy {
  lastWriteWins('Last-Write-Wins (Timestamp)'),
  fieldLevelMerge('Field-Level Deterministic Merge'),
  serverWins('Server Authoritative Override'),
  clientWins('Client Offline Priority');

  final String label;
  const ConflictResolutionStrategy(this.label);
}

enum SyncConflictStatus {
  detected,
  autoResolved,
  manualInterventionRequired;
}

/// Represents an offline synchronization conflict between local storage and cloud database
class SyncConflictRecord {
  final String id;
  final String entityId;
  final String entityType;
  final int localVersion;
  final int serverVersion;
  final DateTime localTimestamp;
  final DateTime serverTimestamp;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final ConflictResolutionStrategy resolutionStrategy;
  final Map<String, dynamic>? resolvedData;
  final SyncConflictStatus status;
  final String? resolutionSummary;

  const SyncConflictRecord({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.localVersion,
    required this.serverVersion,
    required this.localTimestamp,
    required this.serverTimestamp,
    required this.localData,
    required this.serverData,
    required this.resolutionStrategy,
    this.resolvedData,
    this.status = SyncConflictStatus.detected,
    this.resolutionSummary,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityId': entityId,
      'entityType': entityType,
      'localVersion': localVersion,
      'serverVersion': serverVersion,
      'localTimestamp': localTimestamp.toIso8601String(),
      'serverTimestamp': serverTimestamp.toIso8601String(),
      'localData': localData,
      'serverData': serverData,
      'resolutionStrategy': resolutionStrategy.name,
      'resolvedData': resolvedData,
      'status': status.name,
      'resolutionSummary': resolutionSummary,
    };
  }

  factory SyncConflictRecord.fromJson(Map<String, dynamic> json) {
    return SyncConflictRecord(
      id: json['id'] as String,
      entityId: json['entityId'] as String,
      entityType: json['entityType'] as String,
      localVersion: json['localVersion'] as int,
      serverVersion: json['serverVersion'] as int,
      localTimestamp: DateTime.parse(json['localTimestamp'] as String),
      serverTimestamp: DateTime.parse(json['serverTimestamp'] as String),
      localData: json['localData'] as Map<String, dynamic>,
      serverData: json['serverData'] as Map<String, dynamic>,
      resolutionStrategy: ConflictResolutionStrategy.values.firstWhere(
        (s) => s.name == json['resolutionStrategy'],
        orElse: () => ConflictResolutionStrategy.lastWriteWins,
      ),
      resolvedData: json['resolvedData'] as Map<String, dynamic>?,
      status: SyncConflictStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SyncConflictStatus.detected,
      ),
      resolutionSummary: json['resolutionSummary'] as String?,
    );
  }
}
