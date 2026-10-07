import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/inverter_dclink_capacitor_service.dart';
import 'package:evehicle_logbook/core/widgets/inverter_dclink_capacitor_card.dart';

void main() {
  group('Loop 117: InverterDcLinkCapacitorService & Card Tests', () {
    const service = InverterDcLinkCapacitorService();

    test('Rated capacitance and low ripple reports nominal capacitor status', () {
      const telemetry = InverterDcLinkTelemetry(
        measuredCapacitanceMicroFarads: 590.0,
        ratedCapacitanceMicroFarads: 600.0,
        dcBusVoltageVolts: 750.0,
        peakToPeakRippleVoltageVolts: 4.5,
        equivalentSeriesResistanceMilliOhms: 3.2,
        capacitorCoreTemperatureCelsius: 48.0,
      );

      final result = service.auditCapacitorBank(
        vehicleId: 'EV-INV-117-OK',
        telemetry: telemetry,
      );

      expect(result.status, InverterDcLinkStatus.capacitanceNominal);
      expect(result.isCapacitorHealthy, isTrue);
      expect(result.isCriticalInverterFailureRisk, isFalse);
      expect(result.healthPercent, greaterThan(85.0));
      expect(result.advisory, contains('NOMINAL'));
    });

    test('Elevated ripple or early ESR rise triggers degradation warning', () {
      const telemetry = InverterDcLinkTelemetry(
        measuredCapacitanceMicroFarads: 520.0,
        ratedCapacitanceMicroFarads: 600.0,
        dcBusVoltageVolts: 740.0,
        peakToPeakRippleVoltageVolts: 18.0,
        equivalentSeriesResistanceMilliOhms: 14.5,
        capacitorCoreTemperatureCelsius: 72.0,
      );

      final result = service.auditCapacitorBank(
        vehicleId: 'EV-INV-117-WARN',
        telemetry: telemetry,
      );

      expect(result.status, InverterDcLinkStatus.highRippleDegradationWarning);
      expect(result.isCapacitorHealthy, isFalse);
      expect(result.advisory, contains('WARNING: DC-link capacitor ESR aging'));
    });

    test('Excessive capacitance drop or destructive ripple triggers dielectric breakdown danger', () {
      const telemetry = InverterDcLinkTelemetry(
        measuredCapacitanceMicroFarads: 440.0,
        ratedCapacitanceMicroFarads: 600.0,
        dcBusVoltageVolts: 720.0,
        peakToPeakRippleVoltageVolts: 34.0,
        equivalentSeriesResistanceMilliOhms: 24.0,
        capacitorCoreTemperatureCelsius: 89.0,
      );

      final result = service.auditCapacitorBank(
        vehicleId: 'EV-INV-117-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, InverterDcLinkStatus.criticalDielectricBreakdownRisk);
      expect(result.isCriticalInverterFailureRisk, isTrue);
      expect(result.advisory, contains('CRITICAL HAZARD'));
    });

    testWidgets('InverterDcLinkCapacitorCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool serviceScheduled = false;
      const telemetry = InverterDcLinkTelemetry(
        measuredCapacitanceMicroFarads: 510.0,
        ratedCapacitanceMicroFarads: 600.0,
        dcBusVoltageVolts: 730.0,
        peakToPeakRippleVoltageVolts: 19.0,
        equivalentSeriesResistanceMilliOhms: 15.0,
        capacitorCoreTemperatureCelsius: 74.0,
      );

      final result = service.auditCapacitorBank(
        vehicleId: 'E-BUS-INV-01',
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
                child: InverterDcLinkCapacitorCard(
                  result: result,
                  onScheduleInverterCheck: () {
                    serviceScheduled = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Inverter DC-Link Capacitor Sentry'), findsOneWidget);
      expect(find.textContaining('E-BUS-INV-01'), findsOneWidget);
      expect(find.text('RIPPLE WARNING'), findsOneWidget);

      final bookBtn = find.text('Schedule Inverter DC-Bus Service');
      expect(bookBtn, findsOneWidget);
      await tester.tap(bookBtn);
      expect(serviceScheduled, isTrue);
    });
  });
}
