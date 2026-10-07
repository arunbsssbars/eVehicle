import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/crash_reconstruction_service.dart';
import 'package:evehicle_logbook/core/widgets/crash_forensics_card.dart';

void main() {
  group('Loop 23 - Collision & Impact Forensics Reconstruction Service', () {
    const service = CrashReconstructionService();

    test('Smooth driving returns nominal non-crash report', () {
      final now = DateTime.now();
      final samples = List.generate(10, (i) {
        return GForceSample(
          timestamp: now.add(Duration(milliseconds: i * 100)),
          accelX: 0.05,
          accelY: 0.12,
          accelZ: 0.98,
          speedKmph: 60.0,
        );
      });

      final report = service.analyzeImpactTelemetry(samples);
      expect(report.hasCrashOccurred, isFalse);
      expect(report.severity, equals(CrashSeverity.none));
      expect(report.emergencyDispatchRecommended, isFalse);
    });

    test('High G-force impact triggers severe collision and emergency dispatch', () {
      final now = DateTime.now();
      final samples = [
        GForceSample(timestamp: now, accelX: 0.1, accelY: 0.2, accelZ: 1.0, speedKmph: 75.0),
        GForceSample(timestamp: now.add(const Duration(milliseconds: 100)), accelX: 0.2, accelY: 0.3, accelZ: 1.0, speedKmph: 74.0),
        // Impact Spike: 7.2G along Y axis
        GForceSample(timestamp: now.add(const Duration(milliseconds: 200)), accelX: 1.5, accelY: 7.0, accelZ: 1.2, speedKmph: 15.0),
        GForceSample(timestamp: now.add(const Duration(milliseconds: 300)), accelX: 0.4, accelY: 0.8, accelZ: 1.0, speedKmph: 0.0),
      ];

      final report = service.analyzeImpactTelemetry(samples);
      expect(report.hasCrashOccurred, isTrue);
      expect(report.severity, equals(CrashSeverity.severeImpact));
      expect(report.peakGForce, greaterThan(6.0));
      expect(report.emergencyDispatchRecommended, isTrue);
    });

    test('Lateral inversion and inverted Z-axis detects rollover event', () {
      final now = DateTime.now();
      final samples = [
        GForceSample(timestamp: now, accelX: 0.1, accelY: 0.2, accelZ: 1.0, speedKmph: 50.0),
        // Rollover impulse: severe lateral spike and inverted vertical
        GForceSample(timestamp: now.add(const Duration(milliseconds: 100)), accelX: 3.2, accelY: 1.1, accelZ: -0.8, speedKmph: 20.0),
        GForceSample(timestamp: now.add(const Duration(milliseconds: 200)), accelX: 0.2, accelY: 0.1, accelZ: -0.7, speedKmph: 0.0),
      ];

      final report = service.analyzeImpactTelemetry(samples);
      expect(report.hasCrashOccurred, isTrue);
      expect(report.isRollover, isTrue);
      expect(report.severity, equals(CrashSeverity.rollover));
    });
  });

  group('Loop 23 - Collision Forensics AQIL Responsive UI Tests', () {
    testWidgets('CrashForensicsCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final report = CrashReconstructionReport(
        hasCrashOccurred: true,
        severity: CrashSeverity.severeImpact,
        peakGForce: 7.45,
        deltaVKmph: 52.0,
        preImpactSpeedKmph: 75.0,
        postImpactSpeedKmph: 23.0,
        isRollover: false,
        impactVectorDegrees: 180.0,
        emergencyDispatchRecommended: true,
        incidentTimestamp: DateTime(2026, 10, 3, 14, 20),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrashForensicsCard(
              report: report,
              onTriggerEmergencyDispatch: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Impact Forensics'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('Dispatch SOS & Fleet Safety Escort'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CrashForensicsCard maintains readability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const report = CrashReconstructionReport(
        hasCrashOccurred: false,
        severity: CrashSeverity.none,
        peakGForce: 0.95,
        deltaVKmph: 0.0,
        preImpactSpeedKmph: 45.0,
        postImpactSpeedKmph: 45.0,
        isRollover: false,
        impactVectorDegrees: 0.0,
        emergencyDispatchRecommended: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: const Scaffold(
              body: CrashForensicsCard(
                report: report,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NORMAL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
