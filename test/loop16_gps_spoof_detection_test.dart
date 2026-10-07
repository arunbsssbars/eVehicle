import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/models/journey.dart';
import 'package:evehicle_logbook/core/services/gps_spoof_detector_service.dart';
import 'package:evehicle_logbook/core/widgets/telemetry_security_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Loop 16: Telemetry Outlier & GPS Spoofing Detector Tests', () {
    final baseTime = DateTime(2026, 10, 3, 10, 0, 0);

    test('Identifies clean realistic trajectory as non-suspicious with 0 anomaly score', () {
      final cleanPoints = [
        JourneyLocationPoint(
          latitude: 28.6139,
          longitude: 77.2090,
          timestamp: baseTime,
          speed: 12.0,
        ),
        JourneyLocationPoint(
          latitude: 28.6145,
          longitude: 77.2095,
          timestamp: baseTime.add(const Duration(seconds: 15)),
          speed: 14.0,
        ),
        JourneyLocationPoint(
          latitude: 28.6152,
          longitude: 77.2102,
          timestamp: baseTime.add(const Duration(seconds: 30)),
          speed: 15.0,
        ),
        JourneyLocationPoint(
          latitude: 28.6160,
          longitude: 77.2110,
          timestamp: baseTime.add(const Duration(seconds: 45)),
          speed: 15.0,
        ),
      ];

      final result = GpsSpoofDetectorService.evaluateRouteTelemetry(cleanPoints);

      expect(result.isSuspicious, isFalse);
      expect(result.anomalyScore, equals(0.0));
      expect(result.teleportationJumpsCount, equals(0));
      expect(result.zeroJitterDetected, isFalse);
      expect(result.flaggedReasons, isEmpty);
    });

    test('Detects teleportation jumps (>180 km/h) and flags high anomaly score', () {
      final spoofedPoints = [
        // Point 1: Delhi
        JourneyLocationPoint(
          latitude: 28.6139,
          longitude: 77.2090,
          timestamp: baseTime,
          speed: 10.0,
        ),
        // Point 2: Delhi local
        JourneyLocationPoint(
          latitude: 28.6145,
          longitude: 77.2095,
          timestamp: baseTime.add(const Duration(seconds: 10)),
          speed: 12.0,
        ),
        // Point 3: Teleport jump to Agra (~180 km away in 5 seconds!)
        JourneyLocationPoint(
          latitude: 27.1767,
          longitude: 78.0081,
          timestamp: baseTime.add(const Duration(seconds: 15)),
          speed: 999.0,
        ),
      ];

      final result = GpsSpoofDetectorService.evaluateRouteTelemetry(spoofedPoints);

      expect(result.isSuspicious, isTrue);
      expect(result.teleportationJumpsCount, greaterThan(0));
      expect(result.anomalyScore, greaterThanOrEqualTo(35.0));
      expect(result.flaggedReasons.first, contains('teleportation anomaly'));
    });

    test('Detects zero-jitter static mocking interpolation', () {
      // 5 sequential points with exact same coordinates over 1 minute
      final mockPoints = [
        JourneyLocationPoint(
          latitude: 28.6139000,
          longitude: 77.2090000,
          timestamp: baseTime,
          speed: 0.0,
        ),
        JourneyLocationPoint(
          latitude: 28.6139000,
          longitude: 77.2090000,
          timestamp: baseTime.add(const Duration(seconds: 10)),
          speed: 0.0,
        ),
        JourneyLocationPoint(
          latitude: 28.6139000,
          longitude: 77.2090000,
          timestamp: baseTime.add(const Duration(seconds: 20)),
          speed: 0.0,
        ),
        JourneyLocationPoint(
          latitude: 28.6139000,
          longitude: 77.2090000,
          timestamp: baseTime.add(const Duration(seconds: 30)),
          speed: 0.0,
        ),
      ];

      final result = GpsSpoofDetectorService.evaluateRouteTelemetry(mockPoints);

      expect(result.zeroJitterDetected, isTrue);
      expect(result.isSuspicious, isTrue);
      expect(result.anomalyScore, greaterThanOrEqualTo(40.0));
      expect(result.flaggedReasons.any((r) => r.contains('Zero GPS satellite jitter')), isTrue);
    });

    testWidgets('AQIL: TelemetrySecurityCard renders safely on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const audit = GpsAuditResult(
        isSuspicious: true,
        anomalyScore: 75.0,
        teleportationJumpsCount: 2,
        zeroJitterDetected: true,
        flaggedReasons: [
          '2 teleportation anomaly(s) detected with impossible ground speed (>180 km/h)',
          'Zero GPS satellite jitter detected: Artificial coordinate interpolation',
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: TelemetrySecurityCard(
                auditResult: audit,
                onInspectTelemetry: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TelemetrySecurityCard), findsOneWidget);
      expect(find.text('MOCK LOCATION SUSPECTED'), findsOneWidget);
      expect(find.text('Risk: 75%'), findsOneWidget);
    });

    testWidgets('AQIL: TelemetrySecurityCard scales safely under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const audit = GpsAuditResult(
        isSuspicious: false,
        anomalyScore: 0.0,
        teleportationJumpsCount: 0,
        zeroJitterDetected: false,
        flaggedReasons: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: TelemetrySecurityCard(auditResult: audit),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TelemetrySecurityCard), findsOneWidget);
      expect(find.text('GENUINE HARDWARE GPS VERIFIED'), findsOneWidget);
      expect(find.text('Risk: 0%'), findsOneWidget);
    });
  });
}
