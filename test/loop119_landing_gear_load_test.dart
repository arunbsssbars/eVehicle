import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/landing_gear_load_splay_service.dart';
import 'package:evehicle_logbook/core/widgets/landing_gear_load_splay_card.dart';

void main() {
  group('Loop 119: LandingGearLoadSplayService & Card Tests', () {
    const service = LandingGearLoadSplayService();

    test('Plumb legs and balanced load reports plumb and stable status', () {
      const telemetry = LandingGearLoadTelemetry(
        curbsideLegLoadTonnes: 10.5,
        roadsideLegLoadTonnes: 11.2,
        angularSplayDegrees: 0.4,
        asphaltFootingPenetrationMm: 6.0,
        crossShaftTorqueNewtonMetres: 35.0,
      );

      final result = service.auditLandingGear(
        vehicleId: 'TRAILER-LEG-119-OK',
        telemetry: telemetry,
      );

      expect(result.status, LandingGearLoadSplayStatus.plumbAndStable);
      expect(result.isLegPlumbAndSound, isTrue);
      expect(result.isImminentTipoverRisk, isFalse);
      expect(result.loadAsymmetryTonnes, closeTo(0.7, 0.05));
      expect(result.safetyAdvisory, contains('NOMINAL'));
    });

    test('Splay angle > 1.2 or asphalt settlement triggers warning', () {
      const telemetry = LandingGearLoadTelemetry(
        curbsideLegLoadTonnes: 14.5,
        roadsideLegLoadTonnes: 9.5,
        angularSplayDegrees: 1.6,
        asphaltFootingPenetrationMm: 32.0,
        crossShaftTorqueNewtonMetres: 75.0,
      );

      final result = service.auditLandingGear(
        vehicleId: 'TRAILER-LEG-119-WARN',
        telemetry: telemetry,
      );

      expect(result.status, LandingGearLoadSplayStatus.splaySettlementWarning);
      expect(result.isLegPlumbAndSound, isFalse);
      expect(result.loadAsymmetryTonnes, closeTo(5.0, 0.05));
      expect(result.safetyAdvisory, contains('WARNING: Landing leg settlement'));
    });

    test('Severe splay (>= 2.5) or deep asphalt sinking triggers critical buckling hazard', () {
      const telemetry = LandingGearLoadTelemetry(
        curbsideLegLoadTonnes: 26.5,
        roadsideLegLoadTonnes: 16.0,
        angularSplayDegrees: 2.8,
        asphaltFootingPenetrationMm: 55.0,
        crossShaftTorqueNewtonMetres: 95.0,
      );

      final result = service.auditLandingGear(
        vehicleId: 'TRAILER-LEG-119-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, LandingGearLoadSplayStatus.criticalBucklingCollapseHazard);
      expect(result.isImminentTipoverRisk, isTrue);
      expect(result.safetyAdvisory, contains('CRITICAL HAZARD: Landing gear buckling'));
    });

    testWidgets('LandingGearLoadSplayCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool supportsDeployed = false;
      const telemetry = LandingGearLoadTelemetry(
        curbsideLegLoadTonnes: 15.0,
        roadsideLegLoadTonnes: 10.0,
        angularSplayDegrees: 1.5,
        asphaltFootingPenetrationMm: 30.0,
        crossShaftTorqueNewtonMetres: 72.0,
      );

      final result = service.auditLandingGear(
        vehicleId: 'REEFER-TRAILER-55',
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
                child: LandingGearLoadSplayCard(
                  result: result,
                  onDeployGroundSupports: () {
                    supportsDeployed = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Trailer Landing Gear Sentry'), findsOneWidget);
      expect(find.textContaining('REEFER-TRAILER-55'), findsOneWidget);
      expect(find.text('SINKING WARNING'), findsOneWidget);

      final deployBtn = find.text('Deploy Landing Gear Ground Outriggers');
      expect(deployBtn, findsOneWidget);
      await tester.tap(deployBtn);
      expect(supportsDeployed, isTrue);
    });
  });
}
