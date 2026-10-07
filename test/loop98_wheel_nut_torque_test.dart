import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/wheel_nut_torque_sentinel_service.dart';
import 'package:evehicle_logbook/core/widgets/wheel_nut_torque_sentinel_card.dart';

void main() {
  group('Loop 98: Commercial Wheel Nut Torque Loss & Fastener Tests', () {
    const service = WheelNutTorqueSentinelService();

    test('Fully torqued 10-stud hub reports secure clamping status', () {
      final samples = List.generate(
        10,
        (i) => WheelNutTorqueSample(
          studIndex: i + 1,
          measuredTorqueNm: 620.0,
          nominalSpecTorqueNm: 600.0,
          studElongationMm: 0.12,
          isNutLooseOrMissing: false,
        ),
      );

      final result = service.evaluateWheelFasteners(
        vehicleId: 'TRK-WHEEL-01',
        wheelEndPosition: 'Steer Axle Left',
        samples: samples,
      );

      expect(result.status, equals(WheelClampingStatus.secure));
      expect(result.isSafe, isTrue);
      expect(result.totalLooseFastenersCount, equals(0));
      expect(result.isGroundingMandatory, isFalse);
    });

    test('Multiple loose wheel nuts trigger emergency wheel-off separation alarm', () {
      final samples = [
        const WheelNutTorqueSample(
          studIndex: 1,
          measuredTorqueNm: 200.0, // Loose (< 65% of 600 Nm)
          studElongationMm: 0.0,
          isNutLooseOrMissing: true,
        ),
        const WheelNutTorqueSample(
          studIndex: 2,
          measuredTorqueNm: 250.0, // Loose
          studElongationMm: 0.0,
          isNutLooseOrMissing: false,
        ),
        const WheelNutTorqueSample(
          studIndex: 3,
          measuredTorqueNm: 600.0,
          studElongationMm: 0.12,
          isNutLooseOrMissing: false,
        ),
      ];

      final result = service.evaluateWheelFasteners(
        vehicleId: 'TRK-WHEEL-01',
        wheelEndPosition: 'Drive Axle Right',
        samples: samples,
      );

      expect(result.status, equals(WheelClampingStatus.imminentWheelOffEmergency));
      expect(result.isSafe, isFalse);
      expect(result.totalLooseFastenersCount, equals(2));
      expect(result.isGroundingMandatory, isTrue);
      expect(result.safetyAdvisory, contains('WHEEL-OFF EMERGENCY'));
    });

    testWidgets('AQIL: WheelNutTorqueSentinelCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final samples = [
        const WheelNutTorqueSample(
          studIndex: 1,
          measuredTorqueNm: 610.0,
          studElongationMm: 0.12,
          isNutLooseOrMissing: false,
        ),
      ];

      final result = service.evaluateWheelFasteners(
        vehicleId: 'TRK-WHEEL-01',
        wheelEndPosition: 'Steer Axle Left',
        samples: samples,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WheelNutTorqueSentinelCard(
                result: result,
                onLogWheelTorqueCheck: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(WheelNutTorqueSentinelCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
