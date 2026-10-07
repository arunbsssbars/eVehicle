import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/journey.dart';
import 'package:evehicle_logbook/core/services/journey_export_filter_service.dart';
import 'package:evehicle_logbook/core/widgets/journey_filter_bottom_sheet.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Loop 4: Advanced Filtering, Sorting & Secure CSV Generator Tests', () {
    final now = DateTime.now();

    final journey1 = Journey(
      id: 'JRN-01',
      localId: 'LOC-01',
      clientOperationId: 'OP-01',
      vehicleId: 'VEH-01',
      vehicleRegistration: 'DL01-AB-1234',
      vehicleModel: 'Toyota Innova',
      driverId: 'DRV-1',
      driverName: 'Amit Sharma',
      officerId: 'USR-1',
      officerName: 'Director Singh',
      department: 'Revenue',
      office: 'HQ',
      journeyDate: DateTime(2025, 1, 10),
      startTime: DateTime(2025, 1, 10, 9, 0),
      endTime: DateTime(2025, 1, 10, 10, 30),
      startLocation: 'Secretariat',
      destination: 'Airport Terminal 3',
      purpose: 'VIP Escort',
      openingOdometer: 10000.0,
      closingOdometer: 10045.0,
      officialDistance: 45.0,
      status: JourneyStatus.approved,
      category: TripCategory.business,
      createdAt: now,
      updatedAt: now,
    );

    final journey2 = Journey(
      id: 'JRN-02',
      localId: 'LOC-02',
      clientOperationId: 'OP-02',
      vehicleId: 'VEH-02',
      vehicleRegistration: 'DL01-CD-5678',
      vehicleModel: 'Tata Nexon EV',
      driverId: 'DRV-2',
      driverName: 'Suresh Verma',
      officerId: 'USR-2',
      officerName: 'Finance Officer Rao',
      department: 'Finance',
      office: 'Regional Branch',
      journeyDate: DateTime(2025, 1, 15),
      startTime: DateTime(2025, 1, 15, 11, 0),
      endTime: DateTime(2025, 1, 15, 13, 0),
      startLocation: 'Regional Branch',
      destination: 'Treasury Office',
      purpose: 'Quarterly Audit Documents',
      openingOdometer: 5000.0,
      closingOdometer: 5120.0,
      officialDistance: 120.0,
      status: JourneyStatus.pendingApproval,
      category: TripCategory.business,
      createdAt: now,
      updatedAt: now,
    );

    test('CWE-1236 Defense: sanitizeCsvCell neutralizes formula injection', () {
      // Formula starting with '='
      final formulaCell = JourneyExportFilterService.sanitizeCsvCell('=cmd|\' /C calc\'!A0');
      expect(formulaCell, equals('"\'=cmd|\' /C calc\'!A0"'));

      // Formula starting with '+'
      final plusFormula = JourneyExportFilterService.sanitizeCsvCell('+123456');
      expect(plusFormula, equals('"\' +123456"'.replaceAll(' ', '')));

      // Quotes escaping
      final quotesCell = JourneyExportFilterService.sanitizeCsvCell('Location "A" & "B"');
      expect(quotesCell, equals('"Location ""A"" & ""B"""'));

      // Standard text
      final safeCell = JourneyExportFilterService.sanitizeCsvCell('Normal Purpose');
      expect(safeCell, equals('"Normal Purpose"'));
    });

    test('JourneyExportFilterService accurately filters by status and minDistance', () {
      const criteria = JourneyFilterCriteria(
        status: JourneyStatus.approved,
        minDistance: 40.0,
      );

      final filtered = JourneyExportFilterService.filterAndSortJourneys(
        [journey1, journey2],
        criteria,
      );

      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('JRN-01'));
    });

    test('JourneyExportFilterService sorts correctly by distance descending', () {
      const criteria = JourneyFilterCriteria(
        sortBy: JourneySortField.distance,
        sortAscending: false,
      );

      final sorted = JourneyExportFilterService.filterAndSortJourneys(
        [journey1, journey2],
        criteria,
      );

      expect(sorted.first.id, equals('JRN-02')); // 120 km > 45 km
      expect(sorted.last.id, equals('JRN-01'));
    });

    test('generateJourneyCsv produces valid RFC 4180 CSV with header and data lines', () {
      final csv = JourneyExportFilterService.generateJourneyCsv([journey1]);
      final lines = csv.split('\r\n');

      expect(lines.length, equals(2));
      expect(lines[0], contains('"Journey ID"'));
      expect(lines[0], contains('"Vehicle Registration"'));
      expect(lines[1], contains('"JRN-01"'));
      expect(lines[1], contains('"DL01-AB-1234"'));
    });

    testWidgets('AQIL: JourneyFilterBottomSheet renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JourneyFilterBottomSheet(
              initialCriteria: const JourneyFilterCriteria(),
              onApply: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Filter & Sort Journeys'), findsOneWidget);
      expect(find.text('Apply Filters'), findsOneWidget);
    });

    testWidgets('AQIL: JourneyFilterBottomSheet supports dynamic text scaling 1.5x', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: JourneyFilterBottomSheet(
                initialCriteria: const JourneyFilterCriteria(),
                onApply: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Apply Filters'), findsOneWidget);
    });
  });
}
