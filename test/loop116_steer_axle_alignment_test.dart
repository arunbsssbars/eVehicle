import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/steer_axle_alignment_service.dart';
import 'package:evehicle_logbook/core/widgets/steer_axle_alignment_card.dart';

void main() {
  group('Loop 116: SteerAxleAlignmentService & Card Tests', () {
    const service = SteerAxleAlignmentService();

    test('Toe-in and camber within specs reports within tolerances status', () {
      const telemetry = SteerAxleAlignmentTelemetry(
        toeInDegrees: 0.10,
        camberDegrees: 0.25,
        casterDegrees: 4.5,
        dynamicSideSlipMetresPerKm: 1.8,
        shoulderTireTreadDepthMm: 12.0,
        centerTireTreadDepthMm: 12.2,
      );

      final result = service.auditAlignment(
        vehicleId: 'TRUCK-AXLE-116-OK',
        telemetry: telemetry,
      );

      expect(result.status, SteerAxleAlignmentStatus.withinTolerances);
      expect(result.isAlignedCorrectly, isTrue);
      expect(result.isSevereWanderRisk, isFalse);
      expect(result.scrubDeltaMm, closeTo(0.2, 0.05));
      expect(result.alignmentAdvisory, contains('NOMINAL'));
    });

    test('Elevated side-slip or slight toe deviation triggers scuff drift warning', () {
      const telemetry = SteerAxleAlignmentTelemetry(
        toeInDegrees: 0.28,
        camberDegrees: 0.40,
        casterDegrees: 4.8,
        dynamicSideSlipMetresPerKm: 3.8,
        shoulderTireTreadDepthMm: 9.5,
        centerTireTreadDepthMm: 11.5,
      );

      final result = service.auditAlignment(
        vehicleId: 'TRUCK-AXLE-116-WARN',
        telemetry: telemetry,
      );

      expect(result.status, SteerAxleAlignmentStatus.abnormalScuffAlignmentDrift);
      expect(result.isAlignedCorrectly, isFalse);
      expect(result.scrubDeltaMm, closeTo(2.0, 0.05));
      expect(result.alignmentAdvisory, contains('WARNING: Steer axle toe/camber drift'));
    });

    test('Excessive side-slip (>= 6m/km) or severe toe out triggers critical wander hazard', () {
      const telemetry = SteerAxleAlignmentTelemetry(
        toeInDegrees: -0.35,
        camberDegrees: -1.2,
        casterDegrees: 3.1,
        dynamicSideSlipMetresPerKm: 7.2,
        shoulderTireTreadDepthMm: 6.0,
        centerTireTreadDepthMm: 10.5,
      );

      final result = service.auditAlignment(
        vehicleId: 'TRUCK-AXLE-116-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, SteerAxleAlignmentStatus.criticalSteerWanderBlowoutRisk);
      expect(result.isSevereWanderRisk, isTrue);
      expect(result.alignmentAdvisory, contains('CRITICAL HAZARD'));
    });

    testWidgets('SteerAxleAlignmentCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool alignmentBooked = false;
      const telemetry = SteerAxleAlignmentTelemetry(
        toeInDegrees: 0.32,
        camberDegrees: 0.8,
        casterDegrees: 4.0,
        dynamicSideSlipMetresPerKm: 4.5,
        shoulderTireTreadDepthMm: 8.0,
        centerTireTreadDepthMm: 10.2,
      );

      final result = service.auditAlignment(
        vehicleId: 'FLEET-STEER-88',
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
                child: SteerAxleAlignmentCard(
                  result: result,
                  onScheduleAlignment: () {
                    alignmentBooked = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Steer Axle Alignment Sentry'), findsOneWidget);
      expect(find.textContaining('FLEET-STEER-88'), findsOneWidget);
      expect(find.text('SCUFF DRIFT'), findsOneWidget);

      final bookBtn = find.text('Book 3-Axle Laser Alignment Service');
      expect(bookBtn, findsOneWidget);
      await tester.tap(bookBtn);
      expect(alignmentBooked, isTrue);
    });
  });
}
