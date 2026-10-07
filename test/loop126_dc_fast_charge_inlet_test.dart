import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/dc_fast_charge_inlet_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/dc_fast_charge_inlet_card.dart';

void main() {
  group('Loop 126: DcFastChargeInletAuditorService & Card Tests', () {
    const service = DcFastChargeInletAuditorService();

    test('Locked coupler with normal pin temperature reports nominal charging session', () {
      const telemetry = DcFastChargeInletTelemetry(
        dcPositivePinTemperatureCelsius: 58.0,
        dcNegativePinTemperatureCelsius: 60.5,
        chargingCurrentAmperes: 320.0,
        inletContactResistanceMicroOhms: 12.0,
        isElectronicLockSolenoidEngaged: true,
        isolationResistanceMegaOhms: 650.0,
        liquidCoolantFlowLitersPerMin: 4.2,
      );

      final result = service.auditChargingSession(
        vehicleId: 'EV-SEMI-126-OK',
        telemetry: telemetry,
      );

      expect(result.status, DcFastChargeInletStatus.chargingProtocolNominal);
      expect(result.isChargeSessionSafe, isTrue);
      expect(result.isEmergencyCutoffMandatory, isFalse);
      expect(result.maxPinTempCelsius, 60.5);
      expect(result.recommendedChargeCurrentLimitAmps, 320.0);
      expect(result.safetyAdvisory, contains('NOMINAL'));
    });

    test('Pin temperature >88C triggers current derating warning', () {
      const telemetry = DcFastChargeInletTelemetry(
        dcPositivePinTemperatureCelsius: 94.0,
        dcNegativePinTemperatureCelsius: 82.0,
        chargingCurrentAmperes: 350.0,
        inletContactResistanceMicroOhms: 34.0,
        isElectronicLockSolenoidEngaged: true,
        isolationResistanceMegaOhms: 450.0,
        liquidCoolantFlowLitersPerMin: 3.5,
      );

      final result = service.auditChargingSession(
        vehicleId: 'EV-SEMI-126-WARN',
        telemetry: telemetry,
      );

      expect(result.status, DcFastChargeInletStatus.thermalDeratingPinWarning);
      expect(result.isChargeSessionSafe, isFalse);
      expect(result.recommendedChargeCurrentLimitAmps, lessThan(250.0));
      expect(result.safetyAdvisory, contains('WARNING: Charging inlet pin heating'));
    });

    test('Unlatched lock with live current or pin >=110C triggers critical arc flash abort', () {
      const telemetry = DcFastChargeInletTelemetry(
        dcPositivePinTemperatureCelsius: 114.0,
        dcNegativePinTemperatureCelsius: 112.0,
        chargingCurrentAmperes: 380.0,
        inletContactResistanceMicroOhms: 55.0,
        isElectronicLockSolenoidEngaged: false,
        isolationResistanceMegaOhms: 80.0,
        liquidCoolantFlowLitersPerMin: 1.2,
      );

      final result = service.auditChargingSession(
        vehicleId: 'EV-SEMI-126-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, DcFastChargeInletStatus.criticalThermalRunawayArcHazard);
      expect(result.isEmergencyCutoffMandatory, isTrue);
      expect(result.recommendedChargeCurrentLimitAmps, 0.0);
      expect(result.safetyAdvisory, contains('CRITICAL SAFETY FAULT'));
    });

    testWidgets('DcFastChargeInletCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool abortClicked = false;
      const telemetry = DcFastChargeInletTelemetry(
        dcPositivePinTemperatureCelsius: 112.0,
        dcNegativePinTemperatureCelsius: 110.0,
        chargingCurrentAmperes: 300.0,
        inletContactResistanceMicroOhms: 52.0,
        isElectronicLockSolenoidEngaged: false,
        isolationResistanceMegaOhms: 70.0,
        liquidCoolantFlowLitersPerMin: 1.0,
      );

      final result = service.auditChargingSession(
        vehicleId: 'MEGACAB-EV-99',
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
                child: DcFastChargeInletCard(
                  result: result,
                  onAbortEmergencyCharging: () {
                    abortClicked = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('DC Fast Charge Inlet Sentry'), findsOneWidget);
      expect(find.textContaining('MEGACAB-EV-99'), findsOneWidget);
      expect(find.text('ARC FLASH FAULT'), findsOneWidget);

      final abortBtn = find.text('Open DC Contactors & Terminate Session');
      expect(abortBtn, findsOneWidget);
      await tester.tap(abortBtn);
      expect(abortClicked, isTrue);
    });
  });
}
