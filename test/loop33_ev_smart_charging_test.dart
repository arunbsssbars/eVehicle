import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/ev_smart_charging_service.dart';
import 'package:evehicle_logbook/core/widgets/ev_smart_charging_card.dart';

void main() {
  group('Loop 33 - EV Smart Charging & TOU Tariff Service', () {
    const service = EvSmartChargingService();

    test('Smart off-peak schedule generates over 70% cost savings versus peak tariff', () {
      final plan = service.computeChargingPlan(
        currentSocPercent: 20.0,
        targetSocPercent: 90.0,
        batteryCapacityKwh: 75.0, // 52.5 kWh needed
        chargerPowerKw: 11.0,     // ~4.8 hours
        plannedDepartureHour: 7,
      );

      expect(plan.energyNeededKwh, equals(52.5));
      expect(plan.chargeDurationHours, closeTo(4.8, 0.1));
      expect(plan.optimalStartHour, equals(2)); // 7 - 5 = 2 AM
      expect(plan.unmanagedPeakCostUsd, greaterThan(19.0));
      expect(plan.smartScheduledCostUsd, lessThan(5.0));
      expect(plan.savingsPercentage, greaterThan(70.0));
    });

    test('Fully charged battery requires zero energy and zero cost', () {
      final plan = service.computeChargingPlan(
        currentSocPercent: 95.0,
        targetSocPercent: 90.0,
      );

      expect(plan.energyNeededKwh, equals(0.0));
      expect(plan.chargeDurationHours, equals(0.0));
      expect(plan.netSavingsUsd, equals(0.0));
    });
  });

  group('Loop 33 - EV Smart Charging AQIL Responsive UI Tests', () {
    testWidgets('EvSmartChargingCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const plan = SmartChargingPlan(
        currentSocPercent: 30.0,
        targetSocPercent: 85.0,
        batteryCapacityKwh: 60.0,
        energyNeededKwh: 33.0,
        chargerPowerKw: 7.4,
        chargeDurationHours: 4.5,
        optimalStartHour: 2,
        plannedDepartureHour: 7,
        unmanagedPeakCostUsd: 12.54,
        smartScheduledCostUsd: 2.64,
        netSavingsUsd: 9.90,
        savingsPercentage: 78.9,
        isPreconditioningScheduled: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvSmartChargingCard(
              plan: plan,
              onActivateSchedule: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EV TOU Smart Charging'), findsOneWidget);
      expect(find.text('-78% COST'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EvSmartChargingCard preserves layout stability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const plan = SmartChargingPlan(
        currentSocPercent: 15.0,
        targetSocPercent: 90.0,
        batteryCapacityKwh: 100.0,
        energyNeededKwh: 75.0,
        chargerPowerKw: 22.0,
        chargeDurationHours: 3.4,
        optimalStartHour: 3,
        plannedDepartureHour: 7,
        unmanagedPeakCostUsd: 28.50,
        smartScheduledCostUsd: 6.00,
        netSavingsUsd: 22.50,
        savingsPercentage: 78.9,
        isPreconditioningScheduled: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Scaffold(
              body: EvSmartChargingCard(
                plan: plan,
                onActivateSchedule: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Commit Smart Off-Peak Schedule'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
