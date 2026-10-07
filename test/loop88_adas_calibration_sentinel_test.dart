import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/adas_calibration_sentinel_service.dart';
import 'package:evehicle_logbook/core/widgets/adas_calibration_sentinel_card.dart';

void main() {
  group('Loop 88: ADAS Radar & Camera Calibration Sentinel Tests', () {
    const service = AdasCalibrationSentinelService();

    test('Clean calibrated optical and radar sensors pass verification', () {
      final sensors = [
        const AdasSensorTelemetry(
          sensorId: 'front-camera-01',
          isFrontCamera: true,
          yawAngleDeviationDegrees: 0.2,
          pitchAngleDeviationDegrees: 0.1,
          opticalTransmissionPercent: 98.0,
          targetTrackingDiscrepancies: 0,
        ),
        const AdasSensorTelemetry(
          sensorId: 'front-radar-77ghz',
          isFrontCamera: false,
          yawAngleDeviationDegrees: 0.3,
          pitchAngleDeviationDegrees: 0.2,
          opticalTransmissionPercent: 100.0,
          targetTrackingDiscrepancies: 1,
        ),
      ];

      final result = service.evaluateAdasAlignment(
        vehicleId: 'TRK-SAFETY-01',
        sensors: sensors,
      );

      expect(result.status, equals(AdasSensorStatus.calibrated));
      expect(result.isEmergencyBrakingInhibited, isFalse);
      expect(result.isFieldTargetCalibrationRequired, isFalse);
    });

    test('Occluded optical camera triggers blind sensor alert and inhibits AEB', () {
      final sensors = [
        const AdasSensorTelemetry(
          sensorId: 'front-camera-01',
          isFrontCamera: true,
          yawAngleDeviationDegrees: 0.2,
          pitchAngleDeviationDegrees: 0.1,
          opticalTransmissionPercent: 28.0, // Heavily blocked by mud/snow (< 45%)
          targetTrackingDiscrepancies: 8,
        ),
      ];

      final result = service.evaluateAdasAlignment(
        vehicleId: 'TRK-SAFETY-01',
        sensors: sensors,
      );

      expect(result.status, equals(AdasSensorStatus.occludedOrBlind));
      expect(result.isEmergencyBrakingInhibited, isTrue);
      expect(result.recommendation, contains('BLIND SENSOR'));
    });

    testWidgets('AQIL: AdasCalibrationSentinelCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sensors = [
        const AdasSensorTelemetry(
          sensorId: 'front-camera-01',
          isFrontCamera: true,
          yawAngleDeviationDegrees: 0.2,
          pitchAngleDeviationDegrees: 0.1,
          opticalTransmissionPercent: 98.0,
          targetTrackingDiscrepancies: 0,
        ),
      ];

      final result = service.evaluateAdasAlignment(
        vehicleId: 'TRK-SAFETY-01',
        sensors: sensors,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdasCalibrationSentinelCard(
                result: result,
                onRecalibrateSensors: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AdasCalibrationSentinelCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
