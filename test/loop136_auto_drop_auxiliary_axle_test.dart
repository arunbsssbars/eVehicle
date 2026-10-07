import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/auto_drop_auxiliary_axle_service.dart';
import 'package:evehicle_logbook/core/widgets/auto_drop_auxiliary_axle_card.dart';

void main() {
  group('Loop 136: AutoDropAuxiliaryAxleService & Card Tests', () {
    const service = AutoDropAuxiliaryAxleService();

    test('Axle deployed with normal load reports armed nominal status', () {
      const telemetry = AutoDropAuxiliaryAxleTelemetry(
        isAuxiliaryAxleLoweredToPavement: true,
        isReverseGearEngaged: false,
        vehicleRoadSpeedKmh: 65.0,
        driveAxlePayloadTonnes: 8.8,
        isManualDashLiftSwitchHeld: false,
        steerAngleDegrees: 2.0,
      );

      final result = service.auditAutoDropLogic(
        vehicleId: 'DUMP-TRUCK-136-OK',
        telemetry: telemetry,
      );

      expect(result.status, AutoDropAuxiliaryAxleStatus.logicArmedNominal);
      expect(result.isInterlockSafe, isTrue);
      expect(result.isReverseScrubDanger, isFalse);
      expect(result.shouldAutoDropBeEnacted, isFalse);
      expect(result.interlockAdvisory, contains('NOMINAL'));
    });

    test('Overloaded drive axle with axle up triggers auto-drop mandate warning', () {
      const telemetry = AutoDropAuxiliaryAxleTelemetry(
        isAuxiliaryAxleLoweredToPavement: false,
        isReverseGearEngaged: false,
        vehicleRoadSpeedKmh: 42.0,
        driveAxlePayloadTonnes: 11.2,
        isManualDashLiftSwitchHeld: true,
        steerAngleDegrees: 0.0,
      );

      final result = service.auditAutoDropLogic(
        vehicleId: 'DUMP-TRUCK-136-WARN',
        telemetry: telemetry,
      );

      expect(result.status, AutoDropAuxiliaryAxleStatus.speedInterlockOverrideWarning);
      expect(result.isInterlockSafe, isFalse);
      expect(result.shouldAutoDropBeEnacted, isTrue);
      expect(result.interlockAdvisory, contains('WARNING: Driver holding manual lift override switch'));
    });

    test('Reversing with non-steer tag axle down in tight corner triggers reverse scrub hazard', () {
      const telemetry = AutoDropAuxiliaryAxleTelemetry(
        isAuxiliaryAxleLoweredToPavement: true,
        isReverseGearEngaged: true,
        vehicleRoadSpeedKmh: 6.0,
        driveAxlePayloadTonnes: 10.0,
        isManualDashLiftSwitchHeld: false,
        steerAngleDegrees: 22.0,
      );

      final result = service.auditAutoDropLogic(
        vehicleId: 'DUMP-TRUCK-136-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, AutoDropAuxiliaryAxleStatus.criticalReverseGearTireScrubShearHazard);
      expect(result.isReverseScrubDanger, isTrue);
      expect(result.shouldAutoLiftInReverseBeEnacted, isTrue);
      expect(result.interlockAdvisory, contains('CRITICAL TIRE SCRUB HAZARD'));
    });

    testWidgets('AutoDropAuxiliaryAxleCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool dropExecuted = false;
      const telemetry = AutoDropAuxiliaryAxleTelemetry(
        isAuxiliaryAxleLoweredToPavement: false,
        isReverseGearEngaged: false,
        vehicleRoadSpeedKmh: 35.0,
        driveAxlePayloadTonnes: 10.8,
        isManualDashLiftSwitchHeld: false,
        steerAngleDegrees: 1.0,
      );

      final result = service.auditAutoDropLogic(
        vehicleId: 'CONCRETE-MIXER-44',
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
                child: AutoDropAuxiliaryAxleCard(
                  result: result,
                  onExecuteAutoDrop: () {
                    dropExecuted = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Auxiliary Axle Auto-Drop Sentry'), findsOneWidget);
      expect(find.textContaining('CONCRETE-MIXER-44'), findsOneWidget);
      expect(find.text('AUTO-DROP MANDATE'), findsOneWidget);

      final dropBtn = find.text('Deploy Auxiliary Axle Down Now');
      expect(dropBtn, findsOneWidget);
      await tester.tap(dropBtn);
      expect(dropExecuted, isTrue);
    });
  });
}
