import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/models/fleet_scorecard_index.dart';
import 'package:evehicle_logbook/core/services/fleet_scorecard_service.dart';
import 'package:evehicle_logbook/core/widgets/executive_fleet_scorecard_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Loop 20: Comprehensive Enterprise Executive Scorecard Tests', () {
    test('calculateScorecard computes weighted composite score and grade A+', () {
      final scorecard = FleetScorecardService.calculateScorecard(
        safetyScore: 95.0, // 95 * 0.35 = 33.25
        maintenanceReliabilityScore: 92.0, // 92 * 0.25 = 23.00
        regulatoryComplianceScore: 90.0, // 90 * 0.25 = 22.50
        esgGreenScore: 88.0, // 88 * 0.15 = 13.20
        // Total = 91.95 => Grade A+
      );

      expect(scorecard.compositeScore, closeTo(91.95, 0.01));
      expect(scorecard.grade, equals(FleetGrade.aPlus));
      expect(scorecard.strategicRecommendations.first, contains('Outstanding fleet operations'));
    });

    test('calculateScorecard maps grade and generates corrective recommendations for lagging pillars', () {
      final laggingScorecard = FleetScorecardService.calculateScorecard(
        safetyScore: 65.0, // Low safety
        maintenanceReliabilityScore: 70.0, // Low maintenance
        regulatoryComplianceScore: 75.0, // Approaching expiry
        esgGreenScore: 60.0, // Excessive idling
      );

      expect(laggingScorecard.grade, equals(FleetGrade.c));
      expect(laggingScorecard.strategicRecommendations.length, greaterThanOrEqualTo(3));
      expect(
        laggingScorecard.strategicRecommendations.any((r) => r.contains('fatigue and speeding')),
        isTrue,
      );
      expect(
        laggingScorecard.strategicRecommendations.any((r) => r.contains('DVIR defect rectification')),
        isTrue,
      );
    });

    test('FleetScorecardIndex JSON serialization round-trip works seamlessly', () {
      final original = FleetScorecardService.calculateScorecard(
        safetyScore: 85.0,
        maintenanceReliabilityScore: 80.0,
        regulatoryComplianceScore: 85.0,
        esgGreenScore: 80.0,
      );

      final json = original.toJson();
      final restored = FleetScorecardIndex.fromJson(json);

      expect(restored.compositeScore, equals(original.compositeScore));
      expect(restored.grade, equals(original.grade));
      expect(restored.safetyScore, equals(original.safetyScore));
    });

    testWidgets('AQIL: ExecutiveFleetScorecardCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final scorecard = FleetScorecardService.calculateScorecard(
        safetyScore: 92.0,
        maintenanceReliabilityScore: 88.0,
        regulatoryComplianceScore: 90.0,
        esgGreenScore: 85.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: ExecutiveFleetScorecardCard(
                scorecard: scorecard,
                onViewDetails: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ExecutiveFleetScorecardCard), findsOneWidget);
      expect(find.text('Executive Fleet Scorecard'), findsOneWidget);
      expect(find.text('View Detailed Analytics'), findsOneWidget);
    });

    testWidgets('AQIL: ExecutiveFleetScorecardCard scales safely under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final scorecard = FleetScorecardService.calculateScorecard(
        safetyScore: 78.0,
        maintenanceReliabilityScore: 75.0,
        regulatoryComplianceScore: 82.0,
        esgGreenScore: 70.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ExecutiveFleetScorecardCard(scorecard: scorecard),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ExecutiveFleetScorecardCard), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });
}
