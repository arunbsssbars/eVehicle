import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/brake_fade_thermal_service.dart';
import 'package:evehicle_logbook/core/widgets/brake_fade_thermal_card.dart';

void main() {
  group('Loop 65 - BrakeFadeThermalService Unit Tests', () {
    late BrakeFadeThermalService service;

    setUp(() {
      service = const BrakeFadeThermalService();
    });

    test('Gentle grade with auxiliary retarder keeps brake thermal load nominal', () {
      const telemetry = MountainDescentTelemetry(
        grossVehicleWeightKg: 24000.0,
        roadGradePercent: -3.0,
        descentSpeedKmh: 60.0,
        descentDistanceMeters: 2000.0,
        ambientTemperatureCelsius: 20.0,
        initialBrakeRotorTempCelsius: 110.0,
        auxiliaryRetarderRetardationKw: 120.0,
      );

      final audit = service.predictThermalLoad(telemetry);

      expect(audit.riskLevel, BrakeFadeRiskLevel.nominalCool);
      expect(audit.estimatedRotorTempCelsius, lessThan(280.0));
      expect(audit.runawayRampRequired, isFalse);
    });

    test('Steep descent without retarder causes imminent brake fade', () {
      const telemetry = MountainDescentTelemetry(
        grossVehicleWeightKg: 38000.0, // Fully loaded articulated truck
        roadGradePercent: -7.5,        // Severe mountain grade
        descentSpeedKmh: 65.0,
        descentDistanceMeters: 6000.0,
        ambientTemperatureCelsius: 30.0,
        initialBrakeRotorTempCelsius: 220.0,
        auxiliaryRetarderRetardationKw: 0.0, // Friction brakes alone
      );

      final audit = service.predictThermalLoad(telemetry);

      expect(
        audit.riskLevel == BrakeFadeRiskLevel.imminentBrakeFadeWarning ||
            audit.riskLevel == BrakeFadeRiskLevel.criticalThermalRunawayLockout,
        isTrue,
      );
      expect(audit.estimatedRotorTempCelsius, greaterThan(450.0));
      expect(audit.recommendedSafeDescentSpeedKmh, lessThanOrEqualTo(40.0));
    });

    test('Severe descent over long distance triggers runaway ramp advisory', () {
      const telemetry = MountainDescentTelemetry(
        grossVehicleWeightKg: 42000.0,
        roadGradePercent: -9.0,
        descentSpeedKmh: 80.0,
        descentDistanceMeters: 10000.0,
        ambientTemperatureCelsius: 35.0,
        initialBrakeRotorTempCelsius: 350.0,
        auxiliaryRetarderRetardationKw: 0.0,
      );

      final audit = service.predictThermalLoad(telemetry);

      expect(audit.riskLevel, BrakeFadeRiskLevel.criticalThermalRunawayLockout);
      expect(audit.runawayRampRequired, isTrue);
      expect(audit.safetyAdvisory, contains('runaway truck ramp'));
    });
  });

  group('Loop 65 - BrakeFadeThermalCard Widget & AQIL Tests', () {
    testWidgets('Renders properly in compact 320px viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const telemetry = MountainDescentTelemetry(
        grossVehicleWeightKg: 36000.0,
        roadGradePercent: -6.5,
        descentSpeedKmh: 50.0,
        descentDistanceMeters: 4000.0,
        ambientTemperatureCelsius: 25.0,
        initialBrakeRotorTempCelsius: 180.0,
      );

      const audit = BrakeThermalAudit(
        estimatedRotorTempCelsius: 480.0,
        cumulativeDissipatedEnergyMegaJoules: 78.4,
        brakingThermalAbsorptionKw: 240.0,
        riskLevel: BrakeFadeRiskLevel.imminentBrakeFadeWarning,
        recommendedSafeDescentSpeedKmh: 40.0,
        safetyAdvisory: 'IMMINENT BRAKE FADE: High thermal saturation. Downshift immediately.',
        runawayRampRequired: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BrakeFadeThermalCard(
                audit: audit,
                telemetry: telemetry,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grade Brake Thermal Profiler'), findsOneWidget);
      expect(find.text('FADE RISK'), findsOneWidget);
      expect(find.text('480°C'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders runaway ramp action button and scales under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const telemetry = MountainDescentTelemetry(
        grossVehicleWeightKg: 42000.0,
        roadGradePercent: -9.0,
        descentSpeedKmh: 75.0,
        descentDistanceMeters: 8000.0,
        ambientTemperatureCelsius: 30.0,
        initialBrakeRotorTempCelsius: 320.0,
      );

      const audit = BrakeThermalAudit(
        estimatedRotorTempCelsius: 680.0,
        cumulativeDissipatedEnergyMegaJoules: 140.2,
        brakingThermalAbsorptionKw: 380.0,
        riskLevel: BrakeFadeRiskLevel.criticalThermalRunawayLockout,
        recommendedSafeDescentSpeedKmh: 25.0,
        safetyAdvisory: 'CRITICAL BRAKE TEMPERATURE: Prepare for emergency runaway truck ramp.',
        runawayRampRequired: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: BrakeFadeThermalCard(
                  audit: audit,
                  telemetry: telemetry,
                  onActivateRunawayRampGuidance: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CRITICAL FADE'), findsOneWidget);
      expect(find.text('Locate Runaway Escape Ramp'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
