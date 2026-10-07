import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/transmission_slip_diagnoser_service.dart';
import 'package:evehicle_logbook/core/widgets/transmission_slip_diagnoser_card.dart';

void main() {
  group('Loop 87: Transmission Slip & Torque Converter Health Diagnoser Tests', () {
    const service = TransmissionSlipDiagnoserService();

    test('Locked clutch with low slip RPM reports healthy status', () {
      final readings = [
        const TransmissionClutchReading(
          engineSpeedRpm: 1500.0,
          transmissionInputShaftRpm: 1495.0, // 5 RPM slip (normal)
          transmissionOutputShaftRpm: 450.0,
          currentGear: 8,
          clutchEngagementPercent: 100.0,
          transmissionFluidTempCelsius: 82.0,
          shiftEngagementLatencyMs: 320.0,
        ),
      ];

      final result = service.evaluateTransmission(
        vehicleId: 'TRK-ZF-12',
        readings: readings,
      );

      expect(result.status, equals(TransmissionHealthStatus.healthy));
      expect(result.maxSlipRpm, equals(5.0));
      expect(result.isImmediateServiceRequired, isFalse);
      expect(result.hasThermalFluidDegradation, isFalse);
    });

    test('Excessive clutch slip RPM triggers critical transmission warning', () {
      final readings = [
        const TransmissionClutchReading(
          engineSpeedRpm: 1800.0,
          transmissionInputShaftRpm: 1550.0, // 250 RPM slip (> 180 threshold)
          transmissionOutputShaftRpm: 400.0,
          currentGear: 5,
          clutchEngagementPercent: 100.0,
          transmissionFluidTempCelsius: 120.0, // Fluid overheat
          shiftEngagementLatencyMs: 750.0,
        ),
      ];

      final result = service.evaluateTransmission(
        vehicleId: 'TRK-ZF-12',
        readings: readings,
      );

      expect(result.status, equals(TransmissionHealthStatus.severeClutchSlipCritical));
      expect(result.isImmediateServiceRequired, isTrue);
      expect(result.hasThermalFluidDegradation, isTrue);
      expect(result.diagnosticRecommendation, contains('CRITICAL: Severe clutch slippage'));
    });

    testWidgets('AQIL: TransmissionSlipDiagnoserCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final readings = [
        const TransmissionClutchReading(
          engineSpeedRpm: 1500.0,
          transmissionInputShaftRpm: 1495.0,
          transmissionOutputShaftRpm: 450.0,
          currentGear: 8,
          clutchEngagementPercent: 100.0,
          transmissionFluidTempCelsius: 82.0,
          shiftEngagementLatencyMs: 320.0,
        ),
      ];

      final result = service.evaluateTransmission(
        vehicleId: 'TRK-ZF-12',
        readings: readings,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TransmissionSlipDiagnoserCard(
                result: result,
                onScheduleTransmissionScan: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TransmissionSlipDiagnoserCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
