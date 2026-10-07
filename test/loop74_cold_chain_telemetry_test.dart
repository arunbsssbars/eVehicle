import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/cold_chain_telemetry_service.dart';
import 'package:evehicle_logbook/core/widgets/cold_chain_mkt_quality_card.dart';

void main() {
  group('Loop 74: Cold-Chain Telemetry Quality Service Tests', () {
    const service = ColdChainTelemetryService();

    test('Compliant pharma cold-chain maintain +2°C to +8°C with low spoilage score', () {
      final now = DateTime.now();
      final samples = List.generate(
        12,
        (i) => TemperatureSample(
          timestamp: now.add(Duration(minutes: i * 5)),
          temperatureC: 4.5 + (i % 3) * 0.5, // 4.5°C to 5.5°C
          humidityPercent: 55.0,
          isReeferUnitActive: true,
          isDoorOpen: false,
        ),
      );

      final report = service.auditColdChain(
        cargoId: 'pharma-covax-01',
        category: CargoCategory.refrigeratedPharma,
        samples: samples,
      );

      expect(report.isCompliant, isTrue);
      expect(report.totalExcursionMinutes, 0);
      expect(report.spoilageRiskScore < 10.0, isTrue);
      expect(report.meanKineticTemperatureC >= 4.0 && report.meanKineticTemperatureC <= 6.0, isTrue);
    });

    test('Severe thermal excursion and repeated door openings flags compromise', () {
      final now = DateTime.now();
      final samples = [
        TemperatureSample(timestamp: now, temperatureC: 5.0, humidityPercent: 50.0),
        TemperatureSample(timestamp: now.add(const Duration(minutes: 5)), temperatureC: 12.0, humidityPercent: 75.0, isDoorOpen: true),
        TemperatureSample(timestamp: now.add(const Duration(minutes: 10)), temperatureC: 16.0, humidityPercent: 80.0, isDoorOpen: true),
        TemperatureSample(timestamp: now.add(const Duration(minutes: 15)), temperatureC: 18.0, humidityPercent: 85.0, isDoorOpen: true),
        TemperatureSample(timestamp: now.add(const Duration(minutes: 20)), temperatureC: 15.0, humidityPercent: 80.0, isDoorOpen: true),
        TemperatureSample(timestamp: now.add(const Duration(minutes: 25)), temperatureC: 14.0, humidityPercent: 75.0, isDoorOpen: true),
        TemperatureSample(timestamp: now.add(const Duration(minutes: 30)), temperatureC: 11.0, humidityPercent: 70.0, isDoorOpen: true),
      ];

      final report = service.auditColdChain(
        cargoId: 'pharma-insulin-02',
        category: CargoCategory.refrigeratedPharma,
        samples: samples,
      );

      expect(report.isCompliant, isFalse);
      expect(report.totalExcursionMinutes >= 30, isTrue);
      expect(report.spoilageRiskScore > 50.0, isTrue);
      expect(report.complianceVerdict.contains('Compromised'), isTrue);
    });
  });

  group('Loop 74: AQIL UI Multi-Viewport & Accessibility Tests', () {
    const service = ColdChainTelemetryService();

    final testReport = service.auditColdChain(
      cargoId: 'batch-pfizer-99',
      category: CargoCategory.refrigeratedPharma,
      samples: [
        TemperatureSample(timestamp: DateTime.now(), temperatureC: 5.2, humidityPercent: 55.0),
      ],
    );

    testWidgets('ColdChainMktQualityCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ColdChainMktQualityCard(
                report: testReport,
                consignmentBatchNumber: 'VAX-2026-IND-DEL-98441',
                onExportCertificate: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('VAX-2026-IND-DEL-98441'), findsOneWidget);
      expect(find.textContaining('Pharma Cold-Chain CoA Certificate'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ColdChainMktQualityCard maintains integrity under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: SingleChildScrollView(
                child: ColdChainMktQualityCard(
                  report: testReport,
                  consignmentBatchNumber: 'VAX-2026-IND',
                  onExportCertificate: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ColdChainMktQualityCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
