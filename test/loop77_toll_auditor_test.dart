import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/toll_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/toll_auditor_card.dart';

void main() {
  group('Loop 77: Automated Toll Expense Auditor Service Tests', () {
    const service = TollAuditorService();

    test('Regular journey with accurate fares produces zero refund discrepancies', () {
      final passages = [
        TollPlazaPassage(
          plazaId: 'plz-kherki',
          plazaName: 'Kherki Daula Toll Plaza',
          highwayCode: 'NH-48',
          passageTime: DateTime(2026, 10, 5, 8, 30),
          billedAmount: 80.0,
          standardSingleFare: 80.0,
          standardReturnFare24h: 120.0,
          vehicleClassCharged: 'Car/Jeep',
          registeredVehicleClass: 'Car/Jeep',
        ),
      ];

      final summary = service.auditTollPassages(
        vehicleId: 'veh-01',
        registrationNumber: 'DL01-CA-1111',
        passages: passages,
      );

      expect(summary.totalBilledAmount, 80.0);
      expect(summary.legitimateExpectedAmount, 80.0);
      expect(summary.totalRefundEntitlement, 0.0);
      expect(summary.hasOverchargeDiscrepancies, isFalse);
    });

    test('Missed return concession and misclassified vehicle tag triggers refunds', () {
      final now = DateTime(2026, 10, 5, 8, 0);
      final passages = [
        TollPlazaPassage(
          plazaId: 'plz-manesar',
          plazaName: 'Manesar Gantry',
          highwayCode: 'NH-48',
          passageTime: now,
          billedAmount: 135.0,
          standardSingleFare: 90.0,
          standardReturnFare24h: 135.0,
          vehicleClassCharged: 'Bus/Truck 2-Axle', // Misclassified!
          registeredVehicleClass: 'Car/Jeep',
        ),
        TollPlazaPassage(
          plazaId: 'plz-manesar',
          plazaName: 'Manesar Gantry',
          highwayCode: 'NH-48',
          passageTime: now.add(const Duration(hours: 4)), // Return within 4 hours
          billedAmount: 90.0, // Re-billed full single fare instead of discount
          standardSingleFare: 90.0,
          standardReturnFare24h: 135.0, // Return concession diff = 45.0
          vehicleClassCharged: 'Car/Jeep',
          registeredVehicleClass: 'Car/Jeep',
        ),
      ];

      final summary = service.auditTollPassages(
        vehicleId: 'veh-02',
        registrationNumber: 'HR26-DF-9988',
        passages: passages,
      );

      expect(summary.hasOverchargeDiscrepancies, isTrue);
      expect(summary.totalRefundEntitlement > 0, isTrue);
      expect(summary.discrepancies.length, 2);
      expect(summary.discrepancies.any((d) => d.issueDescription.contains('Miscalibrated Tag')), isTrue);
      expect(summary.discrepancies.any((d) => d.issueDescription.contains('Return Journey Concession')), isTrue);
    });
  });

  group('Loop 77: AQIL UI Multi-Viewport & Accessibility Tests', () {
    const service = TollAuditorService();

    final testSummary = service.auditTollPassages(
      vehicleId: 'veh-test',
      registrationNumber: 'DL04-COMM-9988',
      passages: [
        TollPlazaPassage(
          plazaId: 'plz-01',
          plazaName: 'Eastern Peripheral Expressway Gantry 4',
          highwayCode: 'NE-2',
          passageTime: DateTime.now(),
          billedAmount: 240.0,
          standardSingleFare: 160.0,
          standardReturnFare24h: 240.0,
          vehicleClassCharged: 'MAV 3-Axle',
          registeredVehicleClass: 'Bus/Truck 2-Axle',
        ),
      ],
    );

    testWidgets('TollAuditorCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TollAuditorCard(
                summary: testSummary,
                onFileDisputeClaim: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Toll & FASTag Auditor'), findsOneWidget);
      expect(find.textContaining('Submit Auto-Dispute Claim Packet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TollAuditorCard maintains integrity under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: SingleChildScrollView(
                child: TollAuditorCard(
                  summary: testSummary,
                  onFileDisputeClaim: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TollAuditorCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
