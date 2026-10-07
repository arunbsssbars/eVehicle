import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/road_vibration_profiler_service.dart';
import 'package:evehicle_logbook/core/widgets/road_surface_quality_card.dart';

void main() {
  group('Loop 27 - Road Surface & Pothole Vibration Profiler Service', () {
    const service = RoadVibrationProfilerService();

    test('Smooth highway driving produces low roughness index and smooth quality class', () {
      final now = DateTime.now();
      final samples = List.generate(20, (i) {
        return VibrationSample(
          timestamp: now.add(Duration(milliseconds: i * 200)),
          zAxisAccelG: 1.02 + (i % 2 == 0 ? 0.02 : -0.02),
          speedKmph: 85.0,
          latitude: 12.97,
          longitude: 77.59,
        );
      });

      final audit = service.analyzeVibrations(samples);
      expect(audit.qualityClass, equals(RoadQualityClass.smoothHighway));
      expect(audit.potholeStrikeCount, equals(0));
      expect(audit.roughnessIndex, lessThan(2.0));
      expect(audit.suspensionWearPenaltyPercent, lessThan(10.0));
    });

    test('Severe pothole impacts trigger hazard classification and wear penalty', () {
      final now = DateTime.now();
      final samples = [
        VibrationSample(timestamp: now, zAxisAccelG: 1.0, speedKmph: 45.0, latitude: 12.97, longitude: 77.59),
        // Severe pothole strike 1
        VibrationSample(timestamp: now.add(const Duration(milliseconds: 200)), zAxisAccelG: 2.35, speedKmph: 44.0, latitude: 12.971, longitude: 77.591),
        // Severe pothole strike 2
        VibrationSample(timestamp: now.add(const Duration(milliseconds: 400)), zAxisAccelG: 0.10, speedKmph: 43.0, latitude: 12.972, longitude: 77.592),
        // Severe pothole strike 3
        VibrationSample(timestamp: now.add(const Duration(milliseconds: 600)), zAxisAccelG: 2.10, speedKmph: 42.0, latitude: 12.973, longitude: 77.593),
        // Severe pothole strike 4
        VibrationSample(timestamp: now.add(const Duration(milliseconds: 800)), zAxisAccelG: 1.95, speedKmph: 40.0, latitude: 12.974, longitude: 77.594),
        // Severe pothole strike 5
        VibrationSample(timestamp: now.add(const Duration(milliseconds: 1000)), zAxisAccelG: 2.50, speedKmph: 38.0, latitude: 12.975, longitude: 77.595),
      ];

      final audit = service.analyzeVibrations(samples);
      expect(audit.qualityClass, equals(RoadQualityClass.severePotholes));
      expect(audit.potholeStrikeCount, equals(5));
      expect(audit.suspensionWearPenaltyPercent, greaterThan(15.0));
    });

    test('Empty samples list handled gracefully', () {
      final audit = service.analyzeVibrations([]);
      expect(audit.qualityClass, equals(RoadQualityClass.smoothHighway));
      expect(audit.potholeStrikeCount, equals(0));
    });
  });

  group('Loop 27 - Road Surface AQIL Responsive UI Tests', () {
    testWidgets('RoadSurfaceQualityCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = RoadRoughnessAudit(
        roughnessIndex: 1.8,
        qualityClass: RoadQualityClass.smoothHighway,
        potholeStrikeCount: 0,
        averageSpeedKmph: 78.4,
        suspensionWearPenaltyPercent: 4.5,
        severeStrikes: [],
        surfaceSummary: 'Pristine asphalt: Minimal vibration stress.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoadSurfaceQualityCard(
              audit: audit,
              onReportPotholeHazard: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Road Surface Profiler'), findsOneWidget);
      expect(find.text('SMOOTH'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RoadSurfaceQualityCard preserves layout stability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = RoadRoughnessAudit(
        roughnessIndex: 7.4,
        qualityClass: RoadQualityClass.severePotholes,
        potholeStrikeCount: 6,
        averageSpeedKmph: 32.1,
        suspensionWearPenaltyPercent: 27.5,
        severeStrikes: [],
        surfaceSummary: 'Hazardous potholes: Extreme vertical impulses recorded.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Scaffold(
              body: RoadSurfaceQualityCard(
                audit: audit,
                onReportPotholeHazard: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HAZARD'), findsOneWidget);
      expect(find.text('Broadcast Road Hazard Geo-Tag'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
