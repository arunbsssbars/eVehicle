import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/tyre_brake_health_service.dart';
import 'package:evehicle_logbook/core/widgets/tyre_brake_health_card.dart';

void main() {
  group('Loop 22 - Tyre & Brake Health Degradation Service', () {
    const service = TyreBrakeHealthService();

    test('Fresh vehicle produces roadworthy status with high tread depth', () {
      final audit = service.calculateHealth(
        currentOdometerKm: 5000,
        lastServiceOdometerKm: 0,
        harshBrakeEventCount: 2,
        grossWeightKg: 1800,
        ratedGvwrKg: 2000,
      );

      expect(audit.isRoadworthy, isTrue);
      expect(audit.minTreadDepthMm, greaterThan(7.0));
      expect(audit.maxBrakeWearPercent, lessThan(30.0));
      expect(audit.safetyAdvisory, contains('NOMINAL'));
    });

    test('Severely worn tyres and harsh braking grounds vehicle below legal limit', () {
      final audit = service.calculateHealth(
        currentOdometerKm: 75000,
        lastServiceOdometerKm: 0,
        harshBrakeEventCount: 40,
        grossWeightKg: 2800,
        ratedGvwrKg: 2000,
      );

      expect(audit.isRoadworthy, isFalse);
      expect(audit.minTreadDepthMm, lessThanOrEqualTo(1.6));
      expect(audit.safetyAdvisory, contains('GROUND VEHICLE'));
    });

    test('Front axle sustains higher wear rate than rear axle due to steering load', () {
      final audit = service.calculateHealth(
        currentOdometerKm: 20000,
        lastServiceOdometerKm: 0,
        harshBrakeEventCount: 5,
        grossWeightKg: 2000,
        ratedGvwrKg: 2000,
      );

      final frontTread = audit.tyres[AxlePosition.frontLeft]!.treadDepthMm;
      final rearTread = audit.tyres[AxlePosition.rearLeft]!.treadDepthMm;
      expect(frontTread, lessThan(rearTread));
    });
  });

  group('Loop 22 - Tyre & Brake AQIL Responsive UI Tests', () {
    testWidgets('TyreBrakeHealthCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const service = TyreBrakeHealthService();
      final health = service.calculateHealth(
        currentOdometerKm: 12000,
        lastServiceOdometerKm: 0,
        harshBrakeEventCount: 3,
        grossWeightKg: 1900,
        ratedGvwrKg: 2000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TyreBrakeHealthCard(
              health: health,
              onScheduleService: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tyre & Brake Telemetry'), findsOneWidget);
      expect(find.text('ROADWORTHY'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TyreBrakeHealthCard maintains layout stability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const service = TyreBrakeHealthService();
      final health = service.calculateHealth(
        currentOdometerKm: 70000,
        lastServiceOdometerKm: 0,
        harshBrakeEventCount: 30,
        grossWeightKg: 2400,
        ratedGvwrKg: 2000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Scaffold(
              body: TyreBrakeHealthCard(
                health: health,
                onScheduleService: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GROUNDED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
