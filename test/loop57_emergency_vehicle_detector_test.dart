import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/emergency_vehicle_detector_service.dart';
import 'package:evehicle_logbook/core/widgets/emergency_vehicle_detector_card.dart';

void main() {
  group('Loop 57 - Emergency Siren & Move-Over Tests', () {
    const service = EmergencyVehicleDetectorService();

    test('evaluateSiren reports normal traffic when no sirens or optical strobes active', () {
      const telemetry = SirenDetectorTelemetry(
        dominantFrequencyHz: 250.0, // Normal road tire roar
        acousticVolumeDecibels: 65.0,
        opticalStrobeRateHz: 0.0,
        approachingFromRear: false,
        estimatedDistanceMeters: 500.0,
      );

      final audit = service.evaluateSiren(telemetry);
      expect(audit.status, EmergencyYieldStatus.noEmergencyVehicleDetected);
      expect(audit.requiresImmediateLaneChange, isFalse);
    });

    test('evaluateSiren triggers urgent move-over alert when ambulance approaches rapidly from rear', () {
      const telemetry = SirenDetectorTelemetry(
        dominantFrequencyHz: 920.0, // Ambulance yelp pattern
        acousticVolumeDecibels: 88.0,
        opticalStrobeRateHz: 1.8,   // High-intensity beacon flash
        approachingFromRear: true,
        estimatedDistanceMeters: 75.0, // Closing rapidly
      );

      final audit = service.evaluateSiren(telemetry);
      expect(audit.status, EmergencyYieldStatus.imminentYieldRequired);
      expect(audit.estimatedServiceType, EmergencyServiceType.ambulanceMedical);
      expect(audit.requiresImmediateLaneChange, isTrue);
      expect(audit.timeToOvertakeSeconds, lessThan(8.0));
    });

    test('evaluateSiren classifies police pursuit siren frequency accurately', () {
      const telemetry = SirenDetectorTelemetry(
        dominantFrequencyHz: 1350.0, // High-pitch police electronic wail
        acousticVolumeDecibels: 76.0,
        opticalStrobeRateHz: 1.5,
        approachingFromRear: false,
        estimatedDistanceMeters: 250.0,
      );

      final audit = service.evaluateSiren(telemetry);
      expect(audit.estimatedServiceType, EmergencyServiceType.policePursuit);
      expect(audit.status, EmergencyYieldStatus.distantSirenAdvisory);
    });

    testWidgets('EmergencyVehicleDetectorCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = MoveOverSafetyAudit(
        status: EmergencyYieldStatus.imminentYieldRequired,
        estimatedServiceType: EmergencyServiceType.ambulanceMedical,
        timeToOvertakeSeconds: 4.8,
        yieldAdvisory: 'MOVE-OVER ALERT! Safely merge right!',
        requiresImmediateLaneChange: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmergencyVehicleDetectorCard(
              audit: audit,
              currentDistanceMeters: 72.0,
              onAcknowledgeYield: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acoustic Siren & Move-Over Guard'), findsOneWidget);
      expect(find.text('MOVE OVER NOW'), findsOneWidget);
      expect(find.text('MOVE RIGHT & YIELD CORRIDOR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EmergencyVehicleDetectorCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = MoveOverSafetyAudit(
        status: EmergencyYieldStatus.noEmergencyVehicleDetected,
        estimatedServiceType: EmergencyServiceType.none,
        timeToOvertakeSeconds: 99.0,
        yieldAdvisory: 'TRAFFIC NORMAL: Zero active emergency sirens.',
        requiresImmediateLaneChange: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: EmergencyVehicleDetectorCard(
                audit: audit,
                currentDistanceMeters: 500.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NORMAL TRAFFIC'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
