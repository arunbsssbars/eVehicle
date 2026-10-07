import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/drawbar_coupling_fatigue_service.dart';
import 'package:evehicle_logbook/core/widgets/drawbar_coupling_fatigue_card.dart';

void main() {
  group('Loop 114: DrawbarCouplingFatigueService & Card Tests', () {
    const service = DrawbarCouplingFatigueService();

    test('Kingpin and drawbar within elastic limits reports safe haul status', () {
      const telemetry = DrawbarCouplingTelemetry(
        kingpinDiameterWearMm: 0.35,
        drawbarEyeletHoleOvalityMm: 0.4,
        dynamicTensileMicrostrain: 650.0,
        acousticEmissionCrackHits: 4.0,
        cumulativeTowingKilometers: 85000,
        grossTowedWeightTonnes: 32.0,
      );

      final result = service.auditCoupling(
        vehicleId: 'TRAILER-COUPLE-01',
        telemetry: telemetry,
      );

      expect(result.status, DrawbarCouplingFatigueStatus.withinElasticLimit);
      expect(result.isSafeToHaul, isTrue);
      expect(result.isImminentDecouplingDanger, isFalse);
      expect(result.remainingStructuralLifePercent, greaterThan(75.0));
      expect(result.advisory, contains('NOMINAL'));
    });

    test('High strain and microstrain threshold triggers NDT inspection required', () {
      const telemetry = DrawbarCouplingTelemetry(
        kingpinDiameterWearMm: 1.25,
        drawbarEyeletHoleOvalityMm: 1.6,
        dynamicTensileMicrostrain: 1650.0,
        acousticEmissionCrackHits: 32.0,
        cumulativeTowingKilometers: 280000,
        grossTowedWeightTonnes: 44.0,
      );

      final result = service.auditCoupling(
        vehicleId: 'TRAILER-COUPLE-WARN',
        telemetry: telemetry,
      );

      expect(result.status, DrawbarCouplingFatigueStatus.fatigueInspectionRequired);
      expect(result.isSafeToHaul, isFalse);
      expect(result.advisory, contains('WARNING: Drawbar eyelet elongation'));
    });

    test('Excessive kingpin wear (>= 1.6mm) or acoustic crack bursts triggers critical shear hazard', () {
      const telemetry = DrawbarCouplingTelemetry(
        kingpinDiameterWearMm: 1.85,
        drawbarEyeletHoleOvalityMm: 2.8,
        dynamicTensileMicrostrain: 2300.0,
        acousticEmissionCrackHits: 85.0,
        cumulativeTowingKilometers: 450000,
        grossTowedWeightTonnes: 52.0,
      );

      final result = service.auditCoupling(
        vehicleId: 'TRAILER-COUPLE-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, DrawbarCouplingFatigueStatus.criticalShearCrackDecouplingHazard);
      expect(result.isImminentDecouplingDanger, isTrue);
      expect(result.remainingStructuralLifePercent, 0.0);
      expect(result.advisory, contains('CRITICAL HAZARD'));
    });

    testWidgets('DrawbarCouplingFatigueCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool ndtBooked = false;
      const telemetry = DrawbarCouplingTelemetry(
        kingpinDiameterWearMm: 1.3,
        drawbarEyeletHoleOvalityMm: 1.7,
        dynamicTensileMicrostrain: 1700.0,
        acousticEmissionCrackHits: 35.0,
        cumulativeTowingKilometers: 310000,
        grossTowedWeightTonnes: 45.0,
      );

      final result = service.auditCoupling(
        vehicleId: 'ROAD-TRAIN-09',
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
                child: DrawbarCouplingFatigueCard(
                  result: result,
                  onScheduleNdtInspection: () {
                    ndtBooked = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Kingpin & Drawbar Coupling Sentry'), findsOneWidget);
      expect(find.textContaining('ROAD-TRAIN-09'), findsOneWidget);
      expect(find.text('NDT CHECK REQ'), findsOneWidget);

      final bookBtn = find.text('Book NDT Coupling Non-Destructive Testing');
      expect(bookBtn, findsOneWidget);
      await tester.tap(bookBtn);
      expect(ndtBooked, isTrue);
    });
  });
}
