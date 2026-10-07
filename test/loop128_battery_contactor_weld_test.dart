import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/battery_contactor_weld_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/battery_contactor_weld_card.dart';

void main() {
  group('Loop 128: BatteryContactorWeldAuditorService & Card Tests', () {
    const service = BatteryContactorWeldAuditorService();

    test('Clean contactor separation and low precharge temp reports nominal sound status', () {
      const telemetry = BatteryContactorWeldTelemetry(
        isMainPositiveAuxiliaryFeedbackOpen: true,
        isMainNegativeAuxiliaryFeedbackOpen: true,
        isContactorCommandedClosed: false,
        packVoltageVolts: 760.0,
        inverterLinkVoltageVolts: 0.8,
        preChargeResistorTemperatureCelsius: 38.0,
        coilPullInCurrentAmperes: 1.1,
      );

      final result = service.auditContactors(
        vehicleId: 'EV-PACK-128-OK',
        telemetry: telemetry,
      );

      expect(result.status, BatteryContactorWeldStatus.contactorsNominalCycleSound);
      expect(result.isIsolationSound, isTrue);
      expect(result.isWeldedCriticalFault, isFalse);
      expect(result.safetyAdvisory, contains('NOMINAL'));
    });

    test('Elevated precharge resistor temperature triggers thermal stress warning', () {
      const telemetry = BatteryContactorWeldTelemetry(
        isMainPositiveAuxiliaryFeedbackOpen: false,
        isMainNegativeAuxiliaryFeedbackOpen: false,
        isContactorCommandedClosed: true,
        packVoltageVolts: 760.0,
        inverterLinkVoltageVolts: 758.0,
        preChargeResistorTemperatureCelsius: 104.0,
        coilPullInCurrentAmperes: 1.2,
      );

      final result = service.auditContactors(
        vehicleId: 'EV-PACK-128-WARN',
        telemetry: telemetry,
      );

      expect(result.status, BatteryContactorWeldStatus.preChargeThermalStressWarning);
      expect(result.isIsolationSound, isFalse);
      expect(result.safetyAdvisory, contains('WARNING: Pre-charge circuit thermal stress'));
    });

    test('Contact welded shut with live link voltage triggers critical safety fault', () {
      const telemetry = BatteryContactorWeldTelemetry(
        isMainPositiveAuxiliaryFeedbackOpen: false,
        isMainNegativeAuxiliaryFeedbackOpen: true,
        isContactorCommandedClosed: false,
        packVoltageVolts: 780.0,
        inverterLinkVoltageVolts: 775.0,
        preChargeResistorTemperatureCelsius: 45.0,
        coilPullInCurrentAmperes: 0.0,
      );

      final result = service.auditContactors(
        vehicleId: 'EV-PACK-128-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, BatteryContactorWeldStatus.criticalMainContactorWeldHazard);
      expect(result.isWeldedCriticalFault, isTrue);
      expect(result.isPositiveWelded, isTrue);
      expect(result.safetyAdvisory, contains('CRITICAL SAFETY FAULT'));
    });

    testWidgets('BatteryContactorWeldCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool isolationExecuted = false;
      const telemetry = BatteryContactorWeldTelemetry(
        isMainPositiveAuxiliaryFeedbackOpen: false,
        isMainNegativeAuxiliaryFeedbackOpen: true,
        isContactorCommandedClosed: false,
        packVoltageVolts: 780.0,
        inverterLinkVoltageVolts: 770.0,
        preChargeResistorTemperatureCelsius: 50.0,
        coilPullInCurrentAmperes: 0.0,
      );

      final result = service.auditContactors(
        vehicleId: 'FREIGHT-EV-20',
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
                child: BatteryContactorWeldCard(
                  result: result,
                  onTriggerEmergencyIsolation: () {
                    isolationExecuted = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('HV Contactor Weld Sentry'), findsOneWidget);
      expect(find.textContaining('FREIGHT-EV-20'), findsOneWidget);
      expect(find.text('CONTACTOR WELD'), findsOneWidget);

      final isolateBtn = find.text('Execute Pyrofuse Galvanic Isolation');
      expect(isolateBtn, findsOneWidget);
      await tester.tap(isolateBtn);
      expect(isolationExecuted, isTrue);
    });
  });
}
