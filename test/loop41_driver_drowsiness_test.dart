import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/driver_drowsiness_service.dart';
import 'package:evehicle_logbook/core/widgets/driver_drowsiness_card.dart';

void main() {
  group('Loop 41 - Driver Biometric & Microsleep Drowsiness Tests', () {
    const service = DriverDrowsinessService();

    test('evaluateAlertness returns baseline when samples < 2', () {
      final audit = service.evaluateAlertness([]);
      expect(audit.riskLevel, DrowsinessRiskLevel.normal);
      expect(audit.requiresImmediateRestBreak, isFalse);
    });

    test('evaluateAlertness identifies normal vigilance on healthy HRV and BPM', () {
      final now = DateTime.now();
      final samples = List.generate(
        10,
        (i) => BiometricPulseSample(
          timestamp: now.add(Duration(seconds: i)),
          heartRateBpm: 74.0,
          rrIntervalMs: 800.0 + (i % 2 == 0 ? 30.0 : -30.0),
        ),
      );

      final audit = service.evaluateAlertness(samples);
      expect(audit.riskLevel, DrowsinessRiskLevel.normal);
      expect(audit.averageBpm, 74.0);
      expect(audit.requiresImmediateRestBreak, isFalse);
    });

    test('evaluateAlertness flags critical microsleep when heart rate drops and HRV spikes excessively', () {
      final now = DateTime.now();
      final samples = List.generate(
        10,
        (i) => BiometricPulseSample(
          timestamp: now.add(Duration(seconds: i)),
          heartRateBpm: 48.0, // bradycardic drop during head nodding
          rrIntervalMs: 1200.0 + (i % 2 == 0 ? 95.0 : -95.0),
        ),
      );

      final audit = service.evaluateAlertness(samples);
      expect(audit.riskLevel, DrowsinessRiskLevel.criticalMicrosleepRisk);
      expect(audit.requiresImmediateRestBreak, isTrue);
      expect(audit.fatigueIndexPercent, greaterThanOrEqualTo(75.0));
    });

    testWidgets('DriverDrowsinessCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = DriverDrowsinessAudit(
        averageBpm: 52.0,
        rmssdMs: 78.0,
        fatigueIndexPercent: 82.0,
        riskLevel: DrowsinessRiskLevel.criticalMicrosleepRisk,
        recommendation: 'CRITICAL: Severe microsleep onset detected! Pull over immediately.',
        requiresImmediateRestBreak: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DriverDrowsinessCard(
              audit: audit,
              onAcknowledgeAlert: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Biometric Vigilance Monitor'), findsOneWidget);
      expect(find.text('MICROSLEEP RISK'), findsOneWidget);
      expect(find.text('Schedule Immediate Rest Break'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DriverDrowsinessCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = DriverDrowsinessAudit(
        averageBpm: 70.0,
        rmssdMs: 38.0,
        fatigueIndexPercent: 12.0,
        riskLevel: DrowsinessRiskLevel.normal,
        recommendation: 'OPTIMAL ALERTNESS: Heart rate variability within safe operational parameters.',
        requiresImmediateRestBreak: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: DriverDrowsinessCard(audit: audit),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ALERT & VIGILANT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
