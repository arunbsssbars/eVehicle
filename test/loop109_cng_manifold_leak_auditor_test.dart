import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/cng_manifold_leak_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/cng_manifold_leak_card.dart';

void main() {
  group('Loop 109: Commercial CNG / LNG Manifold Methane Leak Sentinel Tests', () {
    const service = CngManifoldLeakAuditorService();

    test('Sealed manifold and low ambient methane passes gas tightness inspection', () {
      const telemetry = CngManifoldTelemetry(
        manifoldPressureBar: 210.0,
        tankSurfaceTemperatureCelsius: 24.0,
        methaneConcentrationPpm: 25.0,
        lowerExplosiveLimitPercent: 0.8,
        isAutomaticShutoffSolenoidEnergized: true,
      );

      final result = service.auditCngManifold(
        vehicleId: 'CNG-BUS-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(CngManifoldStatus.normalSealedPressure));
      expect(result.isSafeToOperate, isTrue);
      expect(result.isExplosionHazard, isFalse);
      expect(result.safetyDirective, contains('NOMINAL'));
    });

    test('Methane concentration exceeding 20% LEL triggers emergency solenoid shutoff', () {
      const telemetry = CngManifoldTelemetry(
        manifoldPressureBar: 180.0,
        tankSurfaceTemperatureCelsius: 26.0,
        methaneConcentrationPpm: 12000.0, // High explosive gas pocket
        lowerExplosiveLimitPercent: 24.0, // Exceeds 20% legal limit
        isAutomaticShutoffSolenoidEnergized: true,
      );

      final result = service.auditCngManifold(
        vehicleId: 'CNG-BUS-02',
        telemetry: telemetry,
      );

      expect(result.status, equals(CngManifoldStatus.criticalMethaneLeakExplosionRisk));
      expect(result.isSafeToOperate, isFalse);
      expect(result.isExplosionHazard, isTrue);
      expect(result.isEmergencyCutoffTriggered, isTrue);
      expect(result.safetyDirective, contains('EXPLOSION HAZARD'));
    });

    testWidgets('AQIL: CngManifoldLeakCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = CngManifoldTelemetry(
        manifoldPressureBar: 205.0,
        tankSurfaceTemperatureCelsius: 22.0,
        methaneConcentrationPpm: 20.0,
        lowerExplosiveLimitPercent: 0.5,
        isAutomaticShutoffSolenoidEnergized: true,
      );
      final result = service.auditCngManifold(vehicleId: 'CNG-320', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CngManifoldLeakCard(result: result),
            ),
          ),
        ),
      );

      expect(find.text('CNG Manifold Methane Sentry'), findsOneWidget);
      expect(find.text('MANIFOLD SEALED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AQIL: CngManifoldLeakCard scales gracefully under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = CngManifoldTelemetry(
        manifoldPressureBar: 185.0,
        tankSurfaceTemperatureCelsius: 25.0,
        methaneConcentrationPpm: 9000.0,
        lowerExplosiveLimitPercent: 22.0,
        isAutomaticShutoffSolenoidEnergized: true,
      );
      final result = service.auditCngManifold(vehicleId: 'CNG-FONT', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: CngManifoldLeakCard(result: result),
              ),
            ),
          ),
        ),
      );

      expect(find.text('EXPLOSION RISK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
