import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/multi_zone_reefer_service.dart';
import 'package:evehicle_logbook/core/widgets/multi_zone_reefer_card.dart';

void main() {
  group('Loop 53 - Multi-Zone Reefer & Defrost Tests', () {
    const service = MultiZoneReeferService();

    test('evaluateReefer reports stable status when all zone temperatures are within tolerance', () {
      const telemetry = MultiZoneReeferTelemetry(
        zones: [
          ReeferZoneReading(zoneName: 'Z1 Frozen', currentTempCelsius: -20.2, setpointTempCelsius: -20.0),
          ReeferZoneReading(zoneName: 'Z2 Chilled', currentTempCelsius: 3.5, setpointTempCelsius: 4.0),
          ReeferZoneReading(zoneName: 'Z3 Ambient', currentTempCelsius: 18.0, setpointTempCelsius: 18.0),
        ],
        evaporatorFrostThicknessMm: 1.2,
        compressorHoursSinceLastDefrost: 3,
        engineFuelBurnLitersPerHour: 1.8,
      );

      final audit = service.evaluateReefer(telemetry);
      expect(audit.mode, ReeferOperatingMode.setpointSatisfied);
      expect(audit.violatedZoneCount, 0);
      expect(audit.hotGasDefrostNeeded, isFalse);
      expect(audit.requiresEmergencyInspection, isFalse);
    });

    test('evaluateReefer triggers temperature deviation alarm on breached setpoint', () {
      const telemetry = MultiZoneReeferTelemetry(
        zones: [
          ReeferZoneReading(zoneName: 'Z1 Frozen', currentTempCelsius: -14.0, setpointTempCelsius: -20.0), // Violated
          ReeferZoneReading(zoneName: 'Z2 Chilled', currentTempCelsius: 3.8, setpointTempCelsius: 4.0),
          ReeferZoneReading(zoneName: 'Z3 Ambient', currentTempCelsius: 18.2, setpointTempCelsius: 18.0),
        ],
        evaporatorFrostThicknessMm: 1.5,
        compressorHoursSinceLastDefrost: 4,
        engineFuelBurnLitersPerHour: 2.2,
      );

      final audit = service.evaluateReefer(telemetry);
      expect(audit.mode, ReeferOperatingMode.temperatureDeviationAlarm);
      expect(audit.violatedZoneCount, 1);
      expect(audit.requiresEmergencyInspection, isTrue);
    });

    test('evaluateReefer triggers hot-gas defrost when coil frost exceeds 3.5 mm', () {
      const telemetry = MultiZoneReeferTelemetry(
        zones: [
          ReeferZoneReading(zoneName: 'Z1 Frozen', currentTempCelsius: -19.8, setpointTempCelsius: -20.0),
          ReeferZoneReading(zoneName: 'Z2 Chilled', currentTempCelsius: 4.1, setpointTempCelsius: 4.0),
        ],
        evaporatorFrostThicknessMm: 4.2, // Heavy ice blanket
        compressorHoursSinceLastDefrost: 7,
        engineFuelBurnLitersPerHour: 2.5,
      );

      final audit = service.evaluateReefer(telemetry);
      expect(audit.mode, ReeferOperatingMode.defrostCycleActive);
      expect(audit.hotGasDefrostNeeded, isTrue);
    });

    testWidgets('MultiZoneReeferCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = MultiZoneReeferAudit(
        mode: ReeferOperatingMode.defrostCycleActive,
        hotGasDefrostNeeded: true,
        violatedZoneCount: 0,
        statusSummary: 'HOT-GAS DEFROST REQUIRED: Coil frost thickness at 4.2 mm.',
        requiresEmergencyInspection: false,
      );

      const testZones = [
        ReeferZoneReading(zoneName: 'Frozen', currentTempCelsius: -19.5, setpointTempCelsius: -20.0),
        ReeferZoneReading(zoneName: 'Chilled', currentTempCelsius: 3.8, setpointTempCelsius: 4.0),
        ReeferZoneReading(zoneName: 'Pharma', currentTempCelsius: 18.0, setpointTempCelsius: 18.0),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiZoneReeferCard(
              audit: audit,
              zones: testZones,
              onTriggerDefrost: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Multi-Zone Cold-Chain Reefer'), findsOneWidget);
      expect(find.text('DEFROST'), findsOneWidget);
      expect(find.text('Execute Hot-Gas Defrost Cycle'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MultiZoneReeferCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = MultiZoneReeferAudit(
        mode: ReeferOperatingMode.setpointSatisfied,
        hotGasDefrostNeeded: false,
        violatedZoneCount: 0,
        statusSummary: 'ALL ZONES OPTIMAL: Multi-compartment temperatures locked within setpoints.',
        requiresEmergencyInspection: false,
      );

      const testZones = [
        ReeferZoneReading(zoneName: 'Frozen', currentTempCelsius: -20.0, setpointTempCelsius: -20.0),
        ReeferZoneReading(zoneName: 'Chilled', currentTempCelsius: 4.0, setpointTempCelsius: 4.0),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: MultiZoneReeferCard(
                audit: audit,
                zones: testZones,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STABLE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
