import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/shift_handover_record.dart';
import 'package:evehicle_logbook/core/services/shift_handover_service.dart';
import 'package:evehicle_logbook/core/widgets/shift_handover_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Loop 15: Shift Handover & Vehicle Sanitization Checkpoint Tests', () {
    final now = DateTime.now();

    test('validateOdometerContinuity detects valid transition and flags rollback', () {
      // Valid continuity (handover odometer >= previous closing odometer)
      expect(
        ShiftHandoverService.validateOdometerContinuity(
          lastClosingOdometer: 15400.0,
          handoverOdometer: 15400.0,
        ),
        isTrue,
      );

      expect(
        ShiftHandoverService.validateOdometerContinuity(
          lastClosingOdometer: 15400.0,
          handoverOdometer: 15405.0,
        ),
        isTrue,
      );

      // Rollback detected (e.g. 15400 closing, but 15200 handover)
      expect(
        ShiftHandoverService.validateOdometerContinuity(
          lastClosingOdometer: 15400.0,
          handoverOdometer: 15200.0,
        ),
        isFalse,
      );
    });

    test('acceptHandover and disputeHandover update status accurately', () {
      final initial = ShiftHandoverRecord(
        id: 'HO-01',
        vehicleId: 'VEH-01',
        vehicleRegistration: 'DL01-AB-1234',
        outgoingDriverId: 'DRV-1',
        outgoingDriverName: 'Rajesh',
        incomingDriverId: 'DRV-2',
        incomingDriverName: 'Vikram',
        timestamp: now,
        odometerReading: 12500.0,
        fuelLevelPercent: 80,
      );

      expect(initial.status, equals(HandoverStatus.pendingAcceptance));

      final accepted = ShiftHandoverService.acceptHandover(initial);
      expect(accepted.status, equals(HandoverStatus.accepted));

      final disputed = ShiftHandoverService.disputeHandover(
        record: initial,
        reason: 'Fuel gauge below 25%, trash in cabin',
      );
      expect(disputed.status, equals(HandoverStatus.disputed));
      expect(disputed.disputeReason, contains('trash in cabin'));
    });

    testWidgets('AQIL: ShiftHandoverCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final record = ShiftHandoverRecord(
        id: 'HO-02',
        vehicleId: 'VEH-02',
        vehicleRegistration: 'DL01-CD-5678',
        outgoingDriverId: 'DRV-1',
        outgoingDriverName: 'Rajesh',
        incomingDriverId: 'DRV-2',
        incomingDriverName: 'Vikram',
        timestamp: now,
        odometerReading: 18400.0,
        fuelLevelPercent: 75,
        status: HandoverStatus.pendingAcceptance,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: ShiftHandoverCard(
                record: record,
                onAccept: () {},
                onDispute: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ShiftHandoverCard), findsOneWidget);
      expect(find.text('Accept Vehicle'), findsOneWidget);
    });

    testWidgets('AQIL: ShiftHandoverCard scales safely under 1.5x dynamic text scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final record = ShiftHandoverRecord(
        id: 'HO-03',
        vehicleId: 'VEH-03',
        vehicleRegistration: 'DL01-EF-9012',
        outgoingDriverId: 'DRV-3',
        outgoingDriverName: 'Sanjay',
        incomingDriverId: 'DRV-4',
        incomingDriverName: 'Amit',
        timestamp: now,
        odometerReading: 32000.0,
        fuelLevelPercent: 90,
        status: HandoverStatus.accepted,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ShiftHandoverCard(record: record),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ShiftHandoverCard), findsOneWidget);
      expect(find.text('ACCEPTED'), findsOneWidget);
    });
  });
}
