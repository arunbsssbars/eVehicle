import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/models/fleet_executive_report.dart';
import 'package:evehicle_logbook/core/services/fleet_report_generator_service.dart';
import 'package:evehicle_logbook/core/widgets/fleet_report_preview_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Loop 17: Scheduled PDF / Executive Fleet Briefing Generator Tests', () {
    test('generateBriefing calculates CPK, fleet utilization, and compliance score accurately', () {
      final report = FleetReportGeneratorService.generateBriefing(
        id: 'RPT-2026-W40',
        type: FleetReportType.weeklyExecutive,
        dateRangeLabel: 'Sep 25 - Oct 02, 2026',
        totalVehicles: 20,
        activeVehicles: 18,
        totalDistanceKm: 10000.0,
        totalFuelSpend: 65000.0,
        safetyIncidentCount: 1, // -8 penalty
        pendingMaintenanceAlerts: 2, // -8 penalty
        generatedAt: DateTime(2026, 10, 3, 9, 0),
      );

      expect(report.fleetUtilizationPercent, equals(90.0));
      expect(report.averageCpk, equals(6.5));
      expect(report.complianceScore, equals(84.0)); // 100 - 8 - 8 = 84
      expect(report.highlights.length, greaterThanOrEqualTo(3));
      expect(report.highlights.any((h) => h.contains('utilization at 90.0%')), isTrue);
    });

    test('exportStructuredBriefingText formats plain text report accurately', () {
      final report = FleetReportGeneratorService.generateBriefing(
        id: 'RPT-DAILY-01',
        type: FleetReportType.dailySnapshot,
        dateRangeLabel: 'Oct 02, 2026',
        totalVehicles: 10,
        activeVehicles: 10,
        totalDistanceKm: 2500.0,
        totalFuelSpend: 15000.0,
        safetyIncidentCount: 0,
        pendingMaintenanceAlerts: 0,
      );

      final exportedText = FleetReportGeneratorService.exportStructuredBriefingText(report);

      expect(exportedText, contains('FLEET EXECUTIVE BRIEFING'));
      expect(exportedText, contains('Report ID: RPT-DAILY-01'));
      expect(exportedText, contains('Total Distance: 2500.0 km'));
      expect(exportedText, contains('Compliance Score: 100.0 / 100.0'));
      expect(exportedText, contains('Zero safety violations'));
    });

    test('FleetExecutiveReport JSON serialization round-trip works seamlessly', () {
      final original = FleetReportGeneratorService.generateBriefing(
        id: 'RPT-MONTHLY-09',
        type: FleetReportType.monthlyAudit,
        dateRangeLabel: 'September 2026',
        totalVehicles: 25,
        activeVehicles: 24,
        totalDistanceKm: 45000.0,
        totalFuelSpend: 270000.0,
        safetyIncidentCount: 3,
        pendingMaintenanceAlerts: 1,
      );

      final json = original.toJson();
      final restored = FleetExecutiveReport.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.type, equals(original.type));
      expect(restored.totalDistanceKm, equals(original.totalDistanceKm));
      expect(restored.averageCpk, equals(original.averageCpk));
      expect(restored.complianceScore, equals(original.complianceScore));
    });

    testWidgets('AQIL: FleetReportPreviewCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final report = FleetReportGeneratorService.generateBriefing(
        id: 'RPT-AQIL-01',
        type: FleetReportType.weeklyExecutive,
        dateRangeLabel: 'Sep 25 - Oct 02, 2026',
        totalVehicles: 15,
        activeVehicles: 14,
        totalDistanceKm: 8500.0,
        totalFuelSpend: 51000.0,
        safetyIncidentCount: 1,
        pendingMaintenanceAlerts: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: FleetReportPreviewCard(
                report: report,
                onDownloadPdf: () {},
                onShareReport: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(FleetReportPreviewCard), findsOneWidget);
      expect(find.text('Download PDF'), findsOneWidget);
      expect(find.text('Share Brief'), findsOneWidget);
    });

    testWidgets('AQIL: FleetReportPreviewCard scales safely under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final report = FleetReportGeneratorService.generateBriefing(
        id: 'RPT-AQIL-02',
        type: FleetReportType.monthlyAudit,
        dateRangeLabel: 'September 2026',
        totalVehicles: 10,
        activeVehicles: 9,
        totalDistanceKm: 12000.0,
        totalFuelSpend: 72000.0,
        safetyIncidentCount: 0,
        pendingMaintenanceAlerts: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FleetReportPreviewCard(report: report),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(FleetReportPreviewCard), findsOneWidget);
      expect(find.text('100% SCORE'), findsOneWidget);
    });
  });
}
