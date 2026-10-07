import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/liquid_slosh_baffle_surge_service.dart';
import 'package:evehicle_logbook/core/widgets/liquid_slosh_baffle_surge_card.dart';

void main() {
  group('Loop 139: LiquidSloshBaffleSurgeService & Card Tests', () {
    const service = LiquidSloshBaffleSurgeService();

    test('Full or low tank with damped wave reports nominal slosh status', () {
      const telemetry = LiquidSloshBaffleTelemetry(
        tankFillLevelPercent: 92.0,
        lateralSloshWaveAmplitudeMetres: 0.12,
        longitudinalSurgeForceKiloNewtons: 22.0,
        vehicleLateralGForce: 0.15,
        roadSpeedKmh: 75.0,
        hasInternalTransverseBaffles: true,
      );

      final result = service.auditLiquidStability(
        vehicleId: 'TANKER-92-DAMPED',
        telemetry: telemetry,
      );

      expect(result.status, LiquidSloshBaffleStatus.surgeDampedNominal);
      expect(result.isTankerStable, isTrue);
      expect(result.isImminentLiquidRolloverHazard, isFalse);
      expect(result.transportStabilityAdvisory, contains('NOMINAL'));
    });

    test('Partial ullage zone with wave displacement > 0.32m triggers warning', () {
      const telemetry = LiquidSloshBaffleTelemetry(
        tankFillLevelPercent: 60.0,
        lateralSloshWaveAmplitudeMetres: 0.38,
        longitudinalSurgeForceKiloNewtons: 45.0,
        vehicleLateralGForce: 0.20,
        roadSpeedKmh: 65.0,
        hasInternalTransverseBaffles: true,
      );

      final result = service.auditLiquidStability(
        vehicleId: 'TANKER-60-ULLAGE',
        telemetry: telemetry,
      );

      expect(result.status, LiquidSloshBaffleStatus.highCentrifugalSloshWarning);
      expect(result.isTankerStable, isFalse);
      expect(result.isImminentLiquidRolloverHazard, isFalse);
      expect(result.transportStabilityAdvisory, contains('WARNING: High liquid slosh inertia'));
    });

    test('High lateral G (>= 0.38) or high wave combined with cornering triggers critical rollover hazard', () {
      const telemetry = LiquidSloshBaffleTelemetry(
        tankFillLevelPercent: 55.0,
        lateralSloshWaveAmplitudeMetres: 0.52,
        longitudinalSurgeForceKiloNewtons: 92.0,
        vehicleLateralGForce: 0.39,
        roadSpeedKmh: 72.0,
        hasInternalTransverseBaffles: false,
      );

      final result = service.auditLiquidStability(
        vehicleId: 'TANKER-CRIT-SURGE',
        telemetry: telemetry,
      );

      expect(result.status, LiquidSloshBaffleStatus.criticalDynamicLiquidRollSurgeHazard);
      expect(result.isImminentLiquidRolloverHazard, isTrue);
      expect(result.transportStabilityAdvisory, contains('CRITICAL TANKER ROLLOVER HAZARD'));
    });

    testWidgets('LiquidSloshBaffleSurgeCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool stabilized = false;
      const telemetry = LiquidSloshBaffleTelemetry(
        tankFillLevelPercent: 52.0,
        lateralSloshWaveAmplitudeMetres: 0.65,
        longitudinalSurgeForceKiloNewtons: 88.0,
        vehicleLateralGForce: 0.36,
        roadSpeedKmh: 80.0,
        hasInternalTransverseBaffles: false,
      );

      final result = service.auditLiquidStability(
        vehicleId: 'ROAD-TRAIN-TANKER-99',
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
                child: LiquidSloshBaffleSurgeCard(
                  result: result,
                  onActivateTankerEscStabilizer: () {
                    stabilized = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tanker Liquid Slosh Sentry'), findsOneWidget);
      expect(find.textContaining('ROAD-TRAIN-TANKER-99'), findsOneWidget);
      expect(find.text('ROLLOVER SURGE'), findsOneWidget);

      final escBtn = find.text('Enact ESC Tanker Dynamic Roll Intervention');
      expect(escBtn, findsOneWidget);
      await tester.tap(escBtn);
      expect(stabilized, isTrue);
    });
  });
}
