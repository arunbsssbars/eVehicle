import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/ev_battery_health_service.dart';
import 'package:evehicle_logbook/core/widgets/ev_battery_health_card.dart';

void main() {
  group('Loop 26 - EV Battery Health & Thermal Safety Service', () {
    const service = EvBatteryHealthService();

    test('Fresh balanced battery produces optimal status and high SoH', () {
      final cells = List.generate(8, (i) {
        return CellVoltageTelemetry(cellIndex: i, voltageVolts: 3.85, tempCelsius: 28.0);
      });

      final audit = service.evaluateBatteryPack(
        cells: cells,
        totalChargeCycleCount: 50,
        stateOfChargePercent: 80.0,
      );

      expect(audit.status, equals(BatteryThermalStatus.optimal));
      expect(audit.cellDeltaV, equals(0.0));
      expect(audit.stateOfHealthPercent, greaterThan(90.0));
      expect(audit.safetyAdvisory, contains('NOMINAL'));
    });

    test('Significant cell voltage divergence triggers imbalance warning', () {
      final cells = [
        const CellVoltageTelemetry(cellIndex: 0, voltageVolts: 3.85, tempCelsius: 30.0),
        const CellVoltageTelemetry(cellIndex: 1, voltageVolts: 3.75, tempCelsius: 31.0), // 100mV delta
        const CellVoltageTelemetry(cellIndex: 2, voltageVolts: 3.84, tempCelsius: 30.5),
      ];

      final audit = service.evaluateBatteryPack(
        cells: cells,
        totalChargeCycleCount: 200,
        stateOfChargePercent: 60.0,
      );

      expect(audit.status, equals(BatteryThermalStatus.cellImbalanceWarning));
      expect(audit.cellDeltaV, closeTo(0.10, 0.001));
      expect(audit.safetyAdvisory, contains('CELL IMBALANCE'));
    });

    test('Excessive pack heat triggers critical thermal runaway risk', () {
      final cells = [
        const CellVoltageTelemetry(cellIndex: 0, voltageVolts: 3.80, tempCelsius: 64.0),
      ];

      final audit = service.evaluateBatteryPack(
        cells: cells,
        totalChargeCycleCount: 400,
        stateOfChargePercent: 95.0,
      );

      expect(audit.status, equals(BatteryThermalStatus.criticalThermalRunawayRisk));
      expect(audit.safetyAdvisory, contains('CRITICAL THERMAL ALERT'));
    });
  });

  group('Loop 26 - EV Battery AQIL Responsive UI Tests', () {
    testWidgets('EvBatteryHealthCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = BatteryHealthAudit(
        stateOfHealthPercent: 94.2,
        stateOfChargePercent: 78.0,
        minCellVoltage: 3.82,
        maxCellVoltage: 3.85,
        cellDeltaV: 0.03,
        packMaxTempCelsius: 31.5,
        status: BatteryThermalStatus.optimal,
        estimatedRemainingCycles: 1613,
        safetyAdvisory: 'NOMINAL: Traction pack cells balanced.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvBatteryHealthCard(
              audit: audit,
              onInitiateCellBalancing: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EV Battery Telemetry'), findsOneWidget);
      expect(find.text('OPTIMAL'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EvBatteryHealthCard maintains readable layout under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = BatteryHealthAudit(
        stateOfHealthPercent: 82.5,
        stateOfChargePercent: 45.0,
        minCellVoltage: 3.70,
        maxCellVoltage: 3.82,
        cellDeltaV: 0.12,
        packMaxTempCelsius: 58.0,
        status: BatteryThermalStatus.criticalThermalRunawayRisk,
        estimatedRemainingCycles: 833,
        safetyAdvisory: 'CRITICAL THERMAL ALERT: High cell temp.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Scaffold(
              body: EvBatteryHealthCard(
                audit: audit,
                onInitiateCellBalancing: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OVERHEAT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
