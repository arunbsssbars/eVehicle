import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/air_suspension_leveling_service.dart';
import 'package:evehicle_logbook/core/widgets/air_suspension_leveling_card.dart';

void main() {
  group('Loop 107: Bus & Truck Air Suspension Leveling Valve Sentinel Tests', () {
    const service = AirSuspensionLevelingService();

    test('Symmetrical ride height and balanced bellow pressures pass inspection', () {
      const telemetry = AirSuspensionTelemetry(
        leftBellowPressurePsi: 85.0,
        rightBellowPressurePsi: 86.5,
        leftRideHeightMm: 220.0,
        rightRideHeightMm: 222.0,
        compressorDutyCyclePercent: 20.0,
      );

      final result = service.auditSuspension(
        vehicleId: 'BUS-AIR-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(AirSuspensionStatus.balancedRideHeight));
      expect(result.isBalanced, isTrue);
      expect(result.isCritical, isFalse);
      expect(result.levelingAdvisory, contains('NOMINAL'));
    });

    test('Bellow puncture or severe cross-tilt over 35mm triggers critical rollover alert', () {
      const telemetry = AirSuspensionTelemetry(
        leftBellowPressurePsi: 15.0, // Blown bellow
        rightBellowPressurePsi: 95.0,
        leftRideHeightMm: 165.0,
        rightRideHeightMm: 225.0, // 60 mm tilt
        compressorDutyCyclePercent: 88.0, // Continuous run
      );

      final result = service.auditSuspension(
        vehicleId: 'BUS-AIR-02',
        telemetry: telemetry,
      );

      expect(result.status, equals(AirSuspensionStatus.criticalAirSpringLeakOrOverload));
      expect(result.isBalanced, isFalse);
      expect(result.isCritical, isTrue);
      expect(result.levelingAdvisory, contains('CRITICAL'));
    });

    testWidgets('AQIL: AirSuspensionLevelingCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = AirSuspensionTelemetry(
        leftBellowPressurePsi: 80.0,
        rightBellowPressurePsi: 82.0,
        leftRideHeightMm: 220.0,
        rightRideHeightMm: 221.0,
        compressorDutyCyclePercent: 18.0,
      );
      final result = service.auditSuspension(vehicleId: 'BUS-320', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AirSuspensionLevelingCard(result: result),
            ),
          ),
        ),
      );

      expect(find.text('Air Suspension Leveling Sentry'), findsOneWidget);
      expect(find.text('LEVEL BALANCED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AQIL: AirSuspensionLevelingCard scales gracefully under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = AirSuspensionTelemetry(
        leftBellowPressurePsi: 20.0,
        rightBellowPressurePsi: 90.0,
        leftRideHeightMm: 170.0,
        rightRideHeightMm: 225.0,
        compressorDutyCyclePercent: 80.0,
      );
      final result = service.auditSuspension(vehicleId: 'BUS-FONT', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: AirSuspensionLevelingCard(result: result),
              ),
            ),
          ),
        ),
      );

      expect(find.text('BELLOW LEAK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
