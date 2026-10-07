import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/models/journey.dart';
import 'package:evehicle_logbook/core/widgets/journey_card.dart';

void main() {
  final testJourney = Journey(
    id: 'JRN-2026-TEST-001',
    localId: 'LOC-001',
    clientOperationId: 'OP-001',
    vehicleId: 'VEH-01',
    vehicleRegistration: 'DL 1C AB 1234',
    vehicleModel: 'Innova Crysta',
    driverId: 'DRV-01',
    driverName: 'Rajesh Kumar',
    officerId: 'USR-01',
    officerName: 'Dr. S. K. Verma',
    department: 'Public Works Department',
    office: 'Division Headquarters',
    journeyDate: DateTime(2026, 8, 15),
    startTime: DateTime(2026, 8, 15, 9, 30),
    endTime: DateTime(2026, 8, 15, 11, 45),
    startLocation: 'Civil Secretariat, Delhi',
    destination: 'District Collectorate Office, Noida',
    purpose: 'Routine inspection and official project review meeting with engineering staff',
    openingOdometer: 45210.0,
    closingOdometer: 45268.5,
    status: JourneyStatus.completed,
    createdAt: DateTime(2026, 8, 15, 9, 30),
    updatedAt: DateTime(2026, 8, 15, 11, 45),
  );

  testWidgets('JourneyCard renders route micro-timeline, KM badge, and purpose cleanly',
      (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: JourneyCard(
              journey: testJourney,
              showDate: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check Start Location and Destination
    expect(find.text('Civil Secretariat, Delhi'), findsOneWidget);
    expect(find.text('District Collectorate Office, Noida'), findsOneWidget);

    // Check KM badge
    expect(find.text('58.5'), findsOneWidget);
    expect(find.text('KM'), findsOneWidget);

    // Check vehicle name (in between time and KM) and driver with SteeringWheelIcon
    expect(find.text('Innova Crysta'), findsOneWidget);
    expect(find.byType(SteeringWheelIcon), findsOneWidget);
    expect(find.text('Rajesh Kumar'), findsOneWidget);

    // Check Odometer progression
    expect(find.text('45210 → 45269 KM'), findsOneWidget);

    // Check full-width purpose text (no Purpose: prefix)
    expect(
      find.textContaining('Routine inspection and official project review meeting'),
      findsOneWidget,
    );

    // Check navigation chevron
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    // Verify tap callback
    await tester.tap(find.byType(JourneyCard));
    expect(tapped, isTrue);
  });

  testWidgets('JourneyCard renders on narrow 320px width without layout overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: JourneyCard(
              journey: testJourney,
              showDate: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('58.5'), findsOneWidget);
  });

  testWidgets('JourneyCard does NOT contain "Purpose:" prefix and displays raw purpose cleanly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: JourneyCard(journey: testJourney),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify "Purpose:" prefix is NOT present
    expect(find.textContaining('Purpose:'), findsNothing);
    // Verify purpose string itself is present
    expect(find.textContaining('Routine inspection and official project review meeting'), findsOneWidget);
  });
}
