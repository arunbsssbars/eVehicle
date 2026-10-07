import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/def_quality_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/def_quality_guard_card.dart';

void main() {
  group('Loop 108: Diesel DEF / AdBlue Concentration & Tampering Sentinel Tests', () {
    const service = DefQualityAuditorService();

    test('Certified 32.5% urea concentration passes ISO 22241 compliance audit', () {
      const telemetry = DefQualityTelemetry(
        ureaConcentrationPercent: 32.5,
        tankLevelPercent: 75.0,
        tankTemperatureCelsius: 22.0,
        opticalRefractiveIndex: 1.3829,
        noxReductionConversionPercent: 92.0,
      );

      final result = service.auditDefPurity(
        vehicleId: 'DSL-DEF-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(DefQualityStatus.compliantConcentration));
      expect(result.isCompliant, isTrue);
      expect(result.isInducementTorqueLimitingActive, isFalse);
      expect(result.purityScorePercent, equals(100.0));
      expect(result.complianceAdvisory, contains('NOMINAL'));
    });

    test('Diluted DEF under 26% flags tampering and derate inducement', () {
      const telemetry = DefQualityTelemetry(
        ureaConcentrationPercent: 18.0, // Water diluted
        tankLevelPercent: 40.0,
        tankTemperatureCelsius: 20.0,
        opticalRefractiveIndex: 1.3550,
        noxReductionConversionPercent: 42.0, // Catalyst failure
      );

      final result = service.auditDefPurity(
        vehicleId: 'DSL-DEF-02',
        telemetry: telemetry,
      );

      expect(result.status, equals(DefQualityStatus.criticalTamperingDeNoxShutdown));
      expect(result.isCompliant, isFalse);
      expect(result.isInducementTorqueLimitingActive, isTrue);
      expect(result.complianceAdvisory, contains('CRITICAL'));
    });

    testWidgets('AQIL: DefQualityGuardCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = DefQualityTelemetry(
        ureaConcentrationPercent: 32.6,
        tankLevelPercent: 80.0,
        tankTemperatureCelsius: 21.0,
        opticalRefractiveIndex: 1.3830,
        noxReductionConversionPercent: 91.0,
      );
      final result = service.auditDefPurity(vehicleId: 'DEF-320', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DefQualityGuardCard(result: result),
            ),
          ),
        ),
      );

      expect(find.text('DEF / AdBlue Purity Sentry'), findsOneWidget);
      expect(find.text('ISO 22241 OK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AQIL: DefQualityGuardCard scales gracefully under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = DefQualityTelemetry(
        ureaConcentrationPercent: 19.0,
        tankLevelPercent: 35.0,
        tankTemperatureCelsius: 22.0,
        opticalRefractiveIndex: 1.3560,
        noxReductionConversionPercent: 45.0,
      );
      final result = service.auditDefPurity(vehicleId: 'DEF-FONT', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: DefQualityGuardCard(result: result),
              ),
            ),
          ),
        ),
      );

      expect(find.text('DEF TAMPERED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
