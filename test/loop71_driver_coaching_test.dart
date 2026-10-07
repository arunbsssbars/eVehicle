import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/driver_coaching_service.dart';
import 'package:evehicle_logbook/core/widgets/driver_coaching_card.dart';

void main() {
  group('Loop 71: Autonomous Fleet AI Driver Coaching Service Tests', () {
    const service = DriverCoachingService();

    test('Clean driving yields S grade and 100 score', () {
      final report = service.evaluateDriverHabits(
        driverId: 'drv-001',
        driverName: 'Vikram Singh',
        events: [],
        totalJourneyMinutes: 120,
        totalIdlingMinutes: 5,
      );

      expect(report.score, 100.0);
      expect(report.grade, 'S');
      expect(report.harshBrakingCount, 0);
      expect(report.tips.first.title, 'Exemplary Driving Profile');
    });

    test('Aggressive driving incurs calculated penalties and coaching tips', () {
      final now = DateTime.now();
      final events = [
        DriverTelemetryEvent(type: TelematicsEventType.harshBraking, timestamp: now, severity: 0.8),
        DriverTelemetryEvent(type: TelematicsEventType.harshBraking, timestamp: now, severity: 0.9),
        DriverTelemetryEvent(type: TelematicsEventType.harshBraking, timestamp: now, severity: 0.7),
        DriverTelemetryEvent(type: TelematicsEventType.harshAcceleration, timestamp: now, severity: 0.6),
        DriverTelemetryEvent(type: TelematicsEventType.speeding, timestamp: now, severity: 1.0),
        DriverTelemetryEvent(type: TelematicsEventType.severeCornering, timestamp: now, severity: 0.7),
        DriverTelemetryEvent(type: TelematicsEventType.severeCornering, timestamp: now, severity: 0.8),
      ];

      final report = service.evaluateDriverHabits(
        driverId: 'drv-002',
        driverName: 'Arjun Verma',
        events: events,
        totalJourneyMinutes: 90,
        totalIdlingMinutes: 25, // 15 min excess idling -> (15/5)*1 = 3.0 pts
      );

      // harshBraking: 3 * 3.0 = 9.0
      // harshAccel: 1 * 2.5 = 2.5
      // severeCornering: 2 * 3.5 = 7.0
      // speeding: 1 * 4.0 = 4.0
      // excessIdling: 3.0
      // total penalty = 25.5 -> score = 74.5 -> grade 'C'
      expect(report.score, 74.5);
      expect(report.grade, 'C');
      expect(report.harshBrakingCount, 3);
      expect(report.speedingCount, 1);
      expect(report.tips.any((t) => t.title.contains('Following Distance')), isTrue);
      expect(report.tips.any((t) => t.title.contains('Speed Envelopes')), isTrue);
    });
  });

  group('Loop 71: AQIL UI Multi-Viewport & Accessibility Tests', () {
    const service = DriverCoachingService();

    final testReport = service.evaluateDriverHabits(
      driverId: 'drv-test',
      driverName: 'Harpreet Singh Sandhu (Senior Commercial Driver)',
      events: [
        DriverTelemetryEvent(type: TelematicsEventType.harshBraking, timestamp: DateTime.now(), severity: 0.5),
        DriverTelemetryEvent(type: TelematicsEventType.harshAcceleration, timestamp: DateTime.now(), severity: 0.6),
      ],
      totalJourneyMinutes: 60,
      totalIdlingMinutes: 12,
    );

    testWidgets('DriverCoachingCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DriverCoachingCard(
                report: testReport,
                onDetailedReview: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Harpreet Singh Sandhu'), findsOneWidget);
      expect(find.textContaining('AI Driver Coaching'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DriverCoachingCard maintains integrity under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: SingleChildScrollView(
                child: DriverCoachingCard(
                  report: testReport,
                  onDetailedReview: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DriverCoachingCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
