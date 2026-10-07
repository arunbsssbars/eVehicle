import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/brake_lining_forecaster_service.dart';
import 'package:evehicle_logbook/core/widgets/brake_lining_forecaster_card.dart';

void main() {
  group('Loop 83: Brake Pad Wear & Lifespan Forecaster Tests', () {
    const service = BrakeLiningForecasterService();

    test('Brake pad worn below minimum triggers grounding warning', () {
      const telemetry = BrakeLiningTelemetry(
        axleId: 'steer-axle',
        currentThicknessMm: 2.5, // Below 3.0mm discard threshold
        accumulatedKilometers: 65000.0,
      );

      final result = service.forecastBrakeLifespan(
        vehicleId: 'BUS-102',
        telemetry: telemetry,
      );

      expect(result.isImmediateGrounded, isTrue);
      expect(result.wearPercentage, equals(100.0));
      expect(result.advisoryMessage, contains('DANGER: Brake pad below statutory minimum'));
    });

    test('Brake pad with healthy lining forecasts accurate remaining distance', () {
      const telemetry = BrakeLiningTelemetry(
        axleId: 'drive-axle',
        currentThicknessMm: 14.0, // 4mm worn out of 15mm usable
        initialThicknessMm: 18.0,
        discardThicknessMm: 3.0,
        accumulatedKilometers: 20000.0,
      );

      final result = service.forecastBrakeLifespan(
        vehicleId: 'TRK-400',
        telemetry: telemetry,
      );

      expect(result.isImmediateGrounded, isFalse);
      expect(result.isReplacementDue, isFalse);
      expect(result.estimatedRemainingKm > 30000.0, isTrue);
      expect(result.advisoryMessage, contains('Brake linings nominal'));
    });

    testWidgets('AQIL: BrakeLiningForecasterCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = BrakeLiningTelemetry(
        axleId: 'drive-axle',
        currentThicknessMm: 5.0,
        accumulatedKilometers: 45000.0,
      );

      final result = service.forecastBrakeLifespan(
        vehicleId: 'TRK-400',
        telemetry: telemetry,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BrakeLiningForecasterCard(
                result: result,
                onScheduleBrakeService: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BrakeLiningForecasterCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
