import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/propshaft_vibration_service.dart';
import 'package:evehicle_logbook/core/widgets/propshaft_vibration_card.dart';

void main() {
  group('Loop 63 - Propshaft & Driveline Vibration Tests', () {
    const service = PropshaftVibrationService();

    test('diagnoseDriveline confirms smooth balanced driveline under normal operating harmonics', () {
      const sample = PropshaftVibrationSample(
        shaftRotationalRpm: 1800.0,
        order1xAmplitudeMmPerSec: 1.2,
        order2xAmplitudeMmPerSec: 0.8,
        centerBearingGForceRms: 0.6,
        workingAngleDiffDegrees: 0.4,
      );

      final audit = service.diagnoseDriveline(sample);
      expect(audit.severity, DrivelineVibrationSeverity.smoothBalanced);
      expect(audit.immediateInspectionRequired, isFalse);
      expect(audit.totalVibrationVelocityMmPerSec, lessThan(2.5));
    });

    test('diagnoseDriveline triggers critical alert on high RMS shudder', () {
      const sample = PropshaftVibrationSample(
        shaftRotationalRpm: 2200.0,
        order1xAmplitudeMmPerSec: 7.2,
        order2xAmplitudeMmPerSec: 6.1,
        centerBearingGForceRms: 4.2, // Heavy bearing impact
        workingAngleDiffDegrees: 1.2,
      );

      final audit = service.diagnoseDriveline(sample);
      expect(audit.severity, DrivelineVibrationSeverity.criticalPropshaftFailureRisk);
      expect(audit.immediateInspectionRequired, isTrue);
      expect(audit.totalVibrationVelocityMmPerSec, greaterThan(8.5));
    });

    test('diagnoseDriveline detects 2X U-joint angularity mismatch', () {
      const sample = PropshaftVibrationSample(
        shaftRotationalRpm: 1900.0,
        order1xAmplitudeMmPerSec: 1.5,
        order2xAmplitudeMmPerSec: 5.2, // High 2X harmonic
        centerBearingGForceRms: 1.0,
        workingAngleDiffDegrees: 2.1, // Excessive U-joint phase angle
      );

      final audit = service.diagnoseDriveline(sample);
      expect(audit.severity, DrivelineVibrationSeverity.uJointAngleMismatch);
    });

    testWidgets('PropshaftVibrationCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = PropshaftHealthAudit(
        severity: DrivelineVibrationSeverity.criticalPropshaftFailureRisk,
        totalVibrationVelocityMmPerSec: 9.4,
        primaryFaultDiagnosis: 'CRITICAL DRIVELINE SHUDDER: High amplitude vibration.',
        correctiveAction: 'Reduce speed immediately.',
        immediateInspectionRequired: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropshaftVibrationCard(
              audit: audit,
              shaftRpm: 2200.0,
              onBookDrivelineService: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Propshaft & U-Joint Harmonics'), findsOneWidget);
      expect(find.text('FAILURE RISK'), findsOneWidget);
      expect(find.text('Immediate Driveline Inspection'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PropshaftVibrationCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = PropshaftHealthAudit(
        severity: DrivelineVibrationSeverity.smoothBalanced,
        totalVibrationVelocityMmPerSec: 1.4,
        primaryFaultDiagnosis: 'DRIVELINE BALANCED: Rotational harmonics normal.',
        correctiveAction: 'Grease slip yoke at next PM.',
        immediateInspectionRequired: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: PropshaftVibrationCard(
                audit: audit,
                shaftRpm: 1800.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BALANCED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
