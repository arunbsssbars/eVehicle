import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/air_brake_stroke_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/air_brake_stroke_card.dart';

void main() {
  group('Loop 104: Heavy Truck S-Cam Air Brake Stroke & Slack Adjuster Sentinel Tests', () {
    const service = AirBrakeStrokeAuditorService();

    test('Compliant pushrod stroke under DOT limit passes inspection', () {
      const telemetry = AirBrakeChamberTelemetry(
        pushrodStrokeMm: 38.0,
        ratedStrokeLimitMm: 50.8,
        applicationAirPressurePsi: 95.0,
        drumTemperatureCelsius: 160.0,
      );

      final result = service.auditBrakeChamber(
        vehicleId: 'TRK-BRAKE-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(SlackAdjusterStatus.withinDotSafetyLimit));
      expect(result.isSafeForHighway, isTrue);
      expect(result.isOutOfServiceCondition, isFalse);
      expect(result.safetyDirective, contains('NOMINAL'));
    });

    test('Pushrod stroke exceeding legal 50.8mm limit flags Out of Service (OOS)', () {
      const telemetry = AirBrakeChamberTelemetry(
        pushrodStrokeMm: 54.5, // Exceeds 2.0 inch limit
        ratedStrokeLimitMm: 50.8,
        applicationAirPressurePsi: 90.0,
        drumTemperatureCelsius: 310.0,
      );

      final result = service.auditBrakeChamber(
        vehicleId: 'TRK-BRAKE-02',
        telemetry: telemetry,
      );

      expect(result.status, equals(SlackAdjusterStatus.outOfAdjustmentDanger));
      expect(result.isSafeForHighway, isFalse);
      expect(result.isOutOfServiceCondition, isTrue);
      expect(result.safetyDirective, contains('OUT OF SERVICE'));
    });

    testWidgets('AQIL: AirBrakeStrokeCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = AirBrakeChamberTelemetry(
        pushrodStrokeMm: 36.0,
        applicationAirPressurePsi: 92.0,
        drumTemperatureCelsius: 140.0,
      );
      final result = service.auditBrakeChamber(vehicleId: 'TRK-320', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AirBrakeStrokeCard(result: result),
            ),
          ),
        ),
      );

      expect(find.text('Air Brake Stroke Sentinel'), findsOneWidget);
      expect(find.text('DOT COMPLIANT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AQIL: AirBrakeStrokeCard scales gracefully under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = AirBrakeChamberTelemetry(
        pushrodStrokeMm: 52.0,
        applicationAirPressurePsi: 90.0,
        drumTemperatureCelsius: 320.0,
      );
      final result = service.auditBrakeChamber(vehicleId: 'TRK-FONT', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: AirBrakeStrokeCard(result: result),
              ),
            ),
          ),
        ),
      );

      expect(find.text('OUT OF SERVICE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
