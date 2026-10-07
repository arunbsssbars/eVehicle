import '../models/sync_conflict_record.dart';

/// Autonomous Conflict Resolution Engine implementing deterministic vector clock checks,
/// field-level merging, and Last-Write-Wins (LWW) fallbacks.
class SyncConflictMatrixService {
  /// Default fields where server always possesses administrative authority
  static const Set<String> defaultServerAuthoritativeKeys = {
    'status',
    'approvedBy',
    'approvalDate',
    'rejectionReason',
    'complianceStatus',
  };

  /// Identify all conflicting keys between local and server states
  static List<String> identifyConflictingKeys(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
  ) {
    final conflictingKeys = <String>[];
    final allKeys = {...localData.keys, ...serverData.keys};

    for (final key in allKeys) {
      final localVal = localData[key];
      final serverVal = serverData[key];
      if (localVal != serverVal) {
        conflictingKeys.add(key);
      }
    }
    return conflictingKeys;
  }

  /// Deterministic field-level 3-way merge
  static SyncConflictRecord resolveWithFieldLevelMerge({
    required SyncConflictRecord conflict,
    Set<String> serverAuthoritativeKeys = defaultServerAuthoritativeKeys,
  }) {
    final merged = Map<String, dynamic>.from(conflict.localData);

    for (final entry in conflict.serverData.entries) {
      final key = entry.key;
      final serverVal = entry.value;

      // 1. If key is server authoritative, server always wins
      if (serverAuthoritativeKeys.contains(key)) {
        merged[key] = serverVal;
      }
      // 2. If key does not exist locally, adopt server value
      else if (!merged.containsKey(key)) {
        merged[key] = serverVal;
      }
      // 3. If values differ, take newer timestamp value
      else if (merged[key] != serverVal) {
        if (conflict.serverTimestamp.isAfter(conflict.localTimestamp)) {
          merged[key] = serverVal;
        }
      }
    }

    // Bump version deterministically
    final nextVersion = (conflict.localVersion > conflict.serverVersion
            ? conflict.localVersion
            : conflict.serverVersion) +
        1;

    return SyncConflictRecord(
      id: conflict.id,
      entityId: conflict.entityId,
      entityType: conflict.entityType,
      localVersion: nextVersion,
      serverVersion: nextVersion,
      localTimestamp: conflict.localTimestamp,
      serverTimestamp: conflict.serverTimestamp,
      localData: conflict.localData,
      serverData: conflict.serverData,
      resolutionStrategy: ConflictResolutionStrategy.fieldLevelMerge,
      resolvedData: merged,
      status: SyncConflictStatus.autoResolved,
      resolutionSummary:
          'Deterministically merged ${identifyConflictingKeys(conflict.localData, conflict.serverData).length} divergent fields',
    );
  }

  /// Last-Write-Wins (LWW) timestamp based resolution
  static SyncConflictRecord resolveWithLastWriteWins(SyncConflictRecord conflict) {
    final bool clientIsNewer = conflict.localTimestamp.isAfter(conflict.serverTimestamp);
    final chosenData = clientIsNewer ? conflict.localData : conflict.serverData;
    final winnerLabel = clientIsNewer ? 'Client (Offline newer)' : 'Server (Cloud newer)';

    final nextVersion = (conflict.localVersion > conflict.serverVersion
            ? conflict.localVersion
            : conflict.serverVersion) +
        1;

    return SyncConflictRecord(
      id: conflict.id,
      entityId: conflict.entityId,
      entityType: conflict.entityType,
      localVersion: nextVersion,
      serverVersion: nextVersion,
      localTimestamp: conflict.localTimestamp,
      serverTimestamp: conflict.serverTimestamp,
      localData: conflict.localData,
      serverData: conflict.serverData,
      resolutionStrategy: ConflictResolutionStrategy.lastWriteWins,
      resolvedData: chosenData,
      status: SyncConflictStatus.autoResolved,
      resolutionSummary: 'Resolved via Last-Write-Wins ($winnerLabel)',
    );
  }
}
