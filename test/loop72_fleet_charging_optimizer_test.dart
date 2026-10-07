import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/fleet_charging_optimizer_service.dart';
import 'package:evehicle_logbook/core/widgets/fleet_charging_optimizer_card.dart';

void main() {
  group('Loop 72: Fleet Charging Optimizer Service Tests', () {
    const service = FleetChargingOptimizerService();

    final tariffs = [
      const TariffWindow(
        label: 'Super Off-Peak',
        startHour: 0,
        endHour: 5,
        ratePerKwh: 4.5,
        carbonIntensityGPerKwh: 380,
      ),
      const TariffWindow(
        label: 'Off-Peak',
        startHour: 6,
        endHour: 10,
        ratePerKwh: 7.0,
        carbonIntensityGPerKwh: 490,
      ),
      const TariffWindow(
        label: 'Peak Hours',
        startHour: 17,
        endHour: 22,
        ratePerKwh: 14.0,
        carbonIntensityGPerKwh: 780,
      ),
    ];

    test('EV charging optimization prioritizes lowest cost windows and saves costs', () {
      const profile = VehicleEnergyProfile(
        vehicleId: 'ev-101',
        registrationNumber: 'DL01-EV-9999',
        isElectric: true,
        batteryCapacityKwh: 60.0,
        currentSoCPercent: 20.0,
        targetSoCPercent: 80.0,
        maxChargingPowerKw: 20.0,
      );

      final plan = service.optimizeCharging(profile: profile, tariffs: tariffs);

      // Energy needed: (80 - 20)% of 60 = 36 kWh
      expect(plan.energyNeededKwh, 36.0);
      expect(plan.unmanagedPeakCost, 36.0 * 14.0); // 504.0
      expect(plan.optimalCost < plan.unmanagedPeakCost, isTrue);
      expect(plan.costSavingsPercent > 30.0, isTrue);
      expect(plan.scheduleBlocks.isNotEmpty, isTrue);
      expect(plan.parityCostPerKmEv < plan.parityCostPerKmDiesel, isTrue);
    });

    test('Non-electric ICE vehicle returns diesel parity calculation without charging schedule', () {
      const profile = VehicleEnergyProfile(
        vehicleId: 'ice-202',
        registrationNumber: 'MH02-DS-4521',
        isElectric: false,
        dieselEfficiencyKmPerLitre: 15.0,
        dieselPricePerLitre: 90.0,
      );

      final plan = service.optimizeCharging(profile: profile, tariffs: tariffs);

      expect(plan.energyNeededKwh, 0.0);
      expect(plan.optimalCost, 0.0);
      expect(plan.parityCostPerKmDiesel, 6.0); // 90 / 15 = 6.00
      expect(plan.scheduleBlocks.isEmpty, isTrue);
    });
  });

  group('Loop 72: AQIL UI Multi-Viewport & Accessibility Tests', () {
    const service = FleetChargingOptimizerService();

    final plan = service.optimizeCharging(
      profile: const VehicleEnergyProfile(
        vehicleId: 'ev-test',
        registrationNumber: 'KA03-EV-1234',
        isElectric: true,
        batteryCapacityKwh: 75.0,
        currentSoCPercent: 15.0,
        targetSoCPercent: 95.0,
        maxChargingPowerKw: 30.0,
      ),
      tariffs: const [
        TariffWindow(label: 'Super Off-Peak', startHour: 1, endHour: 5, ratePerKwh: 4.0, carbonIntensityGPerKwh: 350),
        TariffWindow(label: 'Peak', startHour: 18, endHour: 22, ratePerKwh: 13.5, carbonIntensityGPerKwh: 750),
      ],
    );

    testWidgets('FleetChargingOptimizerCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FleetChargingOptimizerCard(
                plan: plan,
                registrationNumber: 'KA03-EV-1234 (Tata Nexon EV Commercial)',
                onScheduleCharging: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Smart Grid Charging Optimizer'), findsOneWidget);
      expect(find.textContaining('Authorize Smart Charging Schedule'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('FleetChargingOptimizerCard maintains integrity under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: SingleChildScrollView(
                child: FleetChargingOptimizerCard(
                  plan: plan,
                  registrationNumber: 'KA03-EV-1234',
                  onScheduleCharging: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FleetChargingOptimizerCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
