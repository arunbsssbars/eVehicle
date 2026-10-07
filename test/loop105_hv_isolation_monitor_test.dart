import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/hv_isolation_monitor_service.dart';
import 'package:evehicle_logbook/core/widgets/hv_isolation_monitor_card.dart';

void main() {
  group('Loop 105: EV High-Voltage Bus Chassis Dielectric Isolation Sentinel Tests', () {
    const service = HvIsolationMonitorService();

    test('High resistance over 500 Ohms/Volt reports safe isolation status', () {
      const telemetry = HvIsolationTelemetry(
        positiveRailToChassisKohm: 850.0,
        negativeRailToChassisKohm: 920.0,
        tractionPackVoltageVolts: 400.0,
        inverterAcLeakageMilliamps: 0.8,
        isContactorWelded: false,
      );

      final result = service.auditHvIsolation(
        vehicleId: 'EV-HV-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(HvIsolationStatus.normalHighResistance));
      expect(result.isSafeToOperate, isTrue);
      expect(result.isHighVoltageInterlockTripped, isFalse);
      expect(result.isolationOhmsPerVolt, greaterThanOrEqualTo(500.0));
      expect(result.safetyInterlockAction, contains('NOMINAL'));
    });

    test('Isolation collapse under 100 Ohms/Volt or welded contactor trips emergency interlock', () {
      const telemetry = HvIsolationTelemetry(
        positiveRailToChassisKohm: 28.0, // Dangerous chassis short
        negativeRailToChassisKohm: 35.0,
        tractionPackVoltageVolts: 800.0,
        inverterAcLeakageMilliamps: 14.5,
        isContactorWelded: true,
      );

      final result = service.auditHvIsolation(
        vehicleId: 'EV-HV-02',
        telemetry: telemetry,
      );

      expect(result.status, equals(HvIsolationStatus.criticalIsolationFaultChassisLeak));
      expect(result.isSafeToOperate, isFalse);
      expect(result.isHighVoltageInterlockTripped, isTrue);
      expect(result.safetyInterlockAction, contains('CRITICAL HAZARD'));
    });

    testWidgets('AQIL: HvIsolationMonitorCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = HvIsolationTelemetry(
        positiveRailToChassisKohm: 700.0,
        negativeRailToChassisKohm: 750.0,
        tractionPackVoltageVolts: 400.0,
        inverterAcLeakageMilliamps: 1.0,
      );
      final result = service.auditHvIsolation(vehicleId: 'EV-320', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HvIsolationMonitorCard(result: result),
            ),
          ),
        ),
      );

      expect(find.text('HV Isolation Resistance Sentry'), findsOneWidget);
      expect(find.text('ISOLATION SAFE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AQIL: HvIsolationMonitorCard scales gracefully under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = HvIsolationTelemetry(
        positiveRailToChassisKohm: 25.0,
        negativeRailToChassisKohm: 30.0,
        tractionPackVoltageVolts: 800.0,
        inverterAcLeakageMilliamps: 12.0,
      );
      final result = service.auditHvIsolation(vehicleId: 'EV-FONT', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: HvIsolationMonitorCard(result: result),
              ),
            ),
          ),
        ),
      );

      expect(find.text('CHASSIS LEAK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
