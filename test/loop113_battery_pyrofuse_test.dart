import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/battery_pyrofuse_venting_service.dart';
import 'package:evehicle_logbook/core/widgets/battery_pyrofuse_venting_card.dart';

void main() {
  group('Loop 113: BatteryPyrofuseVentingService & Card Tests', () {
    const service = BatteryPyrofuseVentingService();

    test('Evaluating normal pack parameters confirms sealed and intact status', () {
      const telemetry = BatteryThermalSafetyTelemetry(
        packInternalPressureKPa: 101.3,
        ventGasHydrogenPpm: 25.0,
        carbonMonoxidePpm: 12.0,
        maxCellTemperatureCelsius: 32.5,
        cellTemperatureRiseRateCPerSec: 0.05,
        isPyrofuseCircuitLoopClosed: true,
        packCurrentAmperes: 120.0,
      );

      final result = service.evaluateSafety(
        vehicleId: 'EV-BAT-113-OK',
        telemetry: telemetry,
      );

      expect(result.status, PyrofuseVentingStatus.sealedAndIntact);
      expect(result.isSafeToOperate, isTrue);
      expect(result.isEvacuationMandatory, isFalse);
      expect(result.isHighVoltageSevered, isFalse);
      expect(result.safetyAdvisory, contains('NOMINAL'));
    });

    test('Elevated pressure or off-gassing triggers pressure warning venting status', () {
      const telemetry = BatteryThermalSafetyTelemetry(
        packInternalPressureKPa: 122.5,
        ventGasHydrogenPpm: 410.0,
        carbonMonoxidePpm: 180.0,
        maxCellTemperatureCelsius: 58.0,
        cellTemperatureRiseRateCPerSec: 0.6,
        isPyrofuseCircuitLoopClosed: true,
        packCurrentAmperes: 350.0,
      );

      final result = service.evaluateSafety(
        vehicleId: 'EV-BAT-113-WARN',
        telemetry: telemetry,
      );

      expect(result.status, PyrofuseVentingStatus.pressureWarningVentingInitiated);
      expect(result.isSafeToOperate, isFalse);
      expect(result.isHighVoltageSevered, isFalse);
      expect(result.safetyAdvisory, contains('WARNING: Cell electrolyte venting'));
    });

    test('Detonated pyrofuse or runaway propagation triggers emergency isolation', () {
      const telemetry = BatteryThermalSafetyTelemetry(
        packInternalPressureKPa: 148.0,
        ventGasHydrogenPpm: 1200.0,
        carbonMonoxidePpm: 600.0,
        maxCellTemperatureCelsius: 82.0,
        cellTemperatureRiseRateCPerSec: 2.4,
        isPyrofuseCircuitLoopClosed: false,
        packCurrentAmperes: 2400.0,
      );

      final result = service.evaluateSafety(
        vehicleId: 'EV-BAT-113-EMERGENCY',
        telemetry: telemetry,
      );

      expect(result.status, PyrofuseVentingStatus.emergencyPyrofuseDetonated);
      expect(result.isEvacuationMandatory, isTrue);
      expect(result.isHighVoltageSevered, isTrue);
      expect(result.safetyAdvisory, contains('CRITICAL EMERGENCY'));
    });

    testWidgets('BatteryPyrofuseVentingCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool emergencyTriggered = false;
      const telemetry = BatteryThermalSafetyTelemetry(
        packInternalPressureKPa: 145.0,
        ventGasHydrogenPpm: 950.0,
        carbonMonoxidePpm: 450.0,
        maxCellTemperatureCelsius: 80.0,
        cellTemperatureRiseRateCPerSec: 1.8,
        isPyrofuseCircuitLoopClosed: false,
        packCurrentAmperes: 2100.0,
      );

      final result = service.evaluateSafety(
        vehicleId: 'SEMI-EV-PACK-01',
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
                child: BatteryPyrofuseVentingCard(
                  result: result,
                  onTriggerEmergencyDisconnect: () {
                    emergencyTriggered = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('EV Battery Thermal Runaway Sentry'), findsOneWidget);
      expect(find.textContaining('SEMI-EV-PACK-01'), findsOneWidget);
      expect(find.text('PYROFUSE DETONATED'), findsOneWidget);

      final emergencyBtn = find.text('Initiate Pyrofuse High-Voltage Disconnect');
      expect(emergencyBtn, findsOneWidget);
      await tester.tap(emergencyBtn);
      expect(emergencyTriggered, isTrue);
    });
  });
}
