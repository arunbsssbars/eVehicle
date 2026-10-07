import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/articulation_joint_stabilizer_service.dart';
import 'package:evehicle_logbook/core/widgets/articulation_joint_stabilizer_card.dart';

void main() {
  group('Loop 125: ArticulationJointStabilizerService & Card Tests', () {
    const service = ArticulationJointStabilizerService();

    test('Moderate articulation angle and balanced cylinders report synchronous status', () {
      const telemetry = ArticulationJointTelemetry(
        articulationAngleDegrees: 12.0,
        articulationYawRateDegreesPerSec: 4.5,
        portCylinderPressureKPa: 12500.0,
        starboardCylinderPressureKPa: 13200.0,
        vehicleGroundSpeedKmh: 35.0,
        steeringHandwheelAngleDegrees: 140.0,
      );

      final result = service.auditArticulation(
        vehicleId: 'BUS-ARTIC-125-OK',
        telemetry: telemetry,
      );

      expect(result.status, ArticulationJointStatus.jointPlumbSynchronous);
      expect(result.isArticulatedJointSafe, isTrue);
      expect(result.isCriticalJackknifeRisk, isFalse);
      expect(result.cylinderDeltaKPa, closeTo(700.0, 5.0));
      expect(result.stabilizationAdvisory, contains('NOMINAL'));
    });

    test('High cylinder pressure split triggers yaw drift warning', () {
      const telemetry = ArticulationJointTelemetry(
        articulationAngleDegrees: 36.0,
        articulationYawRateDegreesPerSec: 12.0,
        portCylinderPressureKPa: 18500.0,
        starboardCylinderPressureKPa: 14200.0,
        vehicleGroundSpeedKmh: 22.0,
        steeringHandwheelAngleDegrees: 380.0,
      );

      final result = service.auditArticulation(
        vehicleId: 'BUS-ARTIC-125-WARN',
        telemetry: telemetry,
      );

      expect(result.status, ArticulationJointStatus.yawDriftAlignmentWarning);
      expect(result.isArticulatedJointSafe, isFalse);
      expect(result.cylinderDeltaKPa, closeTo(4300.0, 5.0));
      expect(result.stabilizationAdvisory, contains('WARNING: Hydraulic articulation cylinder pressure split'));
    });

    test('Extreme articulation angle (>=46) triggers critical jackknife lock hazard', () {
      const telemetry = ArticulationJointTelemetry(
        articulationAngleDegrees: 48.5,
        articulationYawRateDegreesPerSec: 32.0,
        portCylinderPressureKPa: 22000.0,
        starboardCylinderPressureKPa: 9500.0,
        vehicleGroundSpeedKmh: 42.0,
        steeringHandwheelAngleDegrees: 180.0,
      );

      final result = service.auditArticulation(
        vehicleId: 'BUS-ARTIC-125-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, ArticulationJointStatus.criticalJackknifeLimpHazard);
      expect(result.isCriticalJackknifeRisk, isTrue);
      expect(result.stabilizationAdvisory, contains('CRITICAL HAZARD: Articulated joint jackknife threshold exceeded'));
    });

    testWidgets('ArticulationJointStabilizerCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool lockEngaged = false;
      const telemetry = ArticulationJointTelemetry(
        articulationAngleDegrees: 47.0,
        articulationYawRateDegreesPerSec: 29.0,
        portCylinderPressureKPa: 21500.0,
        starboardCylinderPressureKPa: 11000.0,
        vehicleGroundSpeedKmh: 38.0,
        steeringHandwheelAngleDegrees: 200.0,
      );

      final result = service.auditArticulation(
        vehicleId: 'METRO-TRANSIT-77',
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
                child: ArticulationJointStabilizerCard(
                  result: result,
                  onTriggerAntiJackknifeLock: () {
                    lockEngaged = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Articulation Joint Sentry'), findsOneWidget);
      expect(find.textContaining('METRO-TRANSIT-77'), findsOneWidget);
      expect(find.text('JACKKNIFE RISK'), findsOneWidget);

      final lockBtn = find.text('Engage Hydraulic Anti-Jackknife Brake');
      expect(lockBtn, findsOneWidget);
      await tester.tap(lockBtn);
      expect(lockEngaged, isTrue);
    });
  });
}
