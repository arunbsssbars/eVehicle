import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/brake_tandem_proportioning_service.dart';
import 'package:evehicle_logbook/core/widgets/brake_tandem_proportioning_card.dart';

void main() {
  group('Loop 138: BrakeTandemProportioningService & Card Tests', () {
    const service = BrakeTandemProportioningService();

    test('Synchronous brake application with low split delta reports balanced status', () {
      const telemetry = BrakeTandemProportioningTelemetry(
        steerAxleChamberPressureKPa: 420.0,
        driveAxleTandemChamberPressureKPa: 435.0,
        trailerAxleChamberPressureKPa: 430.0,
        steerAxleLiningTemperatureCelsius: 140.0,
        driveAxleLiningTemperatureCelsius: 148.0,
        vehicleDecelerationGForce: 0.28,
      );

      final result = service.auditBrakeProportioning(
        vehicleId: 'TRACTOR-EBS-138-OK',
        telemetry: telemetry,
      );

      expect(result.status, BrakeTandemProportioningStatus.brakeTorqueEvenlyDistributed);
      expect(result.isBrakingBalanced, isTrue);
      expect(result.isSevereSpinoutRisk, isFalse);
      expect(result.pressureSplitDeltaKPa, closeTo(15.0, 0.5));
      expect(result.balanceAdvisory, contains('NOMINAL'));
    });

    test('Split pressure delta > 75 kPa triggers timing imbalance warning', () {
      const telemetry = BrakeTandemProportioningTelemetry(
        steerAxleChamberPressureKPa: 480.0,
        driveAxleTandemChamberPressureKPa: 380.0,
        trailerAxleChamberPressureKPa: 420.0,
        steerAxleLiningTemperatureCelsius: 185.0,
        driveAxleLiningTemperatureCelsius: 120.0,
        vehicleDecelerationGForce: 0.24,
      );

      final result = service.auditBrakeProportioning(
        vehicleId: 'TRACTOR-EBS-138-WARN',
        telemetry: telemetry,
      );

      expect(result.status, BrakeTandemProportioningStatus.axleSplitPressureImbalanceWarning);
      expect(result.isBrakingBalanced, isFalse);
      expect(result.pressureSplitDeltaKPa, 100.0);
      expect(result.balanceAdvisory, contains('WARNING: Relay valve crack pressure timing imbalance'));
    });

    test('Severe split (>180 kPa) or lining temp delta >120C triggers critical spinout hazard', () {
      const telemetry = BrakeTandemProportioningTelemetry(
        steerAxleChamberPressureKPa: 220.0,
        driveAxleTandemChamberPressureKPa: 460.0,
        trailerAxleChamberPressureKPa: 400.0,
        steerAxleLiningTemperatureCelsius: 85.0,
        driveAxleLiningTemperatureCelsius: 225.0,
        vehicleDecelerationGForce: 0.42,
      );

      final result = service.auditBrakeProportioning(
        vehicleId: 'TRACTOR-EBS-138-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, BrakeTandemProportioningStatus.criticalSteerDriveBrakeSkewSpinoutHazard);
      expect(result.isSevereSpinoutRisk, isTrue);
      expect(result.pressureSplitDeltaKPa, 240.0);
      expect(result.balanceAdvisory, contains('CRITICAL BRAKE TIMING SKEW'));
    });

    testWidgets('BrakeTandemProportioningCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool calibrated = false;
      const telemetry = BrakeTandemProportioningTelemetry(
        steerAxleChamberPressureKPa: 460.0,
        driveAxleTandemChamberPressureKPa: 370.0,
        trailerAxleChamberPressureKPa: 410.0,
        steerAxleLiningTemperatureCelsius: 175.0,
        driveAxleLiningTemperatureCelsius: 115.0,
        vehicleDecelerationGForce: 0.22,
      );

      final result = service.auditBrakeProportioning(
        vehicleId: 'VOLVO-TRACTOR-50',
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
                child: BrakeTandemProportioningCard(
                  result: result,
                  onScheduleRelayValveCheck: () {
                    calibrated = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Brake Proportioning Sentry'), findsOneWidget);
      expect(find.textContaining('VOLVO-TRACTOR-50'), findsOneWidget);
      expect(find.text('TIMING SPLIT'), findsOneWidget);

      final calBtn = find.text('Calibrate Brake Relay Valves & Quick-Release');
      expect(calBtn, findsOneWidget);
      await tester.tap(calBtn);
      expect(calibrated, isTrue);
    });
  });
}
