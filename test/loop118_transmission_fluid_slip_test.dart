import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/transmission_fluid_slip_service.dart';
import 'package:evehicle_logbook/core/widgets/transmission_fluid_slip_card.dart';

void main() {
  group('Loop 118: TransmissionFluidSlipService & Card Tests', () {
    const service = TransmissionFluidSlipService();

    test('Cool sump and minimal clutch slip reports optimal fluid status', () {
      const telemetry = TransmissionFluidTelemetry(
        transmissionSumpTemperatureCelsius: 82.0,
        clutchSlipRpmDelta: 22.0,
        fluidDielectricOxidationIndex: 2.3,
        linePressureKPa: 1450.0,
        shiftEngagementTimeSeconds: 0.55,
        operatingHoursOnFluid: 450.0,
      );

      final result = service.auditTransmission(
        vehicleId: 'TRUCK-TRANS-118-OK',
        telemetry: telemetry,
      );

      expect(result.status, TransmissionFluidSlipStatus.fluidOptimal);
      expect(result.isTransmissionHealthy, isTrue);
      expect(result.isClutchSlipFatalRisk, isFalse);
      expect(result.fluidLifePercent, greaterThan(70.0));
      expect(result.serviceAdvisory, contains('NOMINAL'));
    });

    test('Elevated temperature or delayed shift flare triggers thermal breakdown warning', () {
      const telemetry = TransmissionFluidTelemetry(
        transmissionSumpTemperatureCelsius: 112.0,
        clutchSlipRpmDelta: 88.0,
        fluidDielectricOxidationIndex: 3.9,
        linePressureKPa: 1150.0,
        shiftEngagementTimeSeconds: 1.15,
        operatingHoursOnFluid: 1650.0,
      );

      final result = service.auditTransmission(
        vehicleId: 'TRUCK-TRANS-118-WARN',
        telemetry: telemetry,
      );

      expect(result.status, TransmissionFluidSlipStatus.thermalBreakdownWarning);
      expect(result.isTransmissionHealthy, isFalse);
      expect(result.serviceAdvisory, contains('WARNING: Transmission fluid thermal stress'));
    });

    test('Extreme clutch slip (>160 RPM) or line pressure collapse triggers critical failure risk', () {
      const telemetry = TransmissionFluidTelemetry(
        transmissionSumpTemperatureCelsius: 128.0,
        clutchSlipRpmDelta: 195.0,
        fluidDielectricOxidationIndex: 4.8,
        linePressureKPa: 780.0,
        shiftEngagementTimeSeconds: 1.8,
        operatingHoursOnFluid: 2100.0,
      );

      final result = service.auditTransmission(
        vehicleId: 'TRUCK-TRANS-118-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, TransmissionFluidSlipStatus.criticalClutchPackSlipFailure);
      expect(result.isClutchSlipFatalRisk, isTrue);
      expect(result.serviceAdvisory, contains('CRITICAL HAZARD: Excessive clutch pack slip flare'));
    });

    testWidgets('TransmissionFluidSlipCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool serviceBooked = false;
      const telemetry = TransmissionFluidTelemetry(
        transmissionSumpTemperatureCelsius: 115.0,
        clutchSlipRpmDelta: 92.0,
        fluidDielectricOxidationIndex: 4.1,
        linePressureKPa: 1100.0,
        shiftEngagementTimeSeconds: 1.2,
        operatingHoursOnFluid: 1700.0,
      );

      final result = service.auditTransmission(
        vehicleId: 'HAUL-TRANS-99',
        telemetry: telemetry,
      );

      // Verify Compact 320px viewport with fontScale 1.5
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: TransmissionFluidSlipCard(
                  result: result,
                  onScheduleTransmissionFlush: () {
                    serviceBooked = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Transmission Fluid & Clutch Sentry'), findsOneWidget);
      expect(find.textContaining('HAUL-TRANS-99'), findsOneWidget);
      expect(find.text('THERMAL STRESS'), findsOneWidget);

      final bookBtn = find.text('Book Transmission Fluid & Cooler Service');
      expect(bookBtn, findsOneWidget);
      await tester.tap(bookBtn);
      expect(serviceBooked, isTrue);
    });
  });
}
