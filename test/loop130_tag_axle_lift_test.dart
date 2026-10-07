import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/tag_axle_lift_suspension_service.dart';
import 'package:evehicle_logbook/core/widgets/tag_axle_lift_suspension_card.dart';

void main() {
  group('Loop 130: TagAxleLiftSuspensionService & Card Tests', () {
    const service = TagAxleLiftSuspensionService();

    test('Tag axle deployed carrying legal payload reports normal compliant status', () {
      const telemetry = TagAxleLiftTelemetry(
        isTagAxleLiftedRetracted: false,
        liftBagPressureKPa: 0.0,
        rideBellowsPressureKPa: 520.0,
        actualDriveAxleLoadTonnes: 8.5,
        vehicleGrossWeightTonnes: 26.0,
        roadSpeedKmh: 80.0,
      );

      final result = service.auditTagAxle(
        vehicleId: 'TRUCK-AXLE-130-OK',
        telemetry: telemetry,
      );

      expect(result.status, TagAxleLiftSuspensionStatus.tagAxleDeployedLoadBearing);
      expect(result.isWeightCompliant, isTrue);
      expect(result.isAxleLifted, isFalse);
      expect(result.overloadTonnes, 0.0);
      expect(result.complianceAdvisory, contains('NOMINAL'));
    });

    test('Low ride bellows pressure triggers lift bag pressure warning', () {
      const telemetry = TagAxleLiftTelemetry(
        isTagAxleLiftedRetracted: false,
        liftBagPressureKPa: 0.0,
        rideBellowsPressureKPa: 280.0,
        actualDriveAxleLoadTonnes: 9.2,
        vehicleGrossWeightTonnes: 24.0,
        roadSpeedKmh: 65.0,
      );

      final result = service.auditTagAxle(
        vehicleId: 'TRUCK-AXLE-130-WARN',
        telemetry: telemetry,
      );

      expect(result.status, TagAxleLiftSuspensionStatus.liftBagPressureWarning);
      expect(result.complianceAdvisory, contains('WARNING: Tag axle suspension air bellows pressure low'));
    });

    test('Retracted tag axle with severe drive axle overload (>=1.5T) triggers critical violation', () {
      const telemetry = TagAxleLiftTelemetry(
        isTagAxleLiftedRetracted: true,
        liftBagPressureKPa: 780.0,
        rideBellowsPressureKPa: 0.0,
        actualDriveAxleLoadTonnes: 12.4,
        vehicleGrossWeightTonnes: 28.0,
        roadSpeedKmh: 85.0,
      );

      final result = service.auditTagAxle(
        vehicleId: 'TRUCK-AXLE-130-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, TagAxleLiftSuspensionStatus.criticalOverGrossAxleWeightRatingHazard);
      expect(result.isWeightCompliant, isFalse);
      expect(result.overloadTonnes, closeTo(2.4, 0.05));
      expect(result.complianceAdvisory, contains('CRITICAL WEIGHT VIOLATION'));
    });

    testWidgets('TagAxleLiftSuspensionCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool autoDropClicked = false;
      const telemetry = TagAxleLiftTelemetry(
        isTagAxleLiftedRetracted: true,
        liftBagPressureKPa: 800.0,
        rideBellowsPressureKPa: 0.0,
        actualDriveAxleLoadTonnes: 12.8,
        vehicleGrossWeightTonnes: 30.0,
        roadSpeedKmh: 75.0,
      );

      final result = service.auditTagAxle(
        vehicleId: 'HEAVY-HAUL-88',
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
                child: TagAxleLiftSuspensionCard(
                  result: result,
                  onAutoDropTagAxle: () {
                    autoDropClicked = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tag / Pusher Axle Sentry'), findsOneWidget);
      expect(find.textContaining('HEAVY-HAUL-88'), findsOneWidget);
      expect(find.text('OVERLOAD DANGER'), findsOneWidget);

      final dropBtn = find.text('Auto-Drop Tag Axle to Road Surface');
      expect(dropBtn, findsOneWidget);
      await tester.tap(dropBtn);
      expect(autoDropClicked, isTrue);
    });
  });
}
