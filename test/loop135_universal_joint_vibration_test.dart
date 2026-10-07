import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/universal_joint_vibration_service.dart';
import 'package:evehicle_logbook/core/widgets/universal_joint_vibration_card.dart';

void main() {
  group('Loop 135: UniversalJointVibrationService & Card Tests', () {
    const service = UniversalJointVibrationService();

    test('Smooth driveline with low 2X vibration reports nominal phased status', () {
      const telemetry = UniversalJointVibrationTelemetry(
        propshaftRotationalSpeedRpm: 2400.0,
        secondOrderHarmonicVibrationMmPerSec: 1.8,
        drivelineWorkingAngleDegrees: 2.2,
        slipYokeSplineRadialPlayMm: 0.18,
        uJointSpiderTrunnionTemperatureCelsius: 58.0,
        continuousDriveshaftOperatingHours: 120.0,
      );

      final result = service.auditUniversalJoint(
        vehicleId: 'PROPSHAFT-135-OK',
        shaftSegment: 'Main Transmission to Carrier Bearing',
        telemetry: telemetry,
      );

      expect(result.status, UniversalJointVibrationStatus.drivelinePhasedNominal);
      expect(result.isDrivelineSmooth, isTrue);
      expect(result.isDriveshaftDropCatastrophicRisk, isFalse);
      expect(result.vibrationMmPerSec, 1.8);
      expect(result.harmonicAdvisory, contains('NOMINAL'));
    });

    test('Elevated 2X vibration or hot trunnions triggers wear warning', () {
      const telemetry = UniversalJointVibrationTelemetry(
        propshaftRotationalSpeedRpm: 2600.0,
        secondOrderHarmonicVibrationMmPerSec: 5.6,
        drivelineWorkingAngleDegrees: 4.2,
        slipYokeSplineRadialPlayMm: 0.65,
        uJointSpiderTrunnionTemperatureCelsius: 98.0,
        continuousDriveshaftOperatingHours: 450.0,
      );

      final result = service.auditUniversalJoint(
        vehicleId: 'PROPSHAFT-135-WARN',
        shaftSegment: 'Carrier Bearing to Rear Axle Differential',
        telemetry: telemetry,
      );

      expect(result.status, UniversalJointVibrationStatus.uJointTrunnionWearWarning);
      expect(result.isDrivelineSmooth, isFalse);
      expect(result.harmonicAdvisory, contains('WARNING: Propeller shaft universal joint needle bearing brinelling'));
    });

    test('Destructive vibration (>=9.0 mm/s) or trunnion overheating triggers driveshaft drop hazard', () {
      const telemetry = UniversalJointVibrationTelemetry(
        propshaftRotationalSpeedRpm: 2800.0,
        secondOrderHarmonicVibrationMmPerSec: 11.2,
        drivelineWorkingAngleDegrees: 6.2,
        slipYokeSplineRadialPlayMm: 1.4,
        uJointSpiderTrunnionTemperatureCelsius: 120.0,
        continuousDriveshaftOperatingHours: 600.0,
      );

      final result = service.auditUniversalJoint(
        vehicleId: 'PROPSHAFT-135-CRIT',
        shaftSegment: 'Transmission Slip Yoke Joint',
        telemetry: telemetry,
      );

      expect(result.status, UniversalJointVibrationStatus.criticalNeedleShatterDriveshaftDropHazard);
      expect(result.isDriveshaftDropCatastrophicRisk, isTrue);
      expect(result.harmonicAdvisory, contains('CRITICAL DRIVELINE HAZARD'));
    });

    testWidgets('UniversalJointVibrationCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool serviceScheduled = false;
      const telemetry = UniversalJointVibrationTelemetry(
        propshaftRotationalSpeedRpm: 2500.0,
        secondOrderHarmonicVibrationMmPerSec: 6.0,
        drivelineWorkingAngleDegrees: 4.5,
        slipYokeSplineRadialPlayMm: 0.7,
        uJointSpiderTrunnionTemperatureCelsius: 100.0,
        continuousDriveshaftOperatingHours: 400.0,
      );

      final result = service.auditUniversalJoint(
        vehicleId: 'FREIGHT-RIG-33',
        shaftSegment: 'Rear Tandem Inter-Axle Propshaft',
        telemetry: telemetry,
      );

      // Verify Compact 320px viewport with fontScale 1.5
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: UniversalJointVibrationCard(
                  result: result,
                  onScheduleDrivelineInspection: () {
                    serviceScheduled = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Universal Joint Sentry'), findsOneWidget);
      expect(find.textContaining('FREIGHT-RIG-33'), findsOneWidget);
      expect(find.text('2X VIBRATION'), findsOneWidget);

      final scheduleBtn = find.text('Schedule Driveline Balance & U-Joint Lube');
      expect(scheduleBtn, findsOneWidget);
      await tester.tap(scheduleBtn);
      expect(serviceScheduled, isTrue);
    });
  });
}
