import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/wheel_end_thermal_service.dart';
import 'package:evehicle_logbook/core/widgets/wheel_end_thermal_card.dart';

void main() {
  group('Loop 82: Wheel-End Thermal & Bearing Hub Health Monitor Tests', () {
    const service = WheelEndThermalService();

    test('Overheated hub bearing triggers critical safety alarm', () {
      final readings = [
        const WheelSensorReading(
          sensorId: 's-steer-l',
          axle: AxlePosition.steer,
          isLeft: true,
          pressurePsi: 110.0,
          temperatureCelsius: 65.0,
          baselinePressurePsi: 110.0,
        ),
        const WheelSensorReading(
          sensorId: 's-steer-r',
          axle: AxlePosition.steer,
          isLeft: false,
          pressurePsi: 112.0,
          temperatureCelsius: 102.0, // Overheat (>95°C and ΔT > 25°C)
          baselinePressurePsi: 110.0,
        ),
      ];

      final result = service.evaluateWheelEnds(
        vehicleId: 'TRK-900',
        readings: readings,
      );

      expect(result.hasCriticalBearingAlert, isTrue);
      expect(result.isSafe, isFalse);
      expect(result.anomalies.first.severity, equals(WheelEndAlertSeverity.critical));
      expect(result.summaryStatus, contains('CRITICAL'));
    });

    test('Severe underinflation flags advisory maintenance', () {
      final readings = [
        const WheelSensorReading(
          sensorId: 's-drive-l',
          axle: AxlePosition.drive,
          isLeft: true,
          pressurePsi: 75.0, // 31.8% below 110 baseline
          temperatureCelsius: 60.0,
          baselinePressurePsi: 110.0,
        ),
      ];

      final result = service.evaluateWheelEnds(
        vehicleId: 'TRK-900',
        readings: readings,
      );

      expect(result.hasUnderinflationAlert, isTrue);
      expect(result.hasCriticalBearingAlert, isFalse);
      expect(result.anomalies.first.title, contains('Underinflation'));
    });

    test('Nominal temperatures and pressures report safe', () {
      final readings = [
        const WheelSensorReading(
          sensorId: 's-steer-l',
          axle: AxlePosition.steer,
          isLeft: true,
          pressurePsi: 110.0,
          temperatureCelsius: 62.0,
          baselinePressurePsi: 110.0,
        ),
        const WheelSensorReading(
          sensorId: 's-steer-r',
          axle: AxlePosition.steer,
          isLeft: false,
          pressurePsi: 110.0,
          temperatureCelsius: 64.0,
          baselinePressurePsi: 110.0,
        ),
      ];

      final result = service.evaluateWheelEnds(
        vehicleId: 'TRK-900',
        readings: readings,
      );

      expect(result.isSafe, isTrue);
      expect(result.anomalies, isEmpty);
    });

    testWidgets('AQIL: WheelEndThermalCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final readings = [
        const WheelSensorReading(
          sensorId: 's-steer-l',
          axle: AxlePosition.steer,
          isLeft: true,
          pressurePsi: 110.0,
          temperatureCelsius: 65.0,
          baselinePressurePsi: 110.0,
        ),
        const WheelSensorReading(
          sensorId: 's-steer-r',
          axle: AxlePosition.steer,
          isLeft: false,
          pressurePsi: 112.0,
          temperatureCelsius: 98.0,
          baselinePressurePsi: 110.0,
        ),
      ];

      final result = service.evaluateWheelEnds(
        vehicleId: 'TRK-900',
        readings: readings,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WheelEndThermalCard(
                result: result,
                onInspectHubs: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(WheelEndThermalCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
