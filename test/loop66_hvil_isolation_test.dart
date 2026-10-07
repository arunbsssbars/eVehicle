import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/hvil_isolation_service.dart';
import 'package:evehicle_logbook/core/widgets/hvil_isolation_card.dart';

void main() {
  group('Loop 66 - HvilIsolationService Unit Tests', () {
    late HvilIsolationService service;

    setUp(() {
      service = const HvilIsolationService();
    });

    test('Healthy 800V EV returns secure HVIL and normal high isolation', () {
      const telemetry = HvilIsolationTelemetry(
        busVoltageVdc: 800.0,
        hvilLoopResistanceOhms: 2.1,
        posChassisIsolationResistanceKOhms: 1200.0, // 1.2 MOhm -> 1500 Ohms/V
        negChassisIsolationResistanceKOhms: 1100.0,
        pyrofuseResistanceOhms: 2.0,
        manualServiceDisconnectPlugged: true,
      );

      final audit = service.evaluateHvSafety(telemetry);

      expect(audit.hvilStatus, HvilCircuitStatus.closedSecure);
      expect(audit.isolationStatus, HvIsolationStatus.normalHighIsolation);
      expect(audit.contactorsPermittedToClose, isTrue);
      expect(audit.activeHighVoltageHazard, isFalse);
      expect(audit.minimumIsolationOhmsPerVolt, greaterThanOrEqualTo(1000.0));
    });

    test('Pulled MSD interlock opens circuit and inhibits contactors', () {
      const telemetry = HvilIsolationTelemetry(
        busVoltageVdc: 400.0,
        hvilLoopResistanceOhms: 1.8,
        posChassisIsolationResistanceKOhms: 900.0,
        negChassisIsolationResistanceKOhms: 950.0,
        pyrofuseResistanceOhms: 2.1,
        manualServiceDisconnectPlugged: false, // Pulled for maintenance
      );

      final audit = service.evaluateHvSafety(telemetry);

      expect(audit.hvilStatus, HvilCircuitStatus.openCircuitEmergencyShutdown);
      expect(audit.contactorsPermittedToClose, isFalse);
      expect(audit.activeHighVoltageHazard, isTrue);
      expect(audit.safetyAdvisory, contains('EMERGENCY DISCONNECT OPEN'));
    });

    test('Low chassis isolation triggers critical isolation fault lockout below 500 Ohms/Volt', () {
      const telemetry = HvilIsolationTelemetry(
        busVoltageVdc: 400.0,
        hvilLoopResistanceOhms: 2.4,
        posChassisIsolationResistanceKOhms: 120.0, // 120k / 400V = 300 Ohms/V (< 500)
        negChassisIsolationResistanceKOhms: 800.0,
        pyrofuseResistanceOhms: 2.0,
        manualServiceDisconnectPlugged: true,
      );

      final audit = service.evaluateHvSafety(telemetry);

      expect(audit.isolationStatus, HvIsolationStatus.criticalIsolationFaultLockout);
      expect(audit.contactorsPermittedToClose, isFalse);
      expect(audit.activeHighVoltageHazard, isTrue);
      expect(audit.minimumIsolationOhmsPerVolt, lessThan(500.0));
      expect(audit.recommendedAction, contains('Lockout-Tagout'));
    });
  });

  group('Loop 66 - HvilIsolationCard Widget & AQIL Tests', () {
    testWidgets('Renders properly in compact 320px viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const telemetry = HvilIsolationTelemetry(
        busVoltageVdc: 400.0,
        hvilLoopResistanceOhms: 2.3,
        posChassisIsolationResistanceKOhms: 1000.0,
        negChassisIsolationResistanceKOhms: 950.0,
        pyrofuseResistanceOhms: 2.1,
        manualServiceDisconnectPlugged: true,
      );

      const audit = HvilIsolationAudit(
        hvilStatus: HvilCircuitStatus.closedSecure,
        isolationStatus: HvIsolationStatus.normalHighIsolation,
        minimumIsolationOhmsPerVolt: 2375.0,
        contactorsPermittedToClose: true,
        activeHighVoltageHazard: false,
        safetyAdvisory: 'HIGH VOLTAGE SECURE: HVIL closed, isolation robust.',
        recommendedAction: 'Vehicle HV powertrain fully operational.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HvilIsolationCard(
                audit: audit,
                telemetry: telemetry,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EV HVIL & Isolation Guard'), findsOneWidget);
      expect(find.text('HV INTERLOCK SECURE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders critical hazard lockout and scales under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const telemetry = HvilIsolationTelemetry(
        busVoltageVdc: 800.0,
        hvilLoopResistanceOhms: 65.0,
        posChassisIsolationResistanceKOhms: 80.0,
        negChassisIsolationResistanceKOhms: 120.0,
        pyrofuseResistanceOhms: 2.2,
        manualServiceDisconnectPlugged: true,
      );

      const audit = HvilIsolationAudit(
        hvilStatus: HvilCircuitStatus.openCircuitEmergencyShutdown,
        isolationStatus: HvIsolationStatus.criticalIsolationFaultLockout,
        minimumIsolationOhmsPerVolt: 100.0,
        contactorsPermittedToClose: false,
        activeHighVoltageHazard: true,
        safetyAdvisory: 'CRITICAL CHASSIS LEAKAGE: Breach below ISO 6469-1 threshold!',
        recommendedAction: 'Lockout-Tagout (LOTO) active. HV main contactors locked open.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: HvilIsolationCard(
                  audit: audit,
                  telemetry: telemetry,
                  onDispatchEvTechnician: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HV HAZARD LOCKOUT'), findsOneWidget);
      expect(find.text('Dispatch Certified EV Technician'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
