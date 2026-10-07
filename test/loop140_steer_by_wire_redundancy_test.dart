import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/steer_by_wire_redundancy_service.dart';
import 'package:evehicle_logbook/core/widgets/steer_by_wire_redundancy_card.dart';

void main() {
  group('Loop 140: SteerByWireRedundancyService & Card Tests', () {
    const service = SteerByWireRedundancyService();

    test('Synchronized resolvers within 0.4 deg report nominal lockstep status', () {
      const telemetry = SteerByWireTelemetry(
        channelAAngleDeg: 12.15,
        channelBAngleDeg: 12.25,
        handwheelTargetAngleDeg: 12.20,
        rackTorqueLoadNm: 180.0,
        actuatorCurrentDrawAmps: 28.5,
        canSyncLatencyMs: 4.0,
      );

      final result = service.auditSteerByWireRedundancy(
        vehicleId: 'SBW-TRUCK-140-SYNC',
        telemetry: telemetry,
      );

      expect(result.status, SteerByWireStatus.dualChannelSynchronized);
      expect(result.isSynchronizedNominal, isTrue);
      expect(result.isCriticalSteeringHazard, isFalse);
      expect(result.angleMismatchDeg, closeTo(0.10, 0.01));
      expect(result.safetyAdvisory, contains('NOMINAL'));
    });

    test('Minor resolver skew (0.8 deg) or sync latency > 12ms triggers warning', () {
      const telemetry = SteerByWireTelemetry(
        channelAAngleDeg: 14.20,
        channelBAngleDeg: 15.00,
        handwheelTargetAngleDeg: 14.50,
        rackTorqueLoadNm: 220.0,
        actuatorCurrentDrawAmps: 42.0,
        canSyncLatencyMs: 14.0,
      );

      final result = service.auditSteerByWireRedundancy(
        vehicleId: 'SBW-TRUCK-140-WARN',
        telemetry: telemetry,
      );

      expect(result.status, SteerByWireStatus.actuatorTrackingDiscrepancyWarning);
      expect(result.isSynchronizedNominal, isFalse);
      expect(result.isCriticalSteeringHazard, isFalse);
      expect(result.angleMismatchDeg, closeTo(0.80, 0.01));
      expect(result.safetyAdvisory, contains('WARNING: Minor dual-channel tracking discrepancy'));
    });

    test('Large channel divergence (> 1.8 deg) or high latency triggers critical divergence hazard', () {
      const telemetry = SteerByWireTelemetry(
        channelAAngleDeg: 10.0,
        channelBAngleDeg: 12.5,
        handwheelTargetAngleDeg: 11.0,
        rackTorqueLoadNm: 310.0,
        actuatorCurrentDrawAmps: 72.0,
        canSyncLatencyMs: 28.0,
      );

      final result = service.auditSteerByWireRedundancy(
        vehicleId: 'SBW-TRUCK-140-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, SteerByWireStatus.criticalDualActuatorAngleDivergenceHazard);
      expect(result.isCriticalSteeringHazard, isTrue);
      expect(result.angleMismatchDeg, closeTo(2.50, 0.01));
      expect(result.safetyAdvisory, contains('CRITICAL STEER-BY-WIRE ANGLE DIVERGENCE'));
    });

    testWidgets('SteerByWireRedundancyCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool calibrated = false;
      const telemetry = SteerByWireTelemetry(
        channelAAngleDeg: 8.10,
        channelBAngleDeg: 8.85,
        handwheelTargetAngleDeg: 8.40,
        rackTorqueLoadNm: 195.0,
        actuatorCurrentDrawAmps: 34.0,
        canSyncLatencyMs: 13.0,
      );

      final result = service.auditSteerByWireRedundancy(
        vehicleId: 'AUTONOMOUS-RIG-SBW',
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
                child: SteerByWireRedundancyCard(
                  result: result,
                  onCalibrateSteeringResolvers: () {
                    calibrated = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Steer-by-Wire Actuator Sentry'), findsOneWidget);
      expect(find.textContaining('AUTONOMOUS-RIG-SBW'), findsOneWidget);
      expect(find.text('RESOLVER SKEW'), findsOneWidget);

      final calBtn = find.text('Perform Dual-Channel Resolver Zero-Calibration');
      expect(calBtn, findsOneWidget);
      await tester.tap(calBtn);
      expect(calibrated, isTrue);
    });
  });
}
