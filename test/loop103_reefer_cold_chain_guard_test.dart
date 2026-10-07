import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/reefer_cold_chain_guard_service.dart';
import 'package:evehicle_logbook/core/widgets/reefer_cold_chain_card.dart';

void main() {
  group('Loop 103: Refrigerated Fleet Cold Chain & Compressor Sentinel Tests', () {
    const service = ReeferColdChainGuardService();

    test('Compliant cargo bay temperature within setpoint bounds passes inspection', () {
      const telemetry = ReeferCargoTelemetry(
        cargoClass: CargoThermalClass.chilledDairyProduce,
        setpointTemperatureCelsius: 3.0,
        supplyAirTemperatureCelsius: 2.1,
        returnAirTemperatureCelsius: 3.4,
        ambientOutsideTemperatureCelsius: 32.0,
        cycleState: ReeferCycleState.temperatureHolding,
        compressorDischargePressurePsi: 240.0,
        isDoorMicroswitchClosed: true,
      );

      final result = service.evaluateColdChain(
        vehicleId: 'RFR-DAIRY-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(ReeferHealthStatus.coldChainCompliant));
      expect(result.isCompliant, isTrue);
      expect(result.isCritical, isFalse);
      expect(result.coldChainComplianceScorePercent, equals(100.0));
      expect(result.complianceNotice, contains('NOMINAL'));
    });

    test('Thermal excursion exceeding 4.5 degrees or open doors triggers critical spoilage alarm', () {
      const telemetry = ReeferCargoTelemetry(
        cargoClass: CargoThermalClass.deepFrozenMeatFish,
        setpointTemperatureCelsius: -20.0,
        supplyAirTemperatureCelsius: -10.0,
        returnAirTemperatureCelsius: -12.0, // +8.0°C excursion
        ambientOutsideTemperatureCelsius: 38.0,
        cycleState: ReeferCycleState.coolingPullDown,
        compressorDischargePressurePsi: 420.0, // High discharge overpressure
        isDoorMicroswitchClosed: false, // Door left unsealed
      );

      final result = service.evaluateColdChain(
        vehicleId: 'RFR-MEAT-02',
        telemetry: telemetry,
      );

      expect(result.status, equals(ReeferHealthStatus.criticalThermalSpoilageRisk));
      expect(result.isCompliant, isFalse);
      expect(result.isCritical, isTrue);
      expect(result.complianceNotice, contains('CRITICAL'));
    });

    testWidgets('AQIL: ReeferColdChainCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = ReeferCargoTelemetry(
        cargoClass: CargoThermalClass.chilledDairyProduce,
        setpointTemperatureCelsius: 4.0,
        supplyAirTemperatureCelsius: 3.5,
        returnAirTemperatureCelsius: 4.2,
        ambientOutsideTemperatureCelsius: 28.0,
        cycleState: ReeferCycleState.temperatureHolding,
        compressorDischargePressurePsi: 220.0,
        isDoorMicroswitchClosed: true,
      );
      final result = service.evaluateColdChain(vehicleId: 'RFR-320', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReeferColdChainCard(result: result),
            ),
          ),
        ),
      );

      expect(find.text('Reefer Cold Chain Sentry'), findsOneWidget);
      expect(find.text('COLD CHAIN OK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AQIL: ReeferColdChainCard scales gracefully under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = ReeferCargoTelemetry(
        cargoClass: CargoThermalClass.deepFrozenMeatFish,
        setpointTemperatureCelsius: -18.0,
        supplyAirTemperatureCelsius: -8.0,
        returnAirTemperatureCelsius: -10.0,
        ambientOutsideTemperatureCelsius: 35.0,
        cycleState: ReeferCycleState.coolingPullDown,
        compressorDischargePressurePsi: 410.0,
        isDoorMicroswitchClosed: false,
      );
      final result = service.evaluateColdChain(vehicleId: 'RFR-FONT', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: ReeferColdChainCard(result: result),
              ),
            ),
          ),
        ),
      );

      expect(find.text('SPOILAGE RISK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
