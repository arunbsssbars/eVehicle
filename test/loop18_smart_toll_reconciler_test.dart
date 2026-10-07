import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/models/journey.dart';
import 'package:evehicle_logbook/core/models/toll_transaction.dart';
import 'package:evehicle_logbook/core/services/smart_toll_reconciler_service.dart';
import 'package:evehicle_logbook/core/widgets/toll_reconciliation_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Loop 18: Smart Toll & FASTag Expense Reconciler Tests', () {
    final baseTime = DateTime(2026, 10, 3, 11, 0, 0);

    const plazaKherki = TollPlaza(
      id: 'PLZ-KHERKI',
      name: 'Kherki Daula Toll Plaza',
      highwayName: 'NH-48',
      latitude: 28.4116,
      longitude: 76.9942,
      standardFee: 80.0,
      radiusMeters: 300.0,
    );

    const plazaManesar = TollPlaza(
      id: 'PLZ-MANESAR',
      name: 'Manesar Toll Plaza',
      highwayName: 'NH-48',
      latitude: 28.3580,
      longitude: 76.9380,
      standardFee: 65.0,
      radiusMeters: 300.0,
    );

    test('detectTollCrossings identifies plaza crossing when route is within radius', () {
      final routePoints = [
        // Point approaching Kherki
        JourneyLocationPoint(
          latitude: 28.4118,
          longitude: 76.9944,
          timestamp: baseTime,
          speed: 15.0,
        ),
        // Point after toll
        JourneyLocationPoint(
          latitude: 28.4100,
          longitude: 76.9920,
          timestamp: baseTime.add(const Duration(minutes: 2)),
          speed: 20.0,
        ),
      ];

      final crossings = SmartTollReconcilerService.detectTollCrossings(
        routePoints: routePoints,
        plazas: [plazaKherki, plazaManesar],
      );

      expect(crossings.length, equals(1));
      expect(crossings.first.plaza.id, equals('PLZ-KHERKI'));
    });

    test('reconcileFastagTransaction reconciles valid matching transaction', () {
      final routePoints = [
        JourneyLocationPoint(
          latitude: 28.4116,
          longitude: 76.9942,
          timestamp: baseTime,
          speed: 5.0,
        ),
      ];

      final transaction = FastagTransaction(
        id: 'TXN-FAST-01',
        plazaId: 'PLZ-KHERKI',
        plazaName: 'Kherki Daula Toll Plaza',
        vehicleRegistration: 'DL01-AB-1234',
        deductedAmount: 80.0,
        timestamp: baseTime.add(const Duration(minutes: 3)),
        bankReferenceId: 'UPI-98210384',
      );

      final result = SmartTollReconcilerService.reconcileFastagTransaction(
        transaction: transaction,
        routePoints: routePoints,
        plazas: [plazaKherki],
      );

      expect(result.isMatched, isTrue);
      expect(result.varianceAmount, equals(0.0));
      expect(result.matchedPlazaName, equals('Kherki Daula Toll Plaza'));
    });

    test('reconcileFastagTransaction flags ghost debit when vehicle never passed plaza', () {
      // Vehicle in Central Delhi, nowhere near Manesar
      final routePoints = [
        JourneyLocationPoint(
          latitude: 28.6139,
          longitude: 77.2090,
          timestamp: baseTime,
          speed: 10.0,
        ),
      ];

      final transaction = FastagTransaction(
        id: 'TXN-GHOST-01',
        plazaId: 'PLZ-MANESAR',
        plazaName: 'Manesar Toll Plaza',
        vehicleRegistration: 'DL01-AB-1234',
        deductedAmount: 65.0,
        timestamp: baseTime,
        bankReferenceId: 'UPI-77665544',
      );

      final result = SmartTollReconcilerService.reconcileFastagTransaction(
        transaction: transaction,
        routePoints: routePoints,
        plazas: [plazaManesar],
      );

      expect(result.isMatched, isFalse);
      expect(result.flaggedAnomalies.first, contains('Ghost FASTag Deduction'));
    });

    testWidgets('AQIL: TollReconciliationCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final transaction = FastagTransaction(
        id: 'TXN-01',
        plazaId: 'PLZ-01',
        plazaName: 'Kherki Daula Toll Plaza',
        vehicleRegistration: 'DL01-AB-1234',
        deductedAmount: 80.0,
        timestamp: baseTime,
        bankReferenceId: 'REF-12345',
      );

      const reconciliation = TollReconciliationResult(
        isMatched: true,
        varianceAmount: 0.0,
        matchedPlazaName: 'Kherki Daula Toll Plaza',
        flaggedAnomalies: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: TollReconciliationCard(
                transaction: transaction,
                reconciliation: reconciliation,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TollReconciliationCard), findsOneWidget);
      expect(find.text('RECONCILED'), findsOneWidget);
      expect(find.text('₹80'), findsOneWidget);
    });

    testWidgets('AQIL: TollReconciliationCard scales safely under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final transaction = FastagTransaction(
        id: 'TXN-02',
        plazaId: 'PLZ-02',
        plazaName: 'Badarpur Flyover Toll',
        vehicleRegistration: 'DL01-CD-5678',
        deductedAmount: 95.0,
        timestamp: baseTime,
        bankReferenceId: 'REF-67890',
      );

      const reconciliation = TollReconciliationResult(
        isMatched: false,
        varianceAmount: 95.0,
        flaggedAnomalies: ['Ghost FASTag Deduction: Vehicle GPS was not within Badarpur Flyover Toll'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TollReconciliationCard(
                    transaction: transaction,
                    reconciliation: reconciliation,
                    onDisputeTransaction: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TollReconciliationCard), findsOneWidget);
      expect(find.text('UNMATCHED / GHOST'), findsOneWidget);
      expect(find.text('Dispute Ghost Charge'), findsOneWidget);
    });
  });
}
