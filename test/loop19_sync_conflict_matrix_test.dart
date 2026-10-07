import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/models/sync_conflict_record.dart';
import 'package:evehicle_logbook/core/services/sync_conflict_matrix_service.dart';
import 'package:evehicle_logbook/core/widgets/sync_conflict_resolver_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Loop 19: Offline Sync Conflict Resolution Matrix Tests', () {
    final t1 = DateTime(2026, 10, 3, 10, 0, 0);
    final t2 = DateTime(2026, 10, 3, 10, 15, 0);

    test('identifyConflictingKeys accurately detects divergent fields', () {
      final local = {
        'endOdometer': 12550.0,
        'driverNotes': 'Delivered parcel to depot',
        'status': 'SUBMITTED',
      };
      final server = {
        'endOdometer': 12500.0,
        'driverNotes': 'Trip ongoing',
        'status': 'APPROVED',
      };

      final conflicts = SyncConflictMatrixService.identifyConflictingKeys(local, server);

      expect(conflicts, containsAll(['endOdometer', 'driverNotes', 'status']));
      expect(conflicts.length, equals(3));
    });

    test('resolveWithFieldLevelMerge preserves server authority on status while retaining client notes', () {
      final conflict = SyncConflictRecord(
        id: 'CONF-01',
        entityId: 'JRN-101',
        entityType: 'Journey',
        localVersion: 2,
        serverVersion: 3,
        localTimestamp: t2,
        serverTimestamp: t1,
        localData: {
          'endOdometer': 15600.0,
          'driverNotes': 'Refueled at station',
          'status': 'SUBMITTED',
        },
        serverData: {
          'endOdometer': 15500.0,
          'driverNotes': 'Trip completed',
          'status': 'APPROVED',
          'approvedBy': 'Supervisor Rajiv',
        },
        resolutionStrategy: ConflictResolutionStrategy.fieldLevelMerge,
      );

      final resolved = SyncConflictMatrixService.resolveWithFieldLevelMerge(
        conflict: conflict,
      );

      expect(resolved.status, equals(SyncConflictStatus.autoResolved));
      final merged = resolved.resolvedData!;
      // Server authoritative keys prevail
      expect(merged['status'], equals('APPROVED'));
      expect(merged['approvedBy'], equals('Supervisor Rajiv'));
      // Client newer values prevail for non-authoritative keys
      expect(merged['endOdometer'], equals(15600.0));
      expect(merged['driverNotes'], equals('Refueled at station'));
    });

    test('resolveWithLastWriteWins awards winner to newer timestamp', () {
      final conflict = SyncConflictRecord(
        id: 'CONF-02',
        entityId: 'VEH-202',
        entityType: 'Vehicle',
        localVersion: 1,
        serverVersion: 2,
        localTimestamp: t1, // Older
        serverTimestamp: t2, // Newer
        localData: {'fuelCapacity': 50.0},
        serverData: {'fuelCapacity': 65.0},
        resolutionStrategy: ConflictResolutionStrategy.lastWriteWins,
      );

      final resolved = SyncConflictMatrixService.resolveWithLastWriteWins(conflict);

      expect(resolved.status, equals(SyncConflictStatus.autoResolved));
      expect(resolved.resolvedData!['fuelCapacity'], equals(65.0));
      expect(resolved.resolutionSummary, contains('Server'));
    });

    testWidgets('AQIL: SyncConflictResolverCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final conflict = SyncConflictRecord(
        id: 'CONF-AQIL-01',
        entityId: 'JRN-404',
        entityType: 'Journey',
        localVersion: 4,
        serverVersion: 5,
        localTimestamp: t1,
        serverTimestamp: t2,
        localData: {'status': 'SUBMITTED', 'notes': 'Offline update'},
        serverData: {'status': 'APPROVED', 'notes': 'Cloud update'},
        resolutionStrategy: ConflictResolutionStrategy.fieldLevelMerge,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: SyncConflictResolverCard(
                conflict: conflict,
                onAutoMerge: () {},
                onKeepLocal: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SyncConflictResolverCard), findsOneWidget);
      expect(find.text('Auto-Merge'), findsOneWidget);
      expect(find.text('Keep Local'), findsOneWidget);
    });

    testWidgets('AQIL: SyncConflictResolverCard scales safely under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final conflict = SyncConflictRecord(
        id: 'CONF-AQIL-02',
        entityId: 'EXP-505',
        entityType: 'FuelExpense',
        localVersion: 3,
        serverVersion: 3,
        localTimestamp: t2,
        serverTimestamp: t1,
        localData: {'amount': 3500.0},
        serverData: {'amount': 3200.0},
        resolutionStrategy: ConflictResolutionStrategy.lastWriteWins,
        status: SyncConflictStatus.autoResolved,
        resolutionSummary: 'Resolved via Last-Write-Wins (Client)',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SyncConflictResolverCard(conflict: conflict),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SyncConflictResolverCard), findsOneWidget);
      expect(find.text('RESOLVED'), findsOneWidget);
    });
  });
}
