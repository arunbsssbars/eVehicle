import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/cng_cryogenic_service.dart';
import 'package:evehicle_logbook/core/widgets/cng_cryogenic_card.dart';

void main() {
  group('Loop 56 - CNG & Cryogenic LNG Pressure Tests', () {
    const service = CngCryogenicService();

    test('auditGasSafety reports normal operational status for safe pressure and zero leak', () {
      final sample = GasTankTelemetrySample(
        cylinderPressureBar: 195.0,
        maxRatedPressureBar: 250.0,
        tankTemperatureKelvin: 290.0,
        methaneDetectorPpm: 25.0,
        hydrostaticCertExpiry: DateTime.now().add(const Duration(days: 365)),
      );

      final audit = service.auditGasSafety(sample: sample);
      expect(audit.status, CngSystemStatus.normalOperational);
      expect(audit.boilOffVentingImminent, isFalse);
      expect(audit.requiresEmergencyVentOrShutoff, isFalse);
    });

    test('auditGasSafety triggers leak alarm on high methane concentration', () {
      final sample = GasTankTelemetrySample(
        cylinderPressureBar: 180.0,
        maxRatedPressureBar: 250.0,
        tankTemperatureKelvin: 290.0,
        methaneDetectorPpm: 2200.0, // High gas leak
        hydrostaticCertExpiry: DateTime.now().add(const Duration(days: 200)),
      );

      final audit = service.auditGasSafety(sample: sample);
      expect(audit.status, CngSystemStatus.methaneLeakAlarm);
      expect(audit.requiresEmergencyVentOrShutoff, isTrue);
    });

    test('auditGasSafety triggers overpressure venting warning at > 92% capacity', () {
      final sample = GasTankTelemetrySample(
        cylinderPressureBar: 240.0, // Near 250 bar limit
        maxRatedPressureBar: 250.0,
        tankTemperatureKelvin: 310.0,
        methaneDetectorPpm: 40.0,
        hydrostaticCertExpiry: DateTime.now().add(const Duration(days: 180)),
      );

      final audit = service.auditGasSafety(sample: sample);
      expect(audit.status, CngSystemStatus.ventingPressureWarning);
      expect(audit.boilOffVentingImminent, isTrue);
    });

    testWidgets('CngCryogenicCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = GasSystemSafetyAudit(
        status: CngSystemStatus.ventingPressureWarning,
        pressureFillPercent: 96.0,
        boilOffVentingImminent: true,
        daysUntilCertExpiry: 120,
        statusSummary: 'OVERPRESSURE WARNING: Tank at 96% rated pressure.',
        requiresEmergencyVentOrShutoff: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CngCryogenicCard(
              audit: audit,
              currentPressureBar: 240.0,
              onEmergencyVentAction: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CNG/LNG Pressure & BOG Guard'), findsOneWidget);
      expect(find.text('VENTING RISK'), findsOneWidget);
      expect(find.text('Trigger Emergency Solenoid Valve Shutoff'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CngCryogenicCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = GasSystemSafetyAudit(
        status: CngSystemStatus.normalOperational,
        pressureFillPercent: 78.0,
        boilOffVentingImminent: false,
        daysUntilCertExpiry: 290,
        statusSummary: 'GAS PRESSURE NORMAL.',
        requiresEmergencyVentOrShutoff: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: CngCryogenicCard(
                audit: audit,
                currentPressureBar: 195.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PRESSURE OK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
