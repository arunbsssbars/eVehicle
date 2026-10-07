import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/adas_safety_service.dart';
import 'package:evehicle_logbook/core/widgets/adas_safety_card.dart';

void main() {
  group('Loop 31 - ADAS Forward Collision & Headway Service', () {
    const service = AdasSafetyService();

    test('Safe headway above 2.5 seconds yields 100 score and nominal rating', () {
      final now = DateTime.now();
      // Driving 72 km/h (20 m/s), distance 60m => headway 3.0 seconds
      final samples = List.generate(10, (i) {
        return RadarSample(
          timestamp: now.add(Duration(seconds: i)),
          distanceToLeadMeters: 60.0,
          ownSpeedKmph: 72.0,
          leadSpeedKmph: 72.0,
        );
      });

      final audit = service.evaluateAdasTelemetry(samples);
      expect(audit.isHighCollisionRisk, isFalse);
      expect(audit.adasSafetyScore, equals(100.0));
      expect(audit.tailgatingEventsCount, equals(0));
      expect(audit.forwardCollisionWarningCount, equals(0));
    });

    test('Severe tailgating with rapid approach triggers FCW and high collision risk', () {
      final now = DateTime.now();
      // Driving 90 km/h (25 m/s) closing on vehicle at 60 km/h (16.6 m/s) with 15m distance
      // Closing speed: 8.33 m/s => TTC = 1.8 seconds (FCW triggered!)
      final samples = List.generate(10, (i) {
        return RadarSample(
          timestamp: now.add(Duration(seconds: i)),
          distanceToLeadMeters: 15.0,
          ownSpeedKmph: 90.0,
          leadSpeedKmph: 60.0,
        );
      });

      final audit = service.evaluateAdasTelemetry(samples);
      expect(audit.isHighCollisionRisk, isTrue);
      expect(audit.forwardCollisionWarningCount, greaterThan(0));
      expect(audit.tailgatingEventsCount, greaterThan(0));
      expect(audit.adasSafetyScore, lessThan(60.0));
    });

    test('Empty samples list handled gracefully', () {
      final audit = service.evaluateAdasTelemetry([]);
      expect(audit.isHighCollisionRisk, isFalse);
      expect(audit.adasSafetyScore, equals(100.0));
    });
  });

  group('Loop 31 - ADAS Safety AQIL Responsive UI Tests', () {
    testWidgets('AdasSafetyCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = AdasSafetyAudit(
        averageHeadwaySeconds: 2.8,
        minObservedHeadwaySeconds: 2.2,
        tailgatingEventsCount: 0,
        forwardCollisionWarningCount: 0,
        tailgatingDurationTotalSeconds: 0.0,
        adasSafetyScore: 98.5,
        isHighCollisionRisk: false,
        safetyAdvisory: 'EXCELLENT: Driver maintains optimal safe following cushion.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdasSafetyCard(
              audit: audit,
              onReviewTelemetry: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ADAS Collision & Headway'), findsOneWidget);
      expect(find.text('SAFE'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AdasSafetyCard preserves layout stability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = AdasSafetyAudit(
        averageHeadwaySeconds: 1.1,
        minObservedHeadwaySeconds: 0.7,
        tailgatingEventsCount: 8,
        forwardCollisionWarningCount: 3,
        tailgatingDurationTotalSeconds: 24.0,
        adasSafetyScore: 42.0,
        isHighCollisionRisk: true,
        safetyAdvisory: 'HIGH COLLISION RISK: Severe tailgating recorded.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Scaffold(
              body: AdasSafetyCard(
                audit: audit,
                onReviewTelemetry: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RISK'), findsOneWidget);
      expect(find.text('Inspect Headway Distance Timeline'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
