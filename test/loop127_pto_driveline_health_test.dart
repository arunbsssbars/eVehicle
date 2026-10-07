import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/pto_driveline_health_service.dart';
import 'package:evehicle_logbook/core/widgets/pto_driveline_health_card.dart';

void main() {
  group('Loop 127: PtoDrivelineHealthService & Card Tests', () {
    const service = PtoDrivelineHealthService();

    test('Normal PTO torque and solid clutch lockup reports nominal status', () {
      const telemetry = PtoDrivelineTelemetry(
        ptoOutputShaftRpm: 980.0,
        engineSpeedRpm: 1800.0,
        measuredTorqueNewtonMetres: 650.0,
        ratedTorqueLimitNewtonMetres: 1200.0,
        ptoClutchSumpTemperatureCelsius: 72.0,
        engagementHydraulicPressureKPa: 1950.0,
        continuousOperatingHours: 4.5,
      );

      final result = service.auditPtoDriveline(
        vehicleId: 'CRANE-PTO-127-OK',
        telemetry: telemetry,
      );

      expect(result.status, PtoDrivelineHealthStatus.ptoOperatingNominal);
      expect(result.isPtoRunningClean, isTrue);
      expect(result.isShaftShearImminent, isFalse);
      expect(result.loadRatioPercent, closeTo(54.2, 0.5));
      expect(result.operationalAdvisory, contains('NOMINAL'));
    });

    test('Torque overload (>105%) or hot clutch sump triggers thermal warning', () {
      const telemetry = PtoDrivelineTelemetry(
        ptoOutputShaftRpm: 920.0,
        engineSpeedRpm: 1800.0,
        measuredTorqueNewtonMetres: 1350.0,
        ratedTorqueLimitNewtonMetres: 1200.0,
        ptoClutchSumpTemperatureCelsius: 104.0,
        engagementHydraulicPressureKPa: 1350.0,
        continuousOperatingHours: 8.0,
      );

      final result = service.auditPtoDriveline(
        vehicleId: 'CRANE-PTO-127-WARN',
        telemetry: telemetry,
      );

      expect(result.status, PtoDrivelineHealthStatus.thermalOverloadWarning);
      expect(result.isPtoRunningClean, isFalse);
      expect(result.operationalAdvisory, contains('WARNING: PTO wet clutch thermal stress'));
    });

    test('Extreme torque spike (>=140%) or hydraulic collapse triggers critical shear hazard', () {
      const telemetry = PtoDrivelineTelemetry(
        ptoOutputShaftRpm: 680.0,
        engineSpeedRpm: 1800.0,
        measuredTorqueNewtonMetres: 1780.0,
        ratedTorqueLimitNewtonMetres: 1200.0,
        ptoClutchSumpTemperatureCelsius: 125.0,
        engagementHydraulicPressureKPa: 950.0,
        continuousOperatingHours: 12.0,
      );

      final result = service.auditPtoDriveline(
        vehicleId: 'CRANE-PTO-127-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, PtoDrivelineHealthStatus.criticalSplineShearAndOverTorqueHazard);
      expect(result.isShaftShearImminent, isTrue);
      expect(result.operationalAdvisory, contains('CRITICAL OVERLOAD: PTO torque surge'));
    });

    testWidgets('PtoDrivelineHealthCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool ptoDisengaged = false;
      const telemetry = PtoDrivelineTelemetry(
        ptoOutputShaftRpm: 620.0,
        engineSpeedRpm: 1800.0,
        measuredTorqueNewtonMetres: 1800.0,
        ratedTorqueLimitNewtonMetres: 1200.0,
        ptoClutchSumpTemperatureCelsius: 122.0,
        engagementHydraulicPressureKPa: 900.0,
        continuousOperatingHours: 10.0,
      );

      final result = service.auditPtoDriveline(
        vehicleId: 'TIPPER-PUMP-40',
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
                child: PtoDrivelineHealthCard(
                  result: result,
                  onDisengagePtoDrive: () {
                    ptoDisengaged = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Power Takeoff (PTO) Sentry'), findsOneWidget);
      expect(find.textContaining('TIPPER-PUMP-40'), findsOneWidget);
      expect(find.text('SPLINE SHEAR RISK'), findsOneWidget);

      final disengageBtn = find.text('Disengage PTO Auxiliary Driveline');
      expect(disengageBtn, findsOneWidget);
      await tester.tap(disengageBtn);
      expect(ptoDisengaged, isTrue);
    });
  });
}
