import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/vru_blind_spot_service.dart';
import 'package:evehicle_logbook/core/widgets/vru_blind_spot_card.dart';

void main() {
  group('Loop 54 - VRU Blind Spot Radar Tests', () {
    const service = VruBlindSpotService();

    test('evaluateBlindSpot reports corridor clear when no targets detected', () {
      const telemetry = BlindSpotRadarTelemetry(
        targetDetected: false,
        targetType: VruTargetType.none,
        lateralDistanceMeters: 10.0,
        longitudinalDistanceMeters: 20.0,
        relativeSpeedMps: 0.0,
        turnSignalActive: false,
        steeringAngleDeg: 0.0,
      );

      final audit = service.evaluateBlindSpot(telemetry);
      expect(audit.threatLevel, VruThreatLevel.clearNoHazard);
      expect(audit.emergencyBrakeInterventionRequired, isFalse);
    });

    test('evaluateBlindSpot triggers advisory when cyclist detected but vehicle driving straight', () {
      const telemetry = BlindSpotRadarTelemetry(
        targetDetected: true,
        targetType: VruTargetType.cyclistBicycle,
        lateralDistanceMeters: 2.2,
        longitudinalDistanceMeters: 5.0,
        relativeSpeedMps: 1.2,
        turnSignalActive: false, // Driving straight
        steeringAngleDeg: 0.5,
      );

      final audit = service.evaluateBlindSpot(telemetry);
      expect(audit.threatLevel, VruThreatLevel.vruDetectedAdvisory);
      expect(audit.emergencyBrakeInterventionRequired, isFalse);
    });

    test('evaluateBlindSpot triggers imminent collision alert when driver attempts turn across VRU path', () {
      const telemetry = BlindSpotRadarTelemetry(
        targetDetected: true,
        targetType: VruTargetType.cyclistBicycle,
        lateralDistanceMeters: 0.9, // Tight alongside truck
        longitudinalDistanceMeters: 2.0,
        relativeSpeedMps: 2.5,
        turnSignalActive: true, // Turn indicator on
        steeringAngleDeg: 14.0, // Wheel turned toward cyclist
      );

      final audit = service.evaluateBlindSpot(telemetry);
      expect(audit.threatLevel, VruThreatLevel.imminentCollisionAlert);
      expect(audit.emergencyBrakeInterventionRequired, isTrue);
      expect(audit.timeToCollisionSeconds, lessThanOrEqualTo(2.2));
    });

    testWidgets('VruBlindSpotCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = VruBlindSpotAudit(
        threatLevel: VruThreatLevel.imminentCollisionAlert,
        targetType: VruTargetType.cyclistBicycle,
        timeToCollisionSeconds: 1.4,
        warningMessage: 'IMMINENT VRU COLLISION! Abort turn!',
        emergencyBrakeInterventionRequired: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VruBlindSpotCard(
              audit: audit,
              currentLateralDistanceMeters: 0.8,
              onAcknowledgeAlert: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Blind Spot VRU & Cyclist Guard'), findsOneWidget);
      expect(find.text('COLLISION HAZARD'), findsOneWidget);
      expect(find.text('ABORT TURN - VRU IN PATH'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('VruBlindSpotCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = VruBlindSpotAudit(
        threatLevel: VruThreatLevel.clearNoHazard,
        targetType: VruTargetType.none,
        timeToCollisionSeconds: 99.0,
        warningMessage: 'BLIND SPOT CLEAR.',
        emergencyBrakeInterventionRequired: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: VruBlindSpotCard(
                audit: audit,
                currentLateralDistanceMeters: 10.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CORRIDOR CLEAR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
