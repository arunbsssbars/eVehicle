import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/dual_tire_differential_service.dart';
import 'package:evehicle_logbook/core/widgets/dual_tire_differential_card.dart';

void main() {
  group('Loop 120: DualTireDifferentialService & Card Tests', () {
    const service = DualTireDifferentialService();

    test('Matched companion dual tire pressure and temp reports duals balanced status', () {
      const telemetry = DualTireDifferentialTelemetry(
        innerTireColdPressurePsi: 104.0,
        outerTireColdPressurePsi: 106.0,
        innerTireTemperatureCelsius: 52.0,
        outerTireTemperatureCelsius: 50.0,
        wheelHubSpeedKmh: 90.0,
      );

      final result = service.auditDualAssembly(
        vehicleId: 'TRUCK-DUAL-120-OK',
        axlePosition: 'Drive Axle 1 - Right Dual',
        telemetry: telemetry,
      );

      expect(result.status, DualTireDifferentialStatus.dualsBalanced);
      expect(result.isDualPairBalanced, isTrue);
      expect(result.isImminentBlowoutRisk, isFalse);
      expect(result.deltaPsi, closeTo(2.0, 0.05));
      expect(result.safetyAdvisory, contains('NOMINAL'));
    });

    test('Pressure delta >= 7 PSI triggers differential pressure warning', () {
      const telemetry = DualTireDifferentialTelemetry(
        innerTireColdPressurePsi: 96.0,
        outerTireColdPressurePsi: 105.0,
        innerTireTemperatureCelsius: 72.0,
        outerTireTemperatureCelsius: 54.0,
        wheelHubSpeedKmh: 95.0,
      );

      final result = service.auditDualAssembly(
        vehicleId: 'TRUCK-DUAL-120-WARN',
        axlePosition: 'Drive Axle 2 - Left Dual',
        telemetry: telemetry,
      );

      expect(result.status, DualTireDifferentialStatus.differentialPressureWarning);
      expect(result.isDualPairBalanced, isFalse);
      expect(result.deltaPsi, closeTo(9.0, 0.05));
      expect(result.safetyAdvisory, contains('WARNING: Companion tire pressure delta'));
    });

    test('Severe disparity (>= 15 PSI) or inner flat triggers blowout fire risk', () {
      const telemetry = DualTireDifferentialTelemetry(
        innerTireColdPressurePsi: 68.0,
        outerTireColdPressurePsi: 104.0,
        innerTireTemperatureCelsius: 98.0,
        outerTireTemperatureCelsius: 58.0,
        wheelHubSpeedKmh: 100.0,
      );

      final result = service.auditDualAssembly(
        vehicleId: 'TRUCK-DUAL-120-CRIT',
        axlePosition: 'Trailer Tandem 1 - Left Dual',
        telemetry: telemetry,
      );

      expect(result.status, DualTireDifferentialStatus.criticalInnerTireBlowoutFireRisk);
      expect(result.isImminentBlowoutRisk, isTrue);
      expect(result.safetyAdvisory, contains('CRITICAL HAZARD: Severe dual pressure disparity'));
    });

    testWidgets('DualTireDifferentialCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool equalizedClicked = false;
      const telemetry = DualTireDifferentialTelemetry(
        innerTireColdPressurePsi: 94.0,
        outerTireColdPressurePsi: 104.0,
        innerTireTemperatureCelsius: 70.0,
        outerTireTemperatureCelsius: 55.0,
        wheelHubSpeedKmh: 88.0,
      );

      final result = service.auditDualAssembly(
        vehicleId: 'HEAVY-TRACTOR-44',
        axlePosition: 'Rear Drive - Left Dual',
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
                child: DualTireDifferentialCard(
                  result: result,
                  onEqualizeDualPressure: () {
                    equalizedClicked = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dual-Tire Pressure Sentry'), findsOneWidget);
      expect(find.textContaining('HEAVY-TRACTOR-44'), findsOneWidget);
      expect(find.text('DELTA WARNING'), findsOneWidget);

      final equalizeBtn = find.text('Equalize Companion Dual Pressure');
      expect(equalizeBtn, findsOneWidget);
      await tester.tap(equalizeBtn);
      expect(equalizedClicked, isTrue);
    });
  });
}
