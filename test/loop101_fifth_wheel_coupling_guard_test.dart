import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/fifth_wheel_coupling_guard_service.dart';
import 'package:evehicle_logbook/core/widgets/fifth_wheel_coupler_card.dart';

void main() {
  group('Loop 101: Articulated Semi-Trailer Fifth Wheel Coupler Lock Sentinel Tests', () {
    const service = FifthWheelCouplingGuardService();

    test('Fully seated kingpin and engaged secondary lock reports secure status', () {
      const telemetry = FifthWheelTelemetry(
        kingpinDepthMm: 50.0,
        jawClampPressureBar: 130.0,
        isSecondarySafetyLockEngaged: true,
        trailerLoadMetricTons: 28.5,
        couplingAngleDegrees: 2.1,
      );

      final result = service.evaluateCoupling(
        vehicleId: 'TRK-VOLVO-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(FifthWheelSecurityStatus.securelyLocked));
      expect(result.isSafeToDrive, isTrue);
      expect(result.isCritical, isFalse);
      expect(result.hitchIntegrityScorePercent, equals(100.0));
      expect(result.safetyAdvisory, contains('NOMINAL'));
    });

    test('Unseated kingpin or low jaw pressure triggers critical false lock risk', () {
      const telemetry = FifthWheelTelemetry(
        kingpinDepthMm: 32.0, // Dangerous false hook / high-hitch
        jawClampPressureBar: 55.0,
        isSecondarySafetyLockEngaged: false,
        trailerLoadMetricTons: 30.0,
        couplingAngleDegrees: 5.0,
      );

      final result = service.evaluateCoupling(
        vehicleId: 'TRK-VOLVO-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(FifthWheelSecurityStatus.criticalFalseLockRisk));
      expect(result.isSafeToDrive, isFalse);
      expect(result.isCritical, isTrue);
      expect(result.safetyAdvisory, contains('CRITICAL'));
    });

    testWidgets('AQIL: FifthWheelCouplerCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = FifthWheelTelemetry(
        kingpinDepthMm: 51.0,
        jawClampPressureBar: 125.0,
        isSecondarySafetyLockEngaged: true,
        trailerLoadMetricTons: 24.0,
        couplingAngleDegrees: 1.5,
      );
      final result = service.evaluateCoupling(vehicleId: 'TRK-320', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FifthWheelCouplerCard(result: result),
            ),
          ),
        ),
      );

      expect(find.text('Fifth Wheel Coupler Guard'), findsOneWidget);
      expect(find.text('SECURELY LOCKED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AQIL: FifthWheelCouplerCard scales gracefully under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = FifthWheelTelemetry(
        kingpinDepthMm: 35.0,
        jawClampPressureBar: 60.0,
        isSecondarySafetyLockEngaged: false,
        trailerLoadMetricTons: 32.0,
        couplingAngleDegrees: 8.0,
      );
      final result = service.evaluateCoupling(vehicleId: 'TRK-FONT', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: FifthWheelCouplerCard(result: result),
              ),
            ),
          ),
        ),
      );

      expect(find.text('FALSE LOCK RISK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
