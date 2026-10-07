import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/fuel_aero_efficiency_service.dart';
import 'package:evehicle_logbook/core/widgets/aero_efficiency_card.dart';

void main() {
  group('Loop 32 - Fuel Economy & Aerodynamic Drag Speed Optimizer', () {
    const service = FuelAeroEfficiencyService();

    test('Driving at sweet spot speed ~80 km/h produces Grade A efficiency', () {
      final speeds = List.generate(20, (i) => 78.0 + (i % 3));
      final audit = service.evaluateSpeedProfile(speedsKmph: speeds);

      expect(audit.efficiencyGrade, equals('A'));
      expect(audit.percentageTimeHighDrag, equals(0.0));
      expect(audit.excessFuelBurnL100Km, closeTo(0.0, 0.2));
      expect(audit.aeroAdvisory, contains('AERODYNAMIC CORRIDOR'));
    });

    test('High speed driving (>100 km/h) triggers Grade D and calculates fuel savings', () {
      final speeds = List.generate(20, (i) => 110.0);
      final audit = service.evaluateSpeedProfile(
        speedsKmph: speeds,
        monthlyProjectedKm: 4000.0,
        fuelPricePerLiter: 1.50,
      );

      expect(audit.efficiencyGrade, equals('D'));
      expect(audit.percentageTimeHighDrag, equals(100.0));
      expect(audit.excessFuelBurnL100Km, greaterThan(1.5));
      expect(audit.monthlyCostSavingsUsd, greaterThan(50.0));
      expect(audit.aeroAdvisory, contains('SEVERE VELOCITY PENALTY'));
    });

    test('Empty speed samples handled gracefully', () {
      final audit = service.evaluateSpeedProfile(speedsKmph: []);
      expect(audit.efficiencyGrade, equals('A'));
      expect(audit.monthlyCostSavingsUsd, equals(0.0));
    });
  });

  group('Loop 32 - Aero Efficiency AQIL Responsive UI Tests', () {
    testWidgets('AeroEfficiencyCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = AeroEfficiencyAudit(
        averageSpeedKmph: 79.5,
        percentageTimeHighDrag: 4.2,
        optimalSpeedKmph: 80.0,
        excessFuelBurnL100Km: 0.12,
        monthlyCostSavingsUsd: 5.40,
        efficiencyGrade: 'A',
        aeroAdvisory: 'AERODYNAMIC CORRIDOR: Fleet operating in peak sweet-spot.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AeroEfficiencyCard(
              audit: audit,
              onConfigureSpeedGovernor: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aerodynamic Efficiency'), findsOneWidget);
      expect(find.text('GRADE A'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AeroEfficiencyCard preserves layout stability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = AeroEfficiencyAudit(
        averageSpeedKmph: 104.2,
        percentageTimeHighDrag: 74.0,
        optimalSpeedKmph: 80.0,
        excessFuelBurnL100Km: 2.35,
        monthlyCostSavingsUsd: 119.26,
        efficiencyGrade: 'D',
        aeroAdvisory: 'SEVERE VELOCITY PENALTY: Speed governor recommended.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Scaffold(
              body: AeroEfficiencyCard(
                audit: audit,
                onConfigureSpeedGovernor: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GRADE D'), findsOneWidget);
      expect(find.text('Enable Telematics Cruising Governor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
