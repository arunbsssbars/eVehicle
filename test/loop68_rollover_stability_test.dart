import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/rollover_stability_service.dart';
import 'package:evehicle_logbook/core/widgets/rollover_stability_card.dart';

void main() {
  group('Loop 68 - RolloverStabilityService Unit Tests', () {
    late RolloverStabilityService service;

    setUp(() {
      service = const RolloverStabilityService();
    });

    test('Straight highway cruising maintains stable nominal state', () {
      const telemetry = RolloverDynamicsTelemetry(
        vehicleSpeedKmh: 90.0,
        steeringAngleDegrees: 1.2,
        lateralAccelerationG: 0.04,
        yawRateDegreesPerSecond: 0.5,
        centerOfGravityHeightMeters: 1.6,
        trackWidthMeters: 2.05,
      );

      final audit = service.evaluateStability(telemetry);

      expect(audit.riskState, RolloverRiskState.stableNominal);
      expect(audit.espInterventionTriggered, isFalse);
      expect(audit.loadTransferRatio, lessThan(0.15));
      expect(audit.targetTorqueCutbackPercent, 0.0);
    });

    test('Moderate cloverleaf ramp induces lateral G advisory warning', () {
      const telemetry = RolloverDynamicsTelemetry(
        vehicleSpeedKmh: 55.0,
        steeringAngleDegrees: 25.0,
        lateralAccelerationG: 0.28,
        yawRateDegreesPerSecond: 7.2,
        centerOfGravityHeightMeters: 1.7,
        trackWidthMeters: 2.05,
      );

      final audit = service.evaluateStability(telemetry);

      expect(audit.riskState, RolloverRiskState.lateralGWarning);
      expect(audit.espInterventionTriggered, isFalse);
      expect(audit.targetTorqueCutbackPercent, 15.0);
    });

    test('High-speed obstacle avoidance activates ESP differential braking and de-rate', () {
      const telemetry = RolloverDynamicsTelemetry(
        vehicleSpeedKmh: 75.0,
        steeringAngleDegrees: 60.0,
        lateralAccelerationG: 0.52,
        yawRateDegreesPerSecond: 18.0,
        centerOfGravityHeightMeters: 1.8,
        trackWidthMeters: 2.05,
      );

      final audit = service.evaluateStability(telemetry);

      expect(audit.riskState, RolloverRiskState.criticalTrippingOrRollThreshold);
      expect(audit.espInterventionTriggered, isTrue);
      expect(audit.loadTransferRatio, greaterThanOrEqualTo(0.85));
      expect(audit.targetTorqueCutbackPercent, 100.0);
      expect(audit.activeInterventionSummary, contains('CRITICAL ROLLOVER RISK'));
    });
  });

  group('Loop 68 - RolloverStabilityCard Widget & AQIL Tests', () {
    testWidgets('Renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const telemetry = RolloverDynamicsTelemetry(
        vehicleSpeedKmh: 80.0,
        steeringAngleDegrees: 2.0,
        lateralAccelerationG: 0.05,
        yawRateDegreesPerSecond: 0.6,
        centerOfGravityHeightMeters: 1.5,
        trackWidthMeters: 2.05,
      );

      const audit = RolloverStabilityAudit(
        riskState: RolloverRiskState.stableNominal,
        staticRolloverThresholdG: 0.68,
        loadTransferRatio: 0.08,
        espInterventionTriggered: false,
        activeInterventionSummary: 'STABLE: Cornering dynamics well within static roll limit.',
        targetTorqueCutbackPercent: 0.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RolloverStabilityCard(
                audit: audit,
                telemetry: telemetry,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Roll Stability & ESP Guard'), findsOneWidget);
      expect(find.text('STABLE'), findsOneWidget);
      expect(find.text('0.68 G'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Displays active ESP intervention button and scales under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const telemetry = RolloverDynamicsTelemetry(
        vehicleSpeedKmh: 72.0,
        steeringAngleDegrees: 55.0,
        lateralAccelerationG: 0.48,
        yawRateDegreesPerSecond: 16.0,
        centerOfGravityHeightMeters: 1.8,
        trackWidthMeters: 2.05,
      );

      const audit = RolloverStabilityAudit(
        riskState: RolloverRiskState.espDifferentialBrakingActive,
        staticRolloverThresholdG: 0.57,
        loadTransferRatio: 0.84,
        espInterventionTriggered: true,
        activeInterventionSummary: 'ESP / RSC ACTIVE: Lateral G exceeds roll safety threshold.',
        targetTorqueCutbackPercent: 65.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: RolloverStabilityCard(
                  audit: audit,
                  telemetry: telemetry,
                  onResetEspFault: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ESP ACTIVE'), findsOneWidget);
      expect(find.text('Review ESP Intervention Telemetry'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
