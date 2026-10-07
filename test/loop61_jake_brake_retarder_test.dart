import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/jake_brake_retarder_service.dart';
import 'package:evehicle_logbook/core/widgets/jake_brake_retarder_card.dart';

void main() {
  group('Loop 61 - Jake Brake & Compression Retarder Tests', () {
    const service = JakeBrakeRetarderService();

    test('evaluateRetarder disengages retarder on flat or uphill terrain', () {
      const telemetry = RetarderGradeTelemetry(
        roadGradePercent: 1.5,
        vehicleGrossWeightKg: 40000.0,
        currentVehicleSpeedKmh: 80.0,
        targetDescentSpeedKmh: 80.0,
        inMuffledNoiseOrdinanceZone: false,
        activeStage: CompressionRetarderStage.off,
      );

      final audit = service.evaluateRetarder(telemetry);
      expect(audit.recommendedStage, CompressionRetarderStage.off);
      expect(audit.retardingPowerKw, 0.0);
      expect(audit.serviceBrakeAssistanceRequired, isFalse);
    });

    test('evaluateRetarder selects Stage 3 full power on steep mountain grades', () {
      // -7% grade at 40,000 kg requires significant holding power
      const telemetry = RetarderGradeTelemetry(
        roadGradePercent: -7.0,
        vehicleGrossWeightKg: 40000.0,
        currentVehicleSpeedKmh: 65.0,
        targetDescentSpeedKmh: 60.0,
        inMuffledNoiseOrdinanceZone: false,
        activeStage: CompressionRetarderStage.highStage3,
      );

      final audit = service.evaluateRetarder(telemetry);
      expect(audit.recommendedStage, CompressionRetarderStage.highStage3);
      expect(audit.retardingPowerKw, greaterThan(250.0));
      expect(audit.noiseZoneStatus, RetarderNoiseZoneStatus.unrestrictedHighway);
    });

    test('evaluateRetarder enforces noise ordinance unless emergency grade override is met', () {
      const standardNoiseZone = RetarderGradeTelemetry(
        roadGradePercent: -3.0,
        vehicleGrossWeightKg: 36000.0,
        currentVehicleSpeedKmh: 50.0,
        targetDescentSpeedKmh: 50.0,
        inMuffledNoiseOrdinanceZone: true,
        activeStage: CompressionRetarderStage.off,
      );

      final audit = service.evaluateRetarder(standardNoiseZone);
      expect(audit.recommendedStage, CompressionRetarderStage.off);
      expect(audit.noiseZoneStatus, RetarderNoiseZoneStatus.noiseOrdinanceRestricted);
    });

    testWidgets('JakeBrakeRetarderCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = RetarderGradeAudit(
        recommendedStage: CompressionRetarderStage.highStage3,
        retardingPowerKw: 400.0,
        gravitationalDownhillForceKn: 27.5,
        noiseZoneStatus: RetarderNoiseZoneStatus.unrestrictedHighway,
        operationalAdvisory: 'MOUNTAIN DESCENT ACTIVE: Stage 3 holding equilibrium.',
        serviceBrakeAssistanceRequired: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JakeBrakeRetarderCard(
              audit: audit,
              roadGradePercent: -7.0,
              onToggleRetarderStage: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jake Brake & Grade Retarder'), findsOneWidget);
      expect(find.text('RETARDER ACTIVE'), findsOneWidget);
      expect(find.text('Manually Select Retarder Stage'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('JakeBrakeRetarderCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = RetarderGradeAudit(
        recommendedStage: CompressionRetarderStage.off,
        retardingPowerKw: 0.0,
        gravitationalDownhillForceKn: 0.0,
        noiseZoneStatus: RetarderNoiseZoneStatus.noiseOrdinanceRestricted,
        operationalAdvisory: 'NOISE ORDINANCE RESTRICTION.',
        serviceBrakeAssistanceRequired: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: JakeBrakeRetarderCard(
                audit: audit,
                roadGradePercent: -2.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NO JAKE ZONE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
