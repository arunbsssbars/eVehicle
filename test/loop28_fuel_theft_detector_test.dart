import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/fuel_siphon_detector_service.dart';
import 'package:evehicle_logbook/core/widgets/fuel_theft_alert_card.dart';

void main() {
  group('Loop 28 - Fuel Theft & Sudden Siphon Anomaly Detector Service', () {
    const service = FuelSiphonDetectorService();

    test('Gradual fuel consumption while driving is recognized as normal', () {
      final now = DateTime.now();
      final readings = [
        FuelLevelReading(timestamp: now, fuelLevelLiters: 60.0, isEngineRunning: true, speedKmph: 70.0, latitude: 12.97, longitude: 77.59),
        FuelLevelReading(timestamp: now.add(const Duration(minutes: 30)), fuelLevelLiters: 57.5, isEngineRunning: true, speedKmph: 68.0, latitude: 13.10, longitude: 77.65),
      ];

      final audit = service.detectFuelTheft(readings: readings);
      expect(audit.hasTheftOccurred, isFalse);
      expect(audit.totalLitersLost, equals(0.0));
      expect(audit.threatLevel, equals('LOW'));
    });

    test('Sudden fuel drop while parked with engine off triggers siphon alert', () {
      final now = DateTime.now();
      final readings = [
        FuelLevelReading(timestamp: now, fuelLevelLiters: 70.0, isEngineRunning: false, speedKmph: 0.0, latitude: 12.97, longitude: 77.59),
        // 20 Liters missing 15 minutes later while vehicle parked
        FuelLevelReading(timestamp: now.add(const Duration(minutes: 15)), fuelLevelLiters: 50.0, isEngineRunning: false, speedKmph: 0.0, latitude: 12.97, longitude: 77.59),
      ];

      final audit = service.detectFuelTheft(readings: readings, fuelPricePerLiter: 1.50);
      expect(audit.hasTheftOccurred, isTrue);
      expect(audit.totalLitersLost, equals(20.0));
      expect(audit.totalFinancialLossUsd, equals(30.0));
      expect(audit.incidents.length, equals(1));
      expect(audit.threatLevel, equals('ELEVATED'));
    });

    test('Massive siphon (>40L) sets threat level to CRITICAL', () {
      final now = DateTime.now();
      final readings = [
        FuelLevelReading(timestamp: now, fuelLevelLiters: 120.0, isEngineRunning: false, speedKmph: 0.0, latitude: 12.97, longitude: 77.59),
        FuelLevelReading(timestamp: now.add(const Duration(minutes: 20)), fuelLevelLiters: 70.0, isEngineRunning: false, speedKmph: 0.0, latitude: 12.97, longitude: 77.59),
      ];

      final audit = service.detectFuelTheft(readings: readings);
      expect(audit.hasTheftOccurred, isTrue);
      expect(audit.totalLitersLost, equals(50.0));
      expect(audit.threatLevel, equals('CRITICAL'));
      expect(audit.advisory, contains('SEVERE SIPHON EVENT'));
    });
  });

  group('Loop 28 - Fuel Theft AQIL Responsive UI Tests', () {
    testWidgets('FuelTheftAlertCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final audit = FuelTheftAudit(
        hasTheftOccurred: true,
        incidents: [
          SiphonIncident(
            timestamp: DateTime(2026, 10, 3, 2, 30),
            litersLost: 25.0,
            financialLossUsd: 37.50,
            latitude: 12.97,
            longitude: 77.59,
            durationMinutes: 12.0,
            confidencePercent: 95,
          ),
        ],
        totalLitersLost: 25.0,
        totalFinancialLossUsd: 37.50,
        threatLevel: 'ELEVATED',
        advisory: 'SIPHON DETECTED: Rapid fuel drop while vehicle stationary.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FuelTheftAlertCard(
              audit: audit,
              onFlagTheftIncident: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fuel Siphon Anomaly Guard'), findsOneWidget);
      expect(find.text('ELEVATED'), findsOneWidget);
      expect(find.text('File Security & Fuel Siphon Report'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('FuelTheftAlertCard maintains layout stability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = FuelTheftAudit(
        hasTheftOccurred: false,
        incidents: [],
        totalLitersLost: 0.0,
        totalFinancialLossUsd: 0.0,
        threatLevel: 'LOW',
        advisory: 'NOMINAL: No unauthorized fuel drops detected.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: const Scaffold(
              body: FuelTheftAlertCard(
                audit: audit,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LOW'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
