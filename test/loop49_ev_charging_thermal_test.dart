import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/ev_charging_thermal_service.dart';
import 'package:evehicle_logbook/core/widgets/ev_charging_thermal_card.dart';

void main() {
  group('Loop 49 - EV DC Fast Charging Thermal Optimization Tests', () {
    const service = EvChargingThermalService();

    test('evaluateChargeReadiness authorizes full power in optimal thermal band', () {
      const state = EvChargeThermalState(
        currentPackTempCelsius: 28.0,
        stateOfChargePercent: 30.0,
        dispenserMaxPowerKw: 250.0,
      );

      final audit = service.evaluateChargeReadiness(state);
      expect(audit.thermalBand, BatteryThermalBand.optimalFastAcceptance);
      expect(audit.deliverablePowerKw, 250.0);
      expect(audit.powerThrottlePercentage, 0.0);
      expect(audit.preconditioningMinutesRequired, 0);
    });

    test('evaluateChargeReadiness throttles freezing battery to prevent lithium plating', () {
      const state = EvChargeThermalState(
        currentPackTempCelsius: -2.0, // Sub-zero battery
        stateOfChargePercent: 20.0,
        dispenserMaxPowerKw: 200.0,
      );

      final audit = service.evaluateChargeReadiness(state);
      expect(audit.thermalBand, BatteryThermalBand.freezingPlateRisk);
      expect(audit.deliverablePowerKw, 50.0); // 25% capped
      expect(audit.powerThrottlePercentage, 75.0);
      expect(audit.preconditioningActive, isTrue);
      expect(audit.preconditioningMinutesRequired, greaterThan(20));
    });

    test('evaluateChargeReadiness cuts off power upon severe pack overheating', () {
      const state = EvChargeThermalState(
        currentPackTempCelsius: 54.0, // Exceeds thermal runaway safeguard threshold
        stateOfChargePercent: 65.0,
        dispenserMaxPowerKw: 150.0,
      );

      final audit = service.evaluateChargeReadiness(state);
      expect(audit.thermalBand, BatteryThermalBand.overheatCutoff);
      expect(audit.deliverablePowerKw, lessThan(15.0));
      expect(audit.powerThrottlePercentage, greaterThan(90.0));
    });

    testWidgets('EvChargingThermalCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = ChargeThermalAudit(
        thermalBand: BatteryThermalBand.coldSuboptimal,
        deliverablePowerKw: 110.0,
        powerThrottlePercentage: 35.0,
        preconditioningMinutesRequired: 18,
        preconditioningEnergyCostKwh: 1.35,
        estimatedSessionMinutesSaved: 14,
        recommendation: 'COLD PACK: Pre-conditioning will save ~14 min at the DC charger.',
        preconditioningActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvChargingThermalCard(
              audit: audit,
              currentPackTempCelsius: 12.0,
              onActivatePreconditioning: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EV Battery Thermal Charging'), findsOneWidget);
      expect(find.text('COLD SLOW'), findsOneWidget);
      expect(find.textContaining('Pre-Condition Battery'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EvChargingThermalCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = ChargeThermalAudit(
        thermalBand: BatteryThermalBand.optimalFastAcceptance,
        deliverablePowerKw: 300.0,
        powerThrottlePercentage: 0.0,
        preconditioningMinutesRequired: 0,
        preconditioningEnergyCostKwh: 0.0,
        estimatedSessionMinutesSaved: 0,
        recommendation: 'OPTIMAL CHARGE WINDOW: Battery temperature at 28°C.',
        preconditioningActive: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: EvChargingThermalCard(
                audit: audit,
                currentPackTempCelsius: 28.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OPTIMAL PEAK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
