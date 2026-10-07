import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/fleet_platooning_service.dart';
import 'package:evehicle_logbook/core/widgets/fleet_platooning_card.dart';

void main() {
  group('Loop 60 - Fleet Platooning & Slipstream Tests', () {
    const service = FleetPlatooningService();

    test('evaluatePlatoon reports solo mode when truck count is 1', () {
      const telemetry = V2vPlatoonTelemetry(
        platoonId: 'PLT-SOLO',
        role: PlatoonRole.soloDissolved,
        interVehicleGapMeters: 50.0,
        vehicleSpeedKmh: 85.0,
        v2vPacketLatencyMs: 0,
        leadVehicleBrakeCommandG: 0.0,
        convoyTruckCount: 1,
      );

      final audit = service.evaluatePlatoon(telemetry);
      expect(audit.state, PlatoonCouplingState.safeCruisingGap);
      expect(audit.aerodynamicFuelSavingsPercent, 0.0);
      expect(audit.requiresEmergencyDecouple, isFalse);
    });

    test('evaluatePlatoon verifies aerodynamic lock with high fuel savings for follower', () {
      // 85 km/h is ~23.6 m/s; 18m gap corresponds to ~0.76s time headway
      const telemetry = V2vPlatoonTelemetry(
        platoonId: 'PLT-EU-402',
        role: PlatoonRole.followerMiddle,
        interVehicleGapMeters: 18.0,
        vehicleSpeedKmh: 85.0,
        v2vPacketLatencyMs: 12, // Low latency radio link
        leadVehicleBrakeCommandG: -0.05,
        convoyTruckCount: 3,
      );

      final audit = service.evaluatePlatoon(telemetry);
      expect(audit.state, PlatoonCouplingState.tightAerodynamicLock);
      expect(audit.aerodynamicFuelSavingsPercent, greaterThan(10.0));
      expect(audit.synchronizedBrakeArmed, isTrue);
      expect(audit.requiresEmergencyDecouple, isFalse);
    });

    test('evaluatePlatoon triggers emergency decouple on sudden lead braking or packet loss', () {
      const telemetry = V2vPlatoonTelemetry(
        platoonId: 'PLT-EU-402',
        role: PlatoonRole.followerMiddle,
        interVehicleGapMeters: 18.0,
        vehicleSpeedKmh: 85.0,
        v2vPacketLatencyMs: 14,
        leadVehicleBrakeCommandG: -0.65, // Emergency stop by lead vehicle
        convoyTruckCount: 3,
      );

      final audit = service.evaluatePlatoon(telemetry);
      expect(audit.state, PlatoonCouplingState.emergencyDecouple);
      expect(audit.requiresEmergencyDecouple, isTrue);
    });

    testWidgets('FleetPlatooningCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = PlatoonSafetyAudit(
        state: PlatoonCouplingState.tightAerodynamicLock,
        timeHeadwaySeconds: 0.85,
        aerodynamicFuelSavingsPercent: 14.2,
        statusSummary: 'AERODYNAMIC LOCK: Drafting in slipstream at 0.85s headway.',
        synchronizedBrakeArmed: true,
        requiresEmergencyDecouple: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FleetPlatooningCard(
              audit: audit,
              platoonId: 'PLT-001',
              role: PlatoonRole.followerMiddle,
              onDecouplePlatoon: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('V2V Autonomous Platooning'), findsOneWidget);
      expect(find.text('AERO LOCKED'), findsOneWidget);
      expect(find.text('Manually Decouple from Platoon Convoy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('FleetPlatooningCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = PlatoonSafetyAudit(
        state: PlatoonCouplingState.safeCruisingGap,
        timeHeadwaySeconds: 1.5,
        aerodynamicFuelSavingsPercent: 7.5,
        statusSummary: 'CRUISING GAP: Safe spacing maintained.',
        synchronizedBrakeArmed: true,
        requiresEmergencyDecouple: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: FleetPlatooningCard(
                audit: audit,
                platoonId: 'PLT-002',
                role: PlatoonRole.leadVehicle,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CRUISING'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
