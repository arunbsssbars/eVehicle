import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/idle_waste_service.dart';
import 'package:evehicle_logbook/core/widgets/idle_waste_card.dart';

void main() {
  group('Loop 29 - Driver Idle Time & Auxiliary Power Service', () {
    const service = IdleWasteService();

    test('Minimal idle duration yields Grade A and low fuel waste', () {
      final now = DateTime.now();
      final sessions = [
        IdleSession(startTime: now, endTime: now.add(const Duration(minutes: 5)), durationMinutes: 5),
      ];

      final audit = service.evaluateIdleTelemetry(
        sessions: sessions,
        totalEngineHours: 10.0, // 5 min out of 600 min is <1%
      );

      expect(audit.efficiencyGrade, equals('A'));
      expect(audit.idleRatioPercent, lessThan(8.0));
      expect(audit.wastedCostUsd, lessThan(1.0));
    });

    test('Productive PTO sessions are excluded from idle waste penalties', () {
      final now = DateTime.now();
      final sessions = [
        // 60 minutes of productive cement pump PTO
        IdleSession(startTime: now, endTime: now.add(const Duration(minutes: 60)), durationMinutes: 60, isProductivePto: true),
        // 10 minutes of unproductive traffic/dock wait
        IdleSession(startTime: now.add(const Duration(minutes: 60)), endTime: now.add(const Duration(minutes: 70)), durationMinutes: 10, isProductivePto: false),
      ];

      final audit = service.evaluateIdleTelemetry(
        sessions: sessions,
        totalEngineHours: 4.0,
      );

      expect(audit.productivePtoHours, equals(1.0));
      expect(audit.unproductiveIdleHours, equals(0.2));
      expect(audit.efficiencyGrade, equals('A'));
    });

    test('High unproductive idle ratio (>40%) triggers Grade F and high emissions penalty', () {
      final now = DateTime.now();
      final sessions = [
        IdleSession(startTime: now, endTime: now.add(const Duration(minutes: 180)), durationMinutes: 180, isProductivePto: false),
      ];

      final audit = service.evaluateIdleTelemetry(
        sessions: sessions,
        totalEngineHours: 5.0, // 3 hours idle out of 5 hours = 60%
        fuelPricePerLiter: 1.50,
      );

      expect(audit.efficiencyGrade, equals('F'));
      expect(audit.idleRatioPercent, equals(60.0));
      expect(audit.wastedFuelLiters, equals(3.6));
      expect(audit.wastedCostUsd, equals(5.40));
      expect(audit.excessCo2Kg, greaterThan(9.0));
    });
  });

  group('Loop 29 - Idle Waste AQIL Responsive UI Tests', () {
    testWidgets('IdleWasteCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = IdleWasteAudit(
        totalEngineHours: 8.0,
        unproductiveIdleHours: 0.5,
        productivePtoHours: 1.2,
        idleRatioPercent: 6.2,
        wastedFuelLiters: 0.6,
        wastedCostUsd: 0.84,
        excessCo2Kg: 1.6,
        efficiencyGrade: 'A',
        recommendations: 'EXCELLENT: Idle duration strictly optimized.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IdleWasteCard(
              audit: audit,
              onConfigureIdleShutoff: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Idle Fuel Waste Analytics'), findsOneWidget);
      expect(find.text('GRADE A'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('IdleWasteCard preserves layout stability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = IdleWasteAudit(
        totalEngineHours: 6.0,
        unproductiveIdleHours: 2.8,
        productivePtoHours: 0.0,
        idleRatioPercent: 46.7,
        wastedFuelLiters: 3.4,
        wastedCostUsd: 4.76,
        excessCo2Kg: 9.1,
        efficiencyGrade: 'F',
        recommendations: 'CRITICAL IDLE WASTE: Over 40% spent idling.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Scaffold(
              body: IdleWasteCard(
                audit: audit,
                onConfigureIdleShutoff: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GRADE F'), findsOneWidget);
      expect(find.text('Configure Auto-Idle Engine Shutdown'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
