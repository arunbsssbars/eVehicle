import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/leaf_spring_ubolt_torque_service.dart';
import 'package:evehicle_logbook/core/widgets/leaf_spring_ubolt_torque_card.dart';

void main() {
  group('Loop 133: LeafSpringUboltTorqueService & Card Tests', () {
    const service = LeafSpringUboltTorqueService();

    test('Tight U-bolts with aligned center pin reports nominal clamped status', () {
      const telemetry = LeafSpringUboltTelemetry(
        uboltClampingPreloadKiloNewtons: 94.0,
        recommendedPreloadKiloNewtons: 95.0,
        leafSpringFanningOffsetMm: 1.2,
        axleSpringSeatWalkingDeltaMm: 0.8,
        isCenterPinAcousticallyFractured: false,
        grossAxleWeightTonnes: 9.0,
      );

      final result = service.auditUboltClamping(
        vehicleId: 'TRUCK-AXLE-133-OK',
        axleLocation: 'Drive Axle Tandem Forward',
        telemetry: telemetry,
      );

      expect(result.status, LeafSpringUboltTorqueStatus.uboltClampedNominal);
      expect(result.isClampingSecure, isTrue);
      expect(result.isAxleWalkImminent, isFalse);
      expect(result.clampingPreloadKN, 94.0);
      expect(result.clampingAdvisory, contains('NOMINAL'));
    });

    test('Loose U-bolts or leaf fanning triggers torque relaxation warning', () {
      const telemetry = LeafSpringUboltTelemetry(
        uboltClampingPreloadKiloNewtons: 68.0,
        recommendedPreloadKiloNewtons: 95.0,
        leafSpringFanningOffsetMm: 5.2,
        axleSpringSeatWalkingDeltaMm: 3.5,
        isCenterPinAcousticallyFractured: false,
        grossAxleWeightTonnes: 9.8,
      );

      final result = service.auditUboltClamping(
        vehicleId: 'TRUCK-AXLE-133-WARN',
        axleLocation: 'Trailer Tandem Rear',
        telemetry: telemetry,
      );

      expect(result.status, LeafSpringUboltTorqueStatus.preloadRelaxationWarning);
      expect(result.isClampingSecure, isFalse);
      expect(result.clampingAdvisory, contains('WARNING: Suspension U-bolt nut torque relaxation'));
    });

    test('Sheared center pin or severe axle walk (>=6mm) triggers critical hazard', () {
      const telemetry = LeafSpringUboltTelemetry(
        uboltClampingPreloadKiloNewtons: 48.0,
        recommendedPreloadKiloNewtons: 95.0,
        leafSpringFanningOffsetMm: 12.0,
        axleSpringSeatWalkingDeltaMm: 7.8,
        isCenterPinAcousticallyFractured: true,
        grossAxleWeightTonnes: 11.2,
      );

      final result = service.auditUboltClamping(
        vehicleId: 'TRUCK-AXLE-133-CRIT',
        axleLocation: 'Drive Axle 1',
        telemetry: telemetry,
      );

      expect(result.status, LeafSpringUboltTorqueStatus.criticalCenterPinShearAxleWalkHazard);
      expect(result.isAxleWalkImminent, isTrue);
      expect(result.clampingAdvisory, contains('CRITICAL SUSPENSION HAZARD'));
    });

    testWidgets('LeafSpringUboltTorqueCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool retorqueScheduled = false;
      const telemetry = LeafSpringUboltTelemetry(
        uboltClampingPreloadKiloNewtons: 50.0,
        recommendedPreloadKiloNewtons: 95.0,
        leafSpringFanningOffsetMm: 11.0,
        axleSpringSeatWalkingDeltaMm: 7.0,
        isCenterPinAcousticallyFractured: true,
        grossAxleWeightTonnes: 10.5,
      );

      final result = service.auditUboltClamping(
        vehicleId: 'LOGGING-TRUCK-55',
        axleLocation: 'Steer Axle 1',
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
                child: LeafSpringUboltTorqueCard(
                  result: result,
                  onScheduleRetorque: () {
                    retorqueScheduled = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Suspension U-Bolt Sentry'), findsOneWidget);
      expect(find.textContaining('LOGGING-TRUCK-55'), findsOneWidget);
      expect(find.text('AXLE WALK / SHEAR'), findsOneWidget);

      final retorqueBtn = find.text('Re-Torque U-Bolt Nuts to Factory Spec');
      expect(retorqueBtn, findsOneWidget);
      await tester.tap(retorqueBtn);
      expect(retorqueScheduled, isTrue);
    });
  });
}
