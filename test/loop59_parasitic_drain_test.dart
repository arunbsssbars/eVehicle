import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/parasitic_drain_service.dart';
import 'package:evehicle_logbook/core/widgets/parasitic_drain_card.dart';

void main() {
  group('Loop 59 - Parasitic Battery Drain & Alternator Tests', () {
    const service = ParasiticDrainService();

    test('evaluateElectricalHealth verifies healthy resting state with low quiescent draw', () {
      const sample = ElectricalTelemetrySample(
        starterBatteryVoltage: 12.6,
        keyOffParasiticDrainMilliAmps: 35.0, // Normal telematic sleep draw
        primaryAlternatorAmps: 0.0,
        secondaryAlternatorAmps: 0.0,
        engineRunning: false,
        consecutiveParkedHours: 12,
      );

      final audit = service.evaluateElectricalHealth(sample);
      expect(audit.status, ElectricalHealthStatus.normalHoldingCharge);
      expect(audit.isolationRelayTripRecommended, isFalse);
      expect(audit.estimatedStateOfChargePercent, greaterThan(80.0));
      expect(audit.estimatedHoursUntilNoStart, greaterThan(100));
    });

    test('evaluateElectricalHealth detects excessive vampire draw threatening battery', () {
      const sample = ElectricalTelemetrySample(
        starterBatteryVoltage: 12.3,
        keyOffParasiticDrainMilliAmps: 680.0, // Severe parasite load (aux light/inverter stuck on)
        primaryAlternatorAmps: 0.0,
        secondaryAlternatorAmps: 0.0,
        engineRunning: false,
        consecutiveParkedHours: 8,
      );

      final audit = service.evaluateElectricalHealth(sample);
      expect(audit.status, ElectricalHealthStatus.parasiticDrainExcessive);
      expect(audit.estimatedHoursUntilNoStart, lessThan(40));
    });

    test('evaluateElectricalHealth flags critical starting risk on depleted battery', () {
      const sample = ElectricalTelemetrySample(
        starterBatteryVoltage: 11.7, // Severely discharged
        keyOffParasiticDrainMilliAmps: 200.0,
        primaryAlternatorAmps: 0.0,
        secondaryAlternatorAmps: 0.0,
        engineRunning: false,
        consecutiveParkedHours: 48,
      );

      final audit = service.evaluateElectricalHealth(sample);
      expect(audit.status, ElectricalHealthStatus.criticalStartingRisk);
      expect(audit.isolationRelayTripRecommended, isTrue);
    });

    testWidgets('ParasiticDrainCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = ElectricalHealthAudit(
        status: ElectricalHealthStatus.criticalStartingRisk,
        estimatedStateOfChargePercent: 12.0,
        estimatedHoursUntilNoStart: 6,
        statusSummary: 'CRITICAL BATTERY DEPLETION: Cranking failure imminent!',
        isolationRelayTripRecommended: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParasiticDrainCard(
              audit: audit,
              currentVoltage: 11.7,
              quiescentDrawMilliAmps: 450.0,
              onTripDisconnectRelay: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parasitic Drain & Battery Health'), findsOneWidget);
      expect(find.text('DEAD RISK'), findsOneWidget);
      expect(find.text('Trip Low-Voltage Disconnect Relay'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ParasiticDrainCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = ElectricalHealthAudit(
        status: ElectricalHealthStatus.normalHoldingCharge,
        estimatedStateOfChargePercent: 95.0,
        estimatedHoursUntilNoStart: 320,
        statusSummary: 'ELECTRICAL SYSTEM HEALTHY.',
        isolationRelayTripRecommended: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: ParasiticDrainCard(
                audit: audit,
                currentVoltage: 12.6,
                quiescentDrawMilliAmps: 35.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CHARGED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
