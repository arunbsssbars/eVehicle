import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/cold_chain_monitor_service.dart';
import 'package:evehicle_logbook/core/widgets/cold_chain_telemetry_card.dart';

void main() {
  group('Loop 21 - Cold Chain & Reefer Telemetry Service', () {
    const service = ColdChainMonitorService();

    test('Evaluating nominal chilled telemetry produces compliant audit', () {
      final now = DateTime.now();
      final readings = [
        ReeferReading(timestamp: now, temperatureCelsius: 4.5, humidityPercent: 65),
        ReeferReading(timestamp: now.add(const Duration(minutes: 10)), temperatureCelsius: 5.0, humidityPercent: 68),
        ReeferReading(timestamp: now.add(const Duration(minutes: 20)), temperatureCelsius: 4.2, humidityPercent: 64),
      ];

      final audit = service.evaluateTelemetry(readings: readings, category: CargoCategory.chilled);

      expect(audit.isCompliant, isTrue);
      expect(audit.totalExcursionMinutes, equals(0));
      expect(audit.averageTemperature, closeTo(4.56, 0.1));
      expect(audit.spoilageRiskScore, equals(0.0));
      expect(audit.excursions, isEmpty);
    });

    test('Strict pharma breach above 8°C triggers critical excursion and non-compliance', () {
      final now = DateTime.now();
      final readings = List.generate(10, (i) {
        return ReeferReading(
          timestamp: now.add(Duration(minutes: i * 5)),
          temperatureCelsius: 12.5, // 4.5 deg breach
          humidityPercent: 70,
        );
      });

      final audit = service.evaluateTelemetry(readings: readings, category: CargoCategory.strictPharma);

      expect(audit.isCompliant, isFalse);
      expect(audit.excursions.isNotEmpty, isTrue);
      expect(audit.excursions.first.severity, equals(ExcursionSeverity.critical));
      expect(audit.spoilageRiskScore, greaterThan(20.0));
    });

    test('Evaluating empty readings handles gracefully without error', () {
      final audit = service.evaluateTelemetry(readings: [], category: CargoCategory.deepFrozen);
      expect(audit.isCompliant, isTrue);
      expect(audit.excursions, isEmpty);
    });
  });

  group('Loop 21 - Cold Chain AQIL Responsive UI Tests', () {
    testWidgets('ColdChainTelemetryCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final audit = ColdChainAuditResult(
        category: CargoCategory.chilled,
        minTemperature: 3.2,
        maxTemperature: 9.1,
        averageTemperature: 5.4,
        totalExcursionMinutes: 15,
        spoilageRiskScore: 8.5,
        isCompliant: true,
        doorOpenEventCount: 3,
        excursions: [
          ColdChainExcursion(
            startTime: DateTime(2026, 10, 3, 10, 0),
            endTime: DateTime(2026, 10, 3, 10, 15),
            peakTemperature: 9.1,
            durationMinutes: 15,
            severity: ExcursionSeverity.warning,
            description: 'Minor breach',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColdChainTelemetryCard(
              audit: audit,
              onExportLog: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cold Chain Integrity'), findsOneWidget);
      expect(find.text('PASS'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ColdChainTelemetryCard maintains readable layout under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final audit = ColdChainAuditResult(
        category: CargoCategory.strictPharma,
        minTemperature: 2.1,
        maxTemperature: 14.8,
        averageTemperature: 8.9,
        totalExcursionMinutes: 45,
        spoilageRiskScore: 35.0,
        isCompliant: false,
        doorOpenEventCount: 7,
        excursions: [
          ColdChainExcursion(
            startTime: DateTime(2026, 10, 3, 11, 0),
            endTime: DateTime(2026, 10, 3, 11, 45),
            peakTemperature: 14.8,
            durationMinutes: 45,
            severity: ExcursionSeverity.critical,
            description: 'Critical temp surge',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Scaffold(
              body: ColdChainTelemetryCard(
                audit: audit,
                onExportLog: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BREACH'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
