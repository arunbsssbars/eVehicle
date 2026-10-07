import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/carbon_offset_ledger_service.dart';
import 'package:evehicle_logbook/core/widgets/carbon_offset_ledger_card.dart';

void main() {
  group('Loop 36 - Carbon Offset & Scope 1 ESG Ledger Service', () {
    const service = CarbonOffsetLedgerService();

    test('Full carbon offset retirement achieves 100% Net-Zero certification', () {
      // 10,000 Liters = 26.8 metric tons CO2
      final batches = [
        OffsetCreditBatch(
          batchId: 'VCS-2026-001',
          projectName: 'Amazon Rainforest Biome Restoration',
          metricTonsOffset: 30.0,
          pricePerTonUsd: 14.50,
          retirementDate: DateTime(2026, 10, 3),
          registrySerialNumber: 'VERRA-1029384-BR',
        ),
      ];

      final audit = service.reconcileOffsetLedger(
        totalFuelLiters: 10000.0,
        creditBatches: batches,
      );

      expect(audit.grossEmissionsTonsCo2, equals(26.8));
      expect(audit.totalOffsetTonsCo2, equals(30.0));
      expect(audit.netEmissionsTonsCo2, equals(0.0));
      expect(audit.isCarbonNeutralCertified, isTrue);
      expect(audit.offsetCoveragePercentage, equals(100.0));
      expect(audit.certificateHash.isNotEmpty, isTrue);
      expect(audit.esgStatusSummary, contains('VERIFIED NET-ZERO'));
    });

    test('Partial offset calculation correctly computes residual emissions and spend', () {
      // 20,000 Liters = 53.6 metric tons CO2
      final batches = [
        OffsetCreditBatch(
          batchId: 'GS-2026-042',
          projectName: 'Rift Valley Geothermal Clean Grid',
          metricTonsOffset: 20.0,
          pricePerTonUsd: 18.00,
          retirementDate: DateTime(2026, 10, 3),
          registrySerialNumber: 'GS-59403-KEN',
        ),
      ];

      final audit = service.reconcileOffsetLedger(
        totalFuelLiters: 20000.0,
        creditBatches: batches,
      );

      expect(audit.isCarbonNeutralCertified, isFalse);
      expect(audit.totalOffsetExpenditureUsd, equals(360.0));
      expect(audit.netEmissionsTonsCo2, closeTo(33.6, 0.1));
    });
  });

  group('Loop 36 - Carbon Offset AQIL Responsive UI Tests', () {
    testWidgets('CarbonOffsetLedgerCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = EsgCarbonLedgerAudit(
        grossEmissionsTonsCo2: 24.5,
        totalOffsetTonsCo2: 25.0,
        netEmissionsTonsCo2: 0.0,
        offsetCoveragePercentage: 100.0,
        totalOffsetExpenditureUsd: 375.0,
        isCarbonNeutralCertified: true,
        retiredBatches: [],
        certificateHash: 'A9B48F27CD184EE9',
        esgStatusSummary: 'VERIFIED NET-ZERO: Scope 1 fleet emissions neutralized.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarbonOffsetLedgerCard(
              audit: audit,
              onDownloadEsgCertificate: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ESG Scope 1 Carbon Ledger'), findsOneWidget);
      expect(find.text('NET-ZERO'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CarbonOffsetLedgerCard preserves layout stability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = EsgCarbonLedgerAudit(
        grossEmissionsTonsCo2: 50.0,
        totalOffsetTonsCo2: 20.0,
        netEmissionsTonsCo2: 30.0,
        offsetCoveragePercentage: 40.0,
        totalOffsetExpenditureUsd: 300.0,
        isCarbonNeutralCertified: false,
        retiredBatches: [],
        certificateHash: 'F83B109C481A7210',
        esgStatusSummary: 'LOW OFFSET COVERAGE: High residual carbon footprint.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Scaffold(
              body: CarbonOffsetLedgerCard(
                audit: audit,
                onDownloadEsgCertificate: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PARTIAL'), findsOneWidget);
      expect(find.text('Export Corporate ESG Offset Certificate'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
