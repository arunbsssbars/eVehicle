import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/pneumatic_air_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/pneumatic_air_auditor_card.dart';

void main() {
  group('Loop 86: Pneumatic Air Brake Pressure & Leakage Rate Auditor Tests', () {
    const service = PneumaticAirAuditorService();

    test('Fully charged pneumatic reservoir reports normal safety status', () {
      const telemetry = PneumaticAirTelemetry(
        primaryReservoirPsi: 120.0,
        secondaryReservoirPsi: 118.0,
        compressorBuildupTimeSeconds: 32.0,
        pressureDropPerMinuteAppliedPsi: 1.5,
      );

      final result = service.auditAirSystem(
        vehicleId: 'TRK-VOLVO-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(AirBrakeIntegrityStatus.normal));
      expect(result.isSafeToOperate, isTrue);
      expect(result.isSpringBrakeLockoutImminent, isFalse);
      expect(result.lowestCircuitPressurePsi, equals(118.0));
    });

    test('Low air pressure drops below lockout threshold and flags critical alarm', () {
      const telemetry = PneumaticAirTelemetry(
        primaryReservoirPsi: 40.0, // Below 45 PSI spring brake lock threshold
        secondaryReservoirPsi: 42.0,
        compressorBuildupTimeSeconds: 65.0,
        pressureDropPerMinuteAppliedPsi: 8.0, // Severe leak
      );

      final result = service.auditAirSystem(
        vehicleId: 'TRK-HAZ-99',
        telemetry: telemetry,
      );

      expect(result.status, equals(AirBrakeIntegrityStatus.criticalSpringBrakeLockout));
      expect(result.isSafeToOperate, isFalse);
      expect(result.safetyAdvisory, contains('Spring emergency brakes locked'));
    });

    testWidgets('AQIL: PneumaticAirAuditorCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = PneumaticAirTelemetry(
        primaryReservoirPsi: 115.0,
        secondaryReservoirPsi: 112.0,
        compressorBuildupTimeSeconds: 35.0,
        pressureDropPerMinuteAppliedPsi: 2.0,
      );

      final result = service.auditAirSystem(
        vehicleId: 'TRK-VOLVO-01',
        telemetry: telemetry,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PneumaticAirAuditorCard(
                result: result,
                onPerformLeakDownTest: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PneumaticAirAuditorCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
