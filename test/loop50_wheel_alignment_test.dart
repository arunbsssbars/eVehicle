import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/wheel_alignment_service.dart';
import 'package:evehicle_logbook/core/widgets/wheel_alignment_card.dart';

void main() {
  group('Loop 50 - Wheel Alignment & Kinematics Tests', () {
    const service = WheelAlignmentService();

    test('evaluateAlignment returns true alignment for steady cruise with zero offset', () {
      const sample = KinematicsTelemetrySample(
        steeringAngleOffsetDeg: 0.1,
        lateralGForceBias: 0.005,
        innerShoulderTempCelsius: 38.2,
        outerShoulderTempCelsius: 37.8,
        cruiseSpeedKmh: 85.0,
      );

      final audit = service.evaluateAlignment(sample);
      expect(audit.severity, AlignmentSeverity.properAlignment);
      expect(audit.laserAlignmentRequired, isFalse);
      expect(audit.camberToeDeviationScore, lessThan(15.0));
      expect(audit.deltaShoulderTempCelsius, lessThan(1.0));
    });

    test('evaluateAlignment triggers critical alert on high thermal differential and steering drift', () {
      const sample = KinematicsTelemetrySample(
        steeringAngleOffsetDeg: 4.2, // Steering wheel held crooked to maintain lane
        lateralGForceBias: 0.08,
        innerShoulderTempCelsius: 52.0, // Severe camber/toe scrubbing
        outerShoulderTempCelsius: 41.0,
        cruiseSpeedKmh: 95.0,
      );

      final audit = service.evaluateAlignment(sample);
      expect(audit.severity, AlignmentSeverity.criticalChassisMisalignment);
      expect(audit.laserAlignmentRequired, isTrue);
      expect(audit.camberToeDeviationScore, greaterThan(65.0));
      expect(audit.projectedTyreLifeLossPercent, greaterThan(25.0));
    });

    test('evaluateAlignment skips diagnosis when cruising speed is insufficient', () {
      const sample = KinematicsTelemetrySample(
        steeringAngleOffsetDeg: 3.0,
        lateralGForceBias: 0.05,
        innerShoulderTempCelsius: 30.0,
        outerShoulderTempCelsius: 25.0,
        cruiseSpeedKmh: 20.0, // Stop-and-go speed
      );

      final audit = service.evaluateAlignment(sample);
      expect(audit.severity, AlignmentSeverity.properAlignment);
      expect(audit.laserAlignmentRequired, isFalse);
    });

    testWidgets('WheelAlignmentCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = WheelAlignmentAudit(
        severity: AlignmentSeverity.criticalChassisMisalignment,
        camberToeDeviationScore: 78.5,
        deltaShoulderTempCelsius: 9.4,
        projectedTyreLifeLossPercent: 35.3,
        annualScrubbingFuelPenaltyLiters: 141.3,
        diagnosticFinding: 'SEVERE MISALIGNMENT: Extreme toe/camber scrub detected.',
        laserAlignmentRequired: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WheelAlignmentCard(
              audit: audit,
              onBookLaserAlignment: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Wheel Alignment & Camber/Toe'), findsOneWidget);
      expect(find.text('CRITICAL SCRUB'), findsOneWidget);
      expect(find.text('Book 4-Wheel Laser Alignment'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('WheelAlignmentCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = WheelAlignmentAudit(
        severity: AlignmentSeverity.properAlignment,
        camberToeDeviationScore: 6.2,
        deltaShoulderTempCelsius: 0.4,
        projectedTyreLifeLossPercent: 2.8,
        annualScrubbingFuelPenaltyLiters: 11.2,
        diagnosticFinding: 'ALIGNED & BALANCED: Steering zero-point true.',
        laserAlignmentRequired: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: WheelAlignmentCard(audit: audit),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TRUE & ALIGNED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
