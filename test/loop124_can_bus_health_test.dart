import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/can_bus_health_diagnostic_service.dart';
import 'package:evehicle_logbook/core/widgets/can_bus_health_diagnostic_card.dart';

void main() {
  group('Loop 124: CanBusHealthDiagnosticService & Card Tests', () {
    const service = CanBusHealthDiagnosticService();

    test('Clean CAN traffic with zero error frames reports nominal status', () {
      const telemetry = CanBusDiagnosticTelemetry(
        busUtilizationPercent: 32.5,
        transmitErrorCounter: 0,
        receiveErrorCounter: 0,
        errorFramesPerSecond: 0,
        canHighVoltageVolts: 3.45,
        canLowVoltageVolts: 1.55,
        busDifferentialVoltageVolts: 1.90,
      );

      final result = service.auditNetwork(
        networkSegment: 'Powertrain J1939 Bus #1',
        telemetry: telemetry,
      );

      expect(result.status, CanBusHealthStatus.busNominalZeroErrorFrames);
      expect(result.isBusHealthy, isTrue);
      expect(result.isNetworkDisabled, isFalse);
      expect(result.tec, 0);
      expect(result.networkAdvisory, contains('NOMINAL'));
    });

    test('Elevated bus utilization or error count triggers jitter warning', () {
      const telemetry = CanBusDiagnosticTelemetry(
        busUtilizationPercent: 78.0,
        transmitErrorCounter: 105,
        receiveErrorCounter: 40,
        errorFramesPerSecond: 14,
        canHighVoltageVolts: 3.30,
        canLowVoltageVolts: 1.70,
        busDifferentialVoltageVolts: 1.60,
      );

      final result = service.auditNetwork(
        networkSegment: 'Body Chassis CAN #2',
        telemetry: telemetry,
      );

      expect(result.status, CanBusHealthStatus.warningFrameDropJitterThreshold);
      expect(result.isBusHealthy, isFalse);
      expect(result.tec, 105);
      expect(result.networkAdvisory, contains('WARNING: Heavy CAN bus loading'));
    });

    test('TEC >= 256 or physical short circuit triggers critical bus-off lockout', () {
      const telemetry = CanBusDiagnosticTelemetry(
        busUtilizationPercent: 99.0,
        transmitErrorCounter: 256,
        receiveErrorCounter: 180,
        errorFramesPerSecond: 65,
        canHighVoltageVolts: 0.1,
        canLowVoltageVolts: 0.1,
        busDifferentialVoltageVolts: 0.0,
      );

      final result = service.auditNetwork(
        networkSegment: 'Braking & EBS Safety Bus',
        telemetry: telemetry,
      );

      expect(result.status, CanBusHealthStatus.criticalBusOffDominantLockout,);
      expect(result.isNetworkDisabled, isTrue);
      expect(result.networkAdvisory, contains('CRITICAL NETWORK FAILURE: CAN controller entered BUS-OFF'));
    });

    testWidgets('CanBusHealthDiagnosticCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool resetTriggered = false;
      const telemetry = CanBusDiagnosticTelemetry(
        busUtilizationPercent: 82.0,
        transmitErrorCounter: 110,
        receiveErrorCounter: 50,
        errorFramesPerSecond: 18,
        canHighVoltageVolts: 3.25,
        canLowVoltageVolts: 1.75,
        busDifferentialVoltageVolts: 1.50,
      );

      final result = service.auditNetwork(
        networkSegment: 'Telematics CAN-FD Primary',
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
                child: CanBusHealthDiagnosticCard(
                  result: result,
                  onResetBusTransceiver: () {
                    resetTriggered = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CAN-Bus Physical Network Sentry'), findsOneWidget);
      expect(find.text('Telematics CAN-FD Primary'), findsOneWidget);
      expect(find.text('BUS JITTER'), findsOneWidget);

      final resetBtn = find.text('Re-initialize Transceiver & Clear Bus-Off');
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      expect(resetTriggered, isTrue);
    });
  });
}
