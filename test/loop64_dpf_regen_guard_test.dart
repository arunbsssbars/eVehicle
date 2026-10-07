import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/dpf_regen_guard_service.dart';
import 'package:evehicle_logbook/core/widgets/dpf_regen_guard_card.dart';

void main() {
  group('Loop 64 - DpfRegenGuardService Unit Tests', () {
    late DpfRegenGuardService service;

    setUp(() {
      service = const DpfRegenGuardService();
    });

    test('Clean DPF baseline operates in sootCleanNormal state', () {
      const telemetry = DpfExhaustTelemetry(
        differentialPressureMbar: 18.0,
        sootMassGrams: 8.5,
        exhaustGasTempCelsius: 280.0,
        vehicleSpeedKmh: 75.0,
        engineOperatingHoursSinceLastRegen: 12,
      );

      final audit = service.evaluateDpfHealth(telemetry);

      expect(audit.state, DpfRegenState.sootCleanNormal);
      expect(audit.sootCapacityPercentage, lessThan(30.0));
      expect(audit.parkedRegenRequired, isFalse);
      expect(audit.activeBurnPermitted, isFalse);
    });

    test('Passive soot burn occurs when exhaust temp exceeds 450C', () {
      const telemetry = DpfExhaustTelemetry(
        differentialPressureMbar: 35.0,
        sootMassGrams: 16.0,
        exhaustGasTempCelsius: 480.0,
        vehicleSpeedKmh: 90.0,
        engineOperatingHoursSinceLastRegen: 22,
      );

      final audit = service.evaluateDpfHealth(telemetry);

      expect(audit.state, DpfRegenState.passiveRegenUnderway);
      expect(audit.statusSummary, contains('PASSIVE BURNOFF ACTIVE'));
    });

    test('Active regen permitted when soot loading high and cruising at highway speed', () {
      const telemetry = DpfExhaustTelemetry(
        differentialPressureMbar: 92.0,
        sootMassGrams: 33.0,
        exhaustGasTempCelsius: 320.0,
        vehicleSpeedKmh: 72.0,
        engineOperatingHoursSinceLastRegen: 45,
      );

      final audit = service.evaluateDpfHealth(telemetry);

      expect(audit.state, DpfRegenState.activeRegenRequired);
      expect(audit.activeBurnPermitted, isTrue);
      expect(audit.parkedRegenRequired, isFalse);
    });

    test('Parked regen mandatory when soot reaches critical threshold (>90%)', () {
      const telemetry = DpfExhaustTelemetry(
        differentialPressureMbar: 155.0,
        sootMassGrams: 42.0,
        exhaustGasTempCelsius: 220.0,
        vehicleSpeedKmh: 35.0,
        engineOperatingHoursSinceLastRegen: 60,
      );

      final audit = service.evaluateDpfHealth(telemetry);

      expect(audit.state, DpfRegenState.parkedRegenMandatory);
      expect(audit.parkedRegenRequired, isTrue);
      expect(audit.statusSummary, contains('CRITICAL SOOT LOAD'));
    });

    test('Cracked or tampered substrate alarm when delta P near zero under highway speed', () {
      const telemetry = DpfExhaustTelemetry(
        differentialPressureMbar: 1.2,
        sootMassGrams: 0.0,
        exhaustGasTempCelsius: 340.0,
        vehicleSpeedKmh: 85.0,
        engineOperatingHoursSinceLastRegen: 5,
      );

      final audit = service.evaluateDpfHealth(telemetry);

      expect(audit.state, DpfRegenState.dpfCrackedFilterAlarm);
      expect(audit.statusSummary, contains('CRACKED / TAMPERED'));
    });
  });

  group('Loop 64 - DpfRegenGuardCard Widget & AQIL Tests', () {
    testWidgets('Renders properly in compact 320px viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const telemetry = DpfExhaustTelemetry(
        differentialPressureMbar: 145.0,
        sootMassGrams: 42.5,
        exhaustGasTempCelsius: 240.0,
        vehicleSpeedKmh: 20.0,
        engineOperatingHoursSinceLastRegen: 58,
      );
      const audit = DpfHealthAudit(
        state: DpfRegenState.parkedRegenMandatory,
        sootCapacityPercentage: 94.4,
        statusSummary: 'CRITICAL SOOT LOAD: Execute parked regeneration immediately.',
        parkedRegenRequired: true,
        activeBurnPermitted: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DpfRegenGuardCard(
                audit: audit,
                telemetry: telemetry,
                onTriggerParkedRegen: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DPF Aftertreatment Guard'), findsOneWidget);
      expect(find.text('PARKED REGEN REQ'), findsOneWidget);
      expect(find.text('Initiate Parked Regen Protocol'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Supports 1.5x dynamic text scale cleanly', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const telemetry = DpfExhaustTelemetry(
        differentialPressureMbar: 88.0,
        sootMassGrams: 32.0,
        exhaustGasTempCelsius: 310.0,
        vehicleSpeedKmh: 75.0,
        engineOperatingHoursSinceLastRegen: 40,
      );
      const audit = DpfHealthAudit(
        state: DpfRegenState.activeRegenRequired,
        sootCapacityPercentage: 71.1,
        statusSummary: 'ACTIVE REGENERATION PERMITTED: Cruising conditions optimal.',
        parkedRegenRequired: false,
        activeBurnPermitted: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: DpfRegenGuardCard(
                  audit: audit,
                  telemetry: telemetry,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE REGEN REQ'), findsOneWidget);
      expect(find.text('ACTIVE REGENERATION PERMITTED: Cruising conditions optimal.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
