import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/axle_load_compliance_service.dart';
import 'package:evehicle_logbook/core/widgets/axle_load_compliance_card.dart';

void main() {
  group('Loop 76: Axle Load & Bridge Weight Limit Sentinel Tests', () {
    const service = AxleLoadComplianceService();

    test('Compliant 3-axle commercial vehicle satisfies GVWR and bridge limits', () {
      const config = AxleConfiguration(
        vehicleId: 'trk-001',
        registrationNumber: 'PB08-XX-9901',
        totalAxleCount: 3,
        wheelbaseMeters: 6.5,
        maxGvwrKg: 25000,
        axles: [
          AxleGroupWeight(type: AxleType.steerSingle, label: 'Front Steer Axle', measuredWeightKg: 5500, legalMaxWeightKg: 6000),
          AxleGroupWeight(type: AxleType.driveTandem, label: 'Center Drive Axle', measuredWeightKg: 9000, legalMaxWeightKg: 10000),
          AxleGroupWeight(type: AxleType.trailerTridem, label: 'Rear Drive Axle', measuredWeightKg: 9000, legalMaxWeightKg: 10000),
        ],
      );

      final audit = service.evaluateAxleLoads(config);

      expect(audit.isFullyCompliant, isTrue);
      expect(audit.totalGrossWeightKg, 23500.0);
      expect(audit.isGvwrCompliant, isTrue);
      expect(audit.isBridgeFormulaCompliant, isTrue);
      expect(audit.isAnyAxleOverloaded, isFalse);
      expect(audit.violationReasons.isEmpty, isTrue);
    });

    test('Overloaded rear axle triggers violation and calculates penalty', () {
      const config = AxleConfiguration(
        vehicleId: 'trk-002',
        registrationNumber: 'RJ14-TR-4455',
        totalAxleCount: 3,
        wheelbaseMeters: 5.5,
        maxGvwrKg: 25000,
        axles: [
          AxleGroupWeight(type: AxleType.steerSingle, label: 'Front Steer Axle', measuredWeightKg: 5800, legalMaxWeightKg: 6000),
          AxleGroupWeight(type: AxleType.driveTandem, label: 'Center Drive Axle', measuredWeightKg: 9500, legalMaxWeightKg: 10000),
          AxleGroupWeight(type: AxleType.trailerTridem, label: 'Rear Drive Axle', measuredWeightKg: 11500, legalMaxWeightKg: 10000), // +1500 kg overload
        ],
      );

      final audit = service.evaluateAxleLoads(config);

      expect(audit.isFullyCompliant, isFalse);
      expect(audit.isAnyAxleOverloaded, isTrue);
      expect(audit.totalGrossWeightKg, 26800.0); // Exceeds 25000 GVWR
      expect(audit.isGvwrCompliant, isFalse);
      expect(audit.overloadPenaltyEstimate > 0, isTrue);
      expect(audit.violationReasons.any((r) => r.contains('Rear Drive Axle overloaded')), isTrue);
    });
  });

  group('Loop 76: AQIL UI Multi-Viewport & Accessibility Tests', () {
    const service = AxleLoadComplianceService();

    const testConfig = AxleConfiguration(
      vehicleId: 'trk-test',
      registrationNumber: 'HR55-COMM-1020',
      totalAxleCount: 3,
      wheelbaseMeters: 6.0,
      maxGvwrKg: 26000,
      axles: [
        AxleGroupWeight(type: AxleType.steerSingle, label: 'Steer Axle', measuredWeightKg: 5800, legalMaxWeightKg: 6000),
        AxleGroupWeight(type: AxleType.driveTandem, label: 'Drive Axle', measuredWeightKg: 10500, legalMaxWeightKg: 10000),
      ],
    );

    final testAudit = service.evaluateAxleLoads(testConfig);

    testWidgets('AxleLoadComplianceCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AxleLoadComplianceCard(
                audit: testAudit,
                config: testConfig,
                onRecalibratePayload: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Axle Weight Sentinel'), findsOneWidget);
      expect(find.textContaining('Optimize Axle Payload Distribution'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AxleLoadComplianceCard maintains integrity under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: SingleChildScrollView(
                child: AxleLoadComplianceCard(
                  audit: testAudit,
                  config: testConfig,
                  onRecalibratePayload: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AxleLoadComplianceCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
