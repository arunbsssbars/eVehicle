import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/coolant_electrolyte_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/coolant_electrolyte_card.dart';

void main() {
  group('Loop 111: Commercial Engine Coolant Chemistry & Electrolysis Sentinel Tests', () {
    const service = CoolantElectrolyteAuditorService();

    test('50/50 ethylene glycol mix with alkaline pH reports safe status', () {
      const telemetry = CoolantChemistryTelemetry(
        ethyleneGlycolConcentrationPercent: 50.0,
        coolantPh: 9.2,
        strayElectricalVoltageMilliVolts: 80.0,
        nitriteSilicateCorrosionInhibitorPpm: 1500.0,
        coolantTemperatureCelsius: 88.0,
      );

      final result = service.auditCoolantChemistry(
        vehicleId: 'ENG-COOL-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(CoolantElectrolyteStatus.balancedFreezeAndCorrosionProtection));
      expect(result.isElectrolyteBalanced, isTrue);
      expect(result.isCorrosiveElectrolysisActive, isFalse);
      expect(result.freezeProtectionCelsius, lessThanOrEqualTo(-35.0));
      expect(result.maintenanceDirective, contains('NOMINAL'));
    });

    test('Acidic coolant and high stray ground voltage flags severe electrolysis corrosion alert', () {
      const telemetry = CoolantChemistryTelemetry(
        ethyleneGlycolConcentrationPercent: 42.0,
        coolantPh: 6.8, // Acidic degradation
        strayElectricalVoltageMilliVolts: 450.0, // Severe electrical current through coolant
        nitriteSilicateCorrosionInhibitorPpm: 300.0,
        coolantTemperatureCelsius: 95.0,
      );

      final result = service.auditCoolantChemistry(
        vehicleId: 'ENG-COOL-02',
        telemetry: telemetry,
      );

      expect(result.status, equals(CoolantElectrolyteStatus.acidicElectrolysisCorrosionWarning));
      expect(result.isElectrolyteBalanced, isFalse);
      expect(result.isCorrosiveElectrolysisActive, isTrue);
      expect(result.maintenanceDirective, contains('ELECTROLYSIS ALERT'));
    });

    testWidgets('AQIL: CoolantElectrolyteCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = CoolantChemistryTelemetry(
        ethyleneGlycolConcentrationPercent: 48.0,
        coolantPh: 8.8,
        strayElectricalVoltageMilliVolts: 90.0,
        nitriteSilicateCorrosionInhibitorPpm: 1400.0,
        coolantTemperatureCelsius: 85.0,
      );
      final result = service.auditCoolantChemistry(vehicleId: 'COOL-320', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CoolantElectrolyteCard(result: result),
            ),
          ),
        ),
      );

      expect(find.text('Coolant Electrolyte Sentry'), findsOneWidget);
      expect(find.text('CHEMISTRY SAFE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AQIL: CoolantElectrolyteCard scales gracefully under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = CoolantChemistryTelemetry(
        ethyleneGlycolConcentrationPercent: 30.0,
        coolantPh: 6.9,
        strayElectricalVoltageMilliVolts: 400.0,
        nitriteSilicateCorrosionInhibitorPpm: 400.0,
        coolantTemperatureCelsius: 90.0,
      );
      final result = service.auditCoolantChemistry(vehicleId: 'COOL-FONT', telemetry: telemetry);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: CoolantElectrolyteCard(result: result),
              ),
            ),
          ),
        ),
      );

      expect(find.text('ELECTROLYSIS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
