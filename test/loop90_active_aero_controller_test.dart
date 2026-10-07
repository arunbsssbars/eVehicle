import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/active_aero_controller_service.dart';
import 'package:evehicle_logbook/core/widgets/active_aero_controller_card.dart';

void main() {
  group('Loop 90: Active Aerodynamic Drag Controller Tests', () {
    const service = ActiveAeroControllerService();

    test('Highway cruise with deployed fairings computes optimal fuel savings', () {
      const telemetry = ActiveAeroTelemetry(
        vehicleSpeedKmh: 88.0,
        headwindSpeedKmh: 12.0,
        isTrailerTailDeployed: true,
        areSideSkirtsIntact: true,
        activeGrilleShutterOpenPercent: 10.0,
        engineCoolantTempCelsius: 86.0,
      );

      final result = service.evaluateAeroState(
        vehicleId: 'TRK-AERO-01',
        telemetry: telemetry,
      );

      expect(result.shouldDeployTrailerTail, isTrue);
      expect(result.shouldCloseGrilleShutters, isTrue);
      expect(result.dragCoefficientReductionPercent, greaterThanOrEqualTo(10.0));
      expect(result.fuelSavingsLitersPer100Km > 1.5, isTrue);
      expect(result.operationalStatus, contains('AERODYNAMIC OPTIMAL'));
    });

    test('Low speed urban driving keeps tail fairings retracted', () {
      const telemetry = ActiveAeroTelemetry(
        vehicleSpeedKmh: 35.0,
        isTrailerTailDeployed: false,
        areSideSkirtsIntact: true,
        activeGrilleShutterOpenPercent: 80.0,
        engineCoolantTempCelsius: 89.0,
      );

      final result = service.evaluateAeroState(
        vehicleId: 'TRK-AERO-01',
        telemetry: telemetry,
      );

      expect(result.shouldDeployTrailerTail, isFalse);
      expect(result.operationalStatus, contains('CITY LOW DRAG'));
    });

    testWidgets('AQIL: ActiveAeroControllerCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = ActiveAeroTelemetry(
        vehicleSpeedKmh: 85.0,
        isTrailerTailDeployed: true,
        areSideSkirtsIntact: true,
        activeGrilleShutterOpenPercent: 15.0,
        engineCoolantTempCelsius: 88.0,
      );

      final result = service.evaluateAeroState(
        vehicleId: 'TRK-AERO-01',
        telemetry: telemetry,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ActiveAeroControllerCard(
                result: result,
                onToggleTrailerFairing: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ActiveAeroControllerCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
