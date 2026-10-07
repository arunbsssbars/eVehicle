import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/trailer_coupling_service.dart';
import 'package:evehicle_logbook/core/widgets/trailer_coupling_card.dart';

void main() {
  group('Loop 46 - Trailer Coupling & Fifth Wheel Tests', () {
    const service = TrailerCouplingService();

    test('auditCoupling passes when all latches, airlines, and electrical circuits are secure', () {
      const telemetry = TrailerCouplingTelemetry(
        kingpinEngaged: true,
        secondarySafetyLatchEngaged: true,
        electricalUmbilicalConnected: true,
        emergencySupplyBar: 7.8,
        serviceBrakeBar: 7.5,
        vehicleSpeedKmh: 0.0,
      );

      final audit = service.auditCoupling(telemetry);
      expect(audit.status, CouplingSafetyStatus.secureLocked);
      expect(audit.safeToDepart, isTrue);
      expect(audit.requiresEmergencyStop, isFalse);
    });

    test('auditCoupling triggers critical emergency stop when unlatched while in motion', () {
      const telemetry = TrailerCouplingTelemetry(
        kingpinEngaged: false,
        secondarySafetyLatchEngaged: false,
        electricalUmbilicalConnected: true,
        emergencySupplyBar: 8.0,
        serviceBrakeBar: 7.0,
        vehicleSpeedKmh: 24.0, // Moving vehicle
      );

      final audit = service.auditCoupling(telemetry);
      expect(audit.status, CouplingSafetyStatus.unlatchedCriticalHazard);
      expect(audit.safeToDepart, isFalse);
      expect(audit.requiresEmergencyStop, isTrue);
    });

    test('auditCoupling blocks departure if secondary safety latch handle is open', () {
      const telemetry = TrailerCouplingTelemetry(
        kingpinEngaged: true,
        secondarySafetyLatchEngaged: false,
        electricalUmbilicalConnected: true,
        emergencySupplyBar: 8.0,
        serviceBrakeBar: 7.5,
        vehicleSpeedKmh: 0.0,
      );

      final audit = service.auditCoupling(telemetry);
      expect(audit.status, CouplingSafetyStatus.secondaryLatchOpen);
      expect(audit.safeToDepart, isFalse);
    });

    testWidgets('TrailerCouplingCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = TrailerCouplingAudit(
        status: CouplingSafetyStatus.secureLocked,
        safeToDepart: true,
        pneumaticPressureAdequate: true,
        statusSummary: 'FIFTH WHEEL SECURE: Kingpin, secondary wedge, dual air lines verified.',
        requiresEmergencyStop: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrailerCouplingCard(
              audit: audit,
              onPerformPullTest: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fifth Wheel & Kingpin Lock'), findsOneWidget);
      expect(find.text('LOCKED & READY'), findsOneWidget);
      expect(find.text('Log Pre-Trip Trailer Tug / Pull Test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TrailerCouplingCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = TrailerCouplingAudit(
        status: CouplingSafetyStatus.secondaryLatchOpen,
        safeToDepart: false,
        pneumaticPressureAdequate: true,
        statusSummary: 'SECONDARY LATCH WARNING: Kingpin seated but safety latch release handle not locked.',
        requiresEmergencyStop: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: TrailerCouplingCard(audit: audit),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LATCH OPEN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
