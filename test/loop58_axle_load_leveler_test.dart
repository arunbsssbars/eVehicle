import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/axle_load_leveler_service.dart';
import 'package:evehicle_logbook/core/widgets/axle_load_leveler_card.dart';

void main() {
  group('Loop 58 - Axle Load Balance & ECAS Leveler Tests', () {
    const service = AxleLoadLevelerService();

    test('evaluateSuspension reports optimal balance for compliant axle pressures', () {
      const telemetry = EcasSuspensionTelemetry(
        steerAxleKg: 5800.0,
        driveBellowsPressureBar: 4.2, // ~10,080 kg (well under 11,500 kg limit)
        trailerBellowsPressureBar: 6.8, // ~21,760 kg (under 24,000 kg limit)
        suspensionRideHeightOffsetMm: 0.0,
        fifthWheelSlideNotch: 5,
        loadingDockModeActive: false,
      );

      final audit = service.evaluateSuspension(telemetry);
      expect(audit.status, SuspensionBalanceStatus.balancedOptimal);
      expect(audit.rebalancingRequired, isFalse);
      expect(audit.recommendedSlideAdjustmentNotches, 0);
    });

    test('evaluateSuspension detects overweight drive axle and recommends rearward slide', () {
      const telemetry = EcasSuspensionTelemetry(
        steerAxleKg: 6000.0,
        driveBellowsPressureBar: 5.2, // ~12,480 kg (exceeds 11,500 kg limit by ~980 kg)
        trailerBellowsPressureBar: 5.5,
        suspensionRideHeightOffsetMm: 0.0,
        fifthWheelSlideNotch: 6,
        loadingDockModeActive: false,
      );

      final audit = service.evaluateSuspension(telemetry);
      expect(audit.status, SuspensionBalanceStatus.driveAxleOverloaded);
      expect(audit.rebalancingRequired, isTrue);
      expect(audit.recommendedSlideAdjustmentNotches, lessThan(0)); // Negative = slide back
    });

    test('evaluateSuspension activates dock leveling mode without trigger rebalance alerts', () {
      const telemetry = EcasSuspensionTelemetry(
        steerAxleKg: 5500.0,
        driveBellowsPressureBar: 4.0,
        trailerBellowsPressureBar: 6.0,
        suspensionRideHeightOffsetMm: 65.0, // Raised for loading dock ramp
        fifthWheelSlideNotch: 5,
        loadingDockModeActive: true,
      );

      final audit = service.evaluateSuspension(telemetry);
      expect(audit.status, SuspensionBalanceStatus.dockLevelingActive);
      expect(audit.rebalancingRequired, isFalse);
    });

    testWidgets('AxleLoadLevelerCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = AxleBalanceAudit(
        status: SuspensionBalanceStatus.driveAxleOverloaded,
        estimatedDriveAxleKg: 12480.0,
        estimatedTrailerAxleKg: 18500.0,
        recommendedSlideAdjustmentNotches: -3,
        statusSummary: 'DRIVE AXLE OVERWEIGHT: Slide fifth wheel -3 notches rearward.',
        rebalancingRequired: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AxleLoadLevelerCard(
              audit: audit,
              currentSlideNotch: 6,
              onAdjustSlide: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Axle Load & 5th-Wheel Leveler'), findsOneWidget);
      expect(find.text('DRIVE OVERWEIGHT'), findsOneWidget);
      expect(find.text('Slide 5th Wheel -3 Notches'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AxleLoadLevelerCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = AxleBalanceAudit(
        status: SuspensionBalanceStatus.balancedOptimal,
        estimatedDriveAxleKg: 10200.0,
        estimatedTrailerAxleKg: 21000.0,
        recommendedSlideAdjustmentNotches: 0,
        statusSummary: 'SUSPENSION BALANCED: Within statutory bridge limits.',
        rebalancingRequired: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: AxleLoadLevelerCard(
                audit: audit,
                currentSlideNotch: 5,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BALANCED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
