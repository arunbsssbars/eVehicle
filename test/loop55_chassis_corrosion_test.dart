import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/chassis_corrosion_service.dart';
import 'package:evehicle_logbook/core/widgets/chassis_corrosion_card.dart';

void main() {
  group('Loop 55 - Chassis Salt & Corrosion Protection Tests', () {
    const service = ChassisCorrosionService();

    test('evaluateCorrosionRisk reports clean protected state for recently washed vehicle', () {
      const log = UndercarriageExposureLog(
        daysSinceLastChassisWash: 3,
        winterSaltExposureKm: 20,
        ambientHumidityPercent: 45.0,
        protectiveWaxZincRatingPercent: 95.0,
      );

      final audit = service.evaluateCorrosionRisk(log);
      expect(audit.riskLevel, CorrosionRiskLevel.cleanProtected);
      expect(audit.requiresMandatoryChassisWash, isFalse);
      expect(audit.corrosionIndexScore, lessThan(20.0));
    });

    test('evaluateCorrosionRisk triggers mandatory wash for heavy road salt accumulation', () {
      const log = UndercarriageExposureLog(
        daysSinceLastChassisWash: 18,
        winterSaltExposureKm: 850, // Heavy salt road mileage
        ambientHumidityPercent: 78.0,
        protectiveWaxZincRatingPercent: 60.0,
      );

      final audit = service.evaluateCorrosionRisk(log);
      expect(audit.requiresMandatoryChassisWash, isTrue);
      expect(audit.riskLevel, isNot(CorrosionRiskLevel.cleanProtected));
      expect(audit.recommendedWashWindowDays, lessThanOrEqualTo(2));
    });

    test('evaluateCorrosionRisk escalates to critical hazard when unwashed past 28 days', () {
      const log = UndercarriageExposureLog(
        daysSinceLastChassisWash: 32,
        winterSaltExposureKm: 300,
        ambientHumidityPercent: 80.0,
        protectiveWaxZincRatingPercent: 40.0,
      );

      final audit = service.evaluateCorrosionRisk(log);
      expect(audit.riskLevel, CorrosionRiskLevel.criticalCorrosionHazard);
      expect(audit.recommendedWashWindowDays, 0);
      expect(audit.requiresMandatoryChassisWash, isTrue);
    });

    testWidgets('ChassisCorrosionCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = ChassisCorrosionAudit(
        corrosionIndexScore: 82.5,
        riskLevel: CorrosionRiskLevel.criticalCorrosionHazard,
        recommendedWashWindowDays: 0,
        statusSummary: 'CRITICAL SALT CRUST: Prolonged brine exposure.',
        requiresMandatoryChassisWash: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChassisCorrosionCard(
              audit: audit,
              daysSinceWash: 32,
              onScheduleWash: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chassis Salt & Corrosion Guard'), findsOneWidget);
      expect(find.text('CRITICAL SALT'), findsOneWidget);
      expect(find.text('Book Undercarriage High-Pressure Wash'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ChassisCorrosionCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = ChassisCorrosionAudit(
        corrosionIndexScore: 12.0,
        riskLevel: CorrosionRiskLevel.cleanProtected,
        recommendedWashWindowDays: 14,
        statusSummary: 'CHASSIS PROTECTED: Undercarriage clean.',
        requiresMandatoryChassisWash: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: ChassisCorrosionCard(
                audit: audit,
                daysSinceWash: 2,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PROTECTED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
