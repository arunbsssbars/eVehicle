import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/common_rail_pressure_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/common_rail_pressure_card.dart';

void main() {
  group('Loop 123: CommonRailPressureAuditorService & Card Tests', () {
    const service = CommonRailPressureAuditorService();

    test('Precise common rail tracking with low oscillation reports nominal status', () {
      const telemetry = CommonRailPressureTelemetry(
        measuredRailPressureBar: 1805.0,
        targetRailPressureBar: 1800.0,
        railPressureReliefValvePopCount: 0.0,
        fuelMeteringUnitCurrentMilliamps: 1420.0,
        railPressureOscillationBar: 18.0,
        fuelRailTemperatureCelsius: 65.0,
      );

      final result = service.auditFuelRail(
        vehicleId: 'DIESEL-HPFP-123-OK',
        telemetry: telemetry,
      );

      expect(result.status, CommonRailPressureStatus.railPressureNominal);
      expect(result.isRailPressureStable, isTrue);
      expect(result.isCriticalRailFailure, isFalse);
      expect(result.deltaBar, closeTo(5.0, 0.5));
      expect(result.diagnosticAdvisory, contains('NOMINAL'));
    });

    test('Elevated rail oscillation or tracking error triggers HPFP wear warning', () {
      const telemetry = CommonRailPressureTelemetry(
        measuredRailPressureBar: 1960.0,
        targetRailPressureBar: 1820.0,
        railPressureReliefValvePopCount: 0.0,
        fuelMeteringUnitCurrentMilliamps: 1680.0,
        railPressureOscillationBar: 65.0,
        fuelRailTemperatureCelsius: 82.0,
      );

      final result = service.auditFuelRail(
        vehicleId: 'DIESEL-HPFP-123-WARN',
        telemetry: telemetry,
      );

      expect(result.status, CommonRailPressureStatus.highPressurePumpWearWarning);
      expect(result.isRailPressureStable, isFalse);
      expect(result.deltaBar, closeTo(140.0, 0.5));
      expect(result.diagnosticAdvisory, contains('WARNING: Fuel rail pressure ripple'));
    });

    test('PRV valve pop or extreme delta (>250 bar) triggers critical limp hazard', () {
      const telemetry = CommonRailPressureTelemetry(
        measuredRailPressureBar: 2350.0,
        targetRailPressureBar: 1800.0,
        railPressureReliefValvePopCount: 2.0,
        fuelMeteringUnitCurrentMilliamps: 1950.0,
        railPressureOscillationBar: 110.0,
        fuelRailTemperatureCelsius: 102.0,
      );

      final result = service.auditFuelRail(
        vehicleId: 'DIESEL-HPFP-123-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, CommonRailPressureStatus.criticalPrvLimpOrRailBlowoutRisk);
      expect(result.isCriticalRailFailure, isTrue);
      expect(result.prvPops, 2.0);
      expect(result.diagnosticAdvisory, contains('CRITICAL HAZARD'));
    });

    testWidgets('CommonRailPressureCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool hpfpScheduled = false;
      const telemetry = CommonRailPressureTelemetry(
        measuredRailPressureBar: 2000.0,
        targetRailPressureBar: 1850.0,
        railPressureReliefValvePopCount: 0.0,
        fuelMeteringUnitCurrentMilliamps: 1700.0,
        railPressureOscillationBar: 68.0,
        fuelRailTemperatureCelsius: 85.0,
      );

      final result = service.auditFuelRail(
        vehicleId: 'COMMERCIAL-CUMMINS-15',
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
                child: CommonRailPressureCard(
                  result: result,
                  onScheduleHpfpInspection: () {
                    hpfpScheduled = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Diesel Common-Rail Sentry'), findsOneWidget);
      expect(find.textContaining('COMMERCIAL-CUMMINS-15'), findsOneWidget);
      expect(find.text('HPFP RIPPLE'), findsOneWidget);

      final scheduleBtn = find.text('Schedule Common-Rail HPFP Diagnostic');
      expect(scheduleBtn, findsOneWidget);
      await tester.tap(scheduleBtn);
      expect(hpfpScheduled, isTrue);
    });
  });
}
