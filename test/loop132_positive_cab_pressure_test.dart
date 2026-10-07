import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/positive_cab_pressure_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/positive_cab_pressure_card.dart';

void main() {
  group('Loop 132: PositiveCabPressureAuditorService & Card Tests', () {
    const service = PositiveCabPressureAuditorService();

    test('Sealed cab with positive overpressure reports nominal clean status', () {
      const telemetry = PositiveCabPressureTelemetry(
        cabinOverpressurePascals: 75.0,
        hepaFilterDifferentialPressurePascals: 140.0,
        ambientParticulatePm25MicrogramsPerM3: 450.0,
        cabinInternalParticulatePm25MicrogramsPerM3: 6.2,
        blowerMotorVoltageVolts: 24.0,
        isDoorOrWindowMagneticReedOpen: false,
      );

      final result = service.auditCabinPressure(
        vehicleId: 'MINING-TRUCK-132-OK',
        telemetry: telemetry,
      );

      expect(result.status, PositiveCabPressureStatus.cabPressurizedNominalClean);
      expect(result.isCabinSafeAndPure, isTrue);
      expect(result.isDepressurizedHazard, isFalse);
      expect(result.cabinPressurePa, 75.0);
      expect(result.safetyAdvisory, contains('NOMINAL'));
    });

    test('Open door or rising filter resistance triggers warning', () {
      const telemetry = PositiveCabPressureTelemetry(
        cabinOverpressurePascals: 30.0,
        hepaFilterDifferentialPressurePascals: 340.0,
        ambientParticulatePm25MicrogramsPerM3: 600.0,
        cabinInternalParticulatePm25MicrogramsPerM3: 28.0,
        blowerMotorVoltageVolts: 24.0,
        isDoorOrWindowMagneticReedOpen: true,
      );

      final result = service.auditCabinPressure(
        vehicleId: 'MINING-TRUCK-132-WARN',
        telemetry: telemetry,
      );

      expect(result.status, PositiveCabPressureStatus.filterRestrictionAirLeakWarning);
      expect(result.isCabinSafeAndPure, isFalse);
      expect(result.safetyAdvisory, contains('WARNING: Cab window/door reed switch open'));
    });

    test('Pressure loss (<20 Pa) or dust intrusion triggers critical depressurization hazard', () {
      const telemetry = PositiveCabPressureTelemetry(
        cabinOverpressurePascals: 8.0,
        hepaFilterDifferentialPressurePascals: 490.0,
        ambientParticulatePm25MicrogramsPerM3: 850.0,
        cabinInternalParticulatePm25MicrogramsPerM3: 65.0,
        blowerMotorVoltageVolts: 24.0,
        isDoorOrWindowMagneticReedOpen: false,
      );

      final result = service.auditCabinPressure(
        vehicleId: 'MINING-TRUCK-132-CRIT',
        telemetry: telemetry,
      );

      expect(result.status, PositiveCabPressureStatus.criticalDustIntrusionDepressurizationHazard);
      expect(result.isDepressurizedHazard, isTrue);
      expect(result.safetyAdvisory, contains('CRITICAL RESPIRATORY HAZARD'));
    });

    testWidgets('PositiveCabPressureCard renders properly across responsive viewports and triggers callback', (tester) async {
      bool fanBoosted = false;
      const telemetry = PositiveCabPressureTelemetry(
        cabinOverpressurePascals: 10.0,
        hepaFilterDifferentialPressurePascals: 460.0,
        ambientParticulatePm25MicrogramsPerM3: 900.0,
        cabinInternalParticulatePm25MicrogramsPerM3: 70.0,
        blowerMotorVoltageVolts: 24.0,
        isDoorOrWindowMagneticReedOpen: false,
      );

      final result = service.auditCabinPressure(
        vehicleId: 'QUARRY-LOADER-09',
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
                child: PositiveCabPressureCard(
                  result: result,
                  onBoostBlowerFan: () {
                    fanBoosted = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cabin Positive Pressure Sentry'), findsOneWidget);
      expect(find.textContaining('QUARRY-LOADER-09'), findsOneWidget);
      expect(find.text('DEPRESSURIZED'), findsOneWidget);

      final boostBtn = find.text('Boost Pressurization Blower Fan Speed');
      expect(boostBtn, findsOneWidget);
      await tester.tap(boostBtn);
      expect(fanBoosted, isTrue);
    });
  });
}
