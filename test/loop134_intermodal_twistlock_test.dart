import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/intermodal_twistlock_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/intermodal_twistlock_card.dart';

void main() {
  group('Loop 134: IntermodalTwistlockAuditorService & Card Tests', () {
    const service = IntermodalTwistlockAuditorService();

    test('All 4 twistlocks verified with secondary detent pins reports nominal status', () {
      const telemetry = IntermodalTwistlockTelemetry(
        totalCornerLocksCount: 4,
        lockedAndVerifiedCornersCount: 4,
        cornerVerticalLoadTonnes: 28.0,
        latchEngagementAngleDegrees: 90.0,
        vehicleRoadSpeedKmh: 80.0,
        isSecondaryDetentLockPinned: true,
      );

      final result = service.auditTwistlocks(
        vehicleId: 'SKELETAL-40FT-134-OK',
        telemetry: telemetry,
      );

      expect(result.status, IntermodalTwistlockStatus.twistlocksLockedAndGrounded);
      expect(result.isSafeToTransit, isTrue);
      expect(result.isImminentTipoverRisk, isFalse);
      expect(result.lockedCount, 4);
      expect(result.transportSafetyAdvisory, contains('NOMINAL'));
    });

    test('Missing secondary pin or partial angle triggers safety pin warning', () {
      const telemetry = IntermodalTwistlockTelemetry(
        totalCornerLocksCount: 4,
        lockedAndVerifiedCornersCount: 4,
        cornerVerticalLoadTonnes: 26.0,
        latchEngagementAngleDegrees: 80.0,
        vehicleRoadSpeedKmh: 0.0,
        isSecondaryDetentLockPinned: false,
      );

      final result = service.auditTwistlocks(
        vehicleId: 'SKELETAL-40FT-134-WARN',
        telemetry: telemetry,
      );

      expect(result.status, IntermodalTwistlockStatus.manualPositionDiscrepancyWarning);
      expect(result.isSafeToTransit, isFalse);
      expect(result.transportSafetyAdvisory, contains('WARNING: Corner twistlocks engaged but secondary safety latch'));
    });

    test('Unlatched lock (<4) while in motion on highway triggers critical rollover hazard', () {
      const telemetry = IntermodalTwistlockTelemetry(
        totalCornerLocksCount: 4,
        lockedAndVerifiedCornersCount: 2,
        cornerVerticalLoadTonnes: 32.0,
        latchEngagementAngleDegrees: 30.0,
        vehicleRoadSpeedKmh: 68.0,
        isSecondaryDetentLockPinned: false,
      );

      final result = service.auditTwistlocks(
        vehicleId: 'SKELETAL-40FT-134-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, IntermodalTwistlockStatus.criticalUnlatchedHighwayTipoverHazard);
      expect(result.isImminentTipoverRisk, isTrue);
      expect(result.transportSafetyAdvisory, contains('CRITICAL ROLLOVER HAZARD'));
    });

    testWidgets('IntermodalTwistlockCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool pinsVerified = false;
      const telemetry = IntermodalTwistlockTelemetry(
        totalCornerLocksCount: 4,
        lockedAndVerifiedCornersCount: 3,
        cornerVerticalLoadTonnes: 30.0,
        latchEngagementAngleDegrees: 70.0,
        vehicleRoadSpeedKmh: 0.0,
        isSecondaryDetentLockPinned: false,
      );

      final result = service.auditTwistlocks(
        vehicleId: 'PORT-CHASSIS-12',
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
                child: IntermodalTwistlockCard(
                  result: result,
                  onConfirmSecondaryLockPins: () {
                    pinsVerified = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Intermodal Twistlock Sentry'), findsOneWidget);
      expect(find.textContaining('PORT-CHASSIS-12'), findsOneWidget);
      expect(find.text('SAFETY PIN REQ'), findsOneWidget);

      final verifyBtn = find.text('Verify 4-Corner Twistlock Safety Pins');
      expect(verifyBtn, findsOneWidget);
      await tester.tap(verifyBtn);
      expect(pinsVerified, isTrue);
    });
  });
}
