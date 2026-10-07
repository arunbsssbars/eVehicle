import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/axle_differential_lock_service.dart';
import 'package:evehicle_logbook/core/widgets/axle_differential_lock_card.dart';

void main() {
  group('Loop 121: AxleDifferentialLockService & Card Tests', () {
    const service = AxleDifferentialLockService();

    test('Open differential operation reports normal disengaged status', () {
      const telemetry = AxleDifferentialLockTelemetry(
        leftWheelSpeedKmh: 45.0,
        rightWheelSpeedKmh: 47.2,
        vehicleRoadSpeedKmh: 46.1,
        pneumaticActuatorPressureKPa: 0.0,
        isDashLockSwitchCommanded: false,
        isDogClutchProximitySensorTripped: false,
        steeringAngleDegrees: 5.0,
      );

      final result = service.auditAxleLock(
        vehicleId: 'TRUCK-AXLE-121-OK',
        axleDesignation: 'Drive Axle 1 Forward Tandem',
        telemetry: telemetry,
      );

      expect(result.status, AxleDifferentialLockStatus.openDifferentialDisengaged);
      expect(result.isSafeToOperate, isTrue);
      expect(result.isLocked, isFalse);
      expect(result.isDrivelineWindUpRisk, isFalse);
      expect(result.safetyAdvisory, contains('NOMINAL'));
    });

    test('Diff lock engaged in low-speed traction condition reports safe engagement', () {
      const telemetry = AxleDifferentialLockTelemetry(
        leftWheelSpeedKmh: 12.0,
        rightWheelSpeedKmh: 12.0,
        vehicleRoadSpeedKmh: 12.0,
        pneumaticActuatorPressureKPa: 680.0,
        isDashLockSwitchCommanded: true,
        isDogClutchProximitySensorTripped: true,
        steeringAngleDegrees: 2.0,
      );

      final result = service.auditAxleLock(
        vehicleId: 'TRUCK-AXLE-121-LOCK',
        axleDesignation: 'Drive Axle 2 Rear Tandem',
        telemetry: telemetry,
      );

      expect(result.status, AxleDifferentialLockStatus.crossLockEngagedNormalTraction);
      expect(result.isSafeToOperate, isTrue);
      expect(result.isLocked, isTrue);
      expect(result.isDrivelineWindUpRisk, isFalse);
      expect(result.safetyAdvisory, contains('TRACTION ENGAGED'));
    });

    test('Diff lock engaged at highway speeds or hard turn triggers critical wind-up binding hazard', () {
      const telemetry = AxleDifferentialLockTelemetry(
        leftWheelSpeedKmh: 58.0,
        rightWheelSpeedKmh: 58.0,
        vehicleRoadSpeedKmh: 58.0,
        pneumaticActuatorPressureKPa: 710.0,
        isDashLockSwitchCommanded: true,
        isDogClutchProximitySensorTripped: true,
        steeringAngleDegrees: 8.0,
      );

      final result = service.auditAxleLock(
        vehicleId: 'TRUCK-AXLE-121-CRIT',
        axleDesignation: 'Drive Axle 1 Forward Tandem',
        telemetry: telemetry,
      );

      expect(result.status, AxleDifferentialLockStatus.criticalPavementLockBindingHazard);
      expect(result.isSafeToOperate, isFalse);
      expect(result.isDrivelineWindUpRisk, isTrue);
      expect(result.safetyAdvisory, contains('CRITICAL HAZARD: Differential cross-lock engaged on hard pavement'));
    });

    testWidgets('AxleDifferentialLockCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool disengagedClicked = false;
      const telemetry = AxleDifferentialLockTelemetry(
        leftWheelSpeedKmh: 62.0,
        rightWheelSpeedKmh: 62.0,
        vehicleRoadSpeedKmh: 62.0,
        pneumaticActuatorPressureKPa: 700.0,
        isDashLockSwitchCommanded: true,
        isDogClutchProximitySensorTripped: true,
        steeringAngleDegrees: 12.0,
      );

      final result = service.auditAxleLock(
        vehicleId: 'MACK-TRACTOR-01',
        axleDesignation: 'Drive Axle 1',
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
                child: AxleDifferentialLockCard(
                  result: result,
                  onDisengageLock: () {
                    disengagedClicked = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Axle Differential Lock Sentry'), findsOneWidget);
      expect(find.textContaining('MACK-TRACTOR-01'), findsOneWidget);
      expect(find.text('WIND-UP BINDING'), findsOneWidget);

      final disengageBtn = find.text('Disengage Cross-Axle Lock Actuator');
      expect(disengageBtn, findsOneWidget);
      await tester.tap(disengageBtn);
      expect(disengagedClicked, isTrue);
    });
  });
}
