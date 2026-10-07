import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/injector_leakoff_balance_service.dart';
import 'package:evehicle_logbook/core/widgets/injector_leakoff_balance_card.dart';

void main() {
  group('Loop 129: InjectorLeakoffBalanceService & Card Tests', () {
    const service = InjectorLeakoffBalanceService();

    test('Clean back-leak and smooth cylinder balance reports nominal status', () {
      const telemetry = InjectorLeakoffTelemetry(
        cylinderNumber: 3,
        returnFuelLeakoffMillilitersPerMinute: 22.0,
        pilotInjectionQuantityMm3: 2.1,
        piezoActuatorCapacitanceMicroFarads: 3.1,
        cylinderSmoothRunningContributionRpm: 4.0,
        injectorBodyTemperatureCelsius: 75.0,
      );

      final result = service.auditInjector(
        vehicleId: 'DIESEL-INJ-129-OK',
        telemetry: telemetry,
      );

      expect(result.status, InjectorLeakoffBalanceStatus.injectorsBalancedNominal);
      expect(result.isInjectorHealthy, isTrue);
      expect(result.isCylinderMisfireSevere, isFalse);
      expect(result.cylinderNumber, 3);
      expect(result.serviceAdvisory, contains('NOMINAL'));
    });

    test('Elevated return flow (>55 mL/min) triggers leakoff warning', () {
      const telemetry = InjectorLeakoffTelemetry(
        cylinderNumber: 5,
        returnFuelLeakoffMillilitersPerMinute: 68.0,
        pilotInjectionQuantityMm3: 1.6,
        piezoActuatorCapacitanceMicroFarads: 2.3,
        cylinderSmoothRunningContributionRpm: 34.0,
        injectorBodyTemperatureCelsius: 98.0,
      );

      final result = service.auditInjector(
        vehicleId: 'DIESEL-INJ-129-WARN',
        telemetry: telemetry,
      );

      expect(result.status, InjectorLeakoffBalanceStatus.excessiveLeakoffReturnWarning);
      expect(result.isInjectorHealthy, isFalse);
      expect(result.serviceAdvisory, contains('WARNING: Cylinder #5 back-leak return flow elevated'));
    });

    test('Extreme leakoff (>90 mL/min) or misfire roughness triggers needle seizure fault', () {
      const telemetry = InjectorLeakoffTelemetry(
        cylinderNumber: 2,
        returnFuelLeakoffMillilitersPerMinute: 96.0,
        pilotInjectionQuantityMm3: 0.2,
        piezoActuatorCapacitanceMicroFarads: 1.8,
        cylinderSmoothRunningContributionRpm: 82.0,
        injectorBodyTemperatureCelsius: 122.0,
      );

      final result = service.auditInjector(
        vehicleId: 'DIESEL-INJ-129-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, InjectorLeakoffBalanceStatus.criticalNeedleSeizureCylinderMisfire);
      expect(result.isCylinderMisfireSevere, isTrue);
      expect(result.serviceAdvisory, contains('CRITICAL INJECTOR FAULT'));
    });

    testWidgets('InjectorLeakoffBalanceCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool calibrated = false;
      const telemetry = InjectorLeakoffTelemetry(
        cylinderNumber: 4,
        returnFuelLeakoffMillilitersPerMinute: 72.0,
        pilotInjectionQuantityMm3: 1.4,
        piezoActuatorCapacitanceMicroFarads: 2.2,
        cylinderSmoothRunningContributionRpm: 38.0,
        injectorBodyTemperatureCelsius: 105.0,
      );

      final result = service.auditInjector(
        vehicleId: 'HEAVY-MACK-60',
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
                child: InjectorLeakoffBalanceCard(
                  result: result,
                  onScheduleInjectorCalibration: () {
                    calibrated = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cylinder #4 Injector Sentry'), findsOneWidget);
      expect(find.textContaining('HEAVY-MACK-60'), findsOneWidget);
      expect(find.text('HIGH LEAKOFF'), findsOneWidget);

      final calBtn = find.text('Recalibrate Injector IMA Codes & Balance');
      expect(calBtn, findsOneWidget);
      await tester.tap(calBtn);
      expect(calibrated, isTrue);
    });
  });
}
