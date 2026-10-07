import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/driver_fatigue_hos_service.dart';
import 'package:evehicle_logbook/core/widgets/driver_fatigue_hos_card.dart';

void main() {
  group('Loop 78: Driver Fatigue & Hours of Service (HOS) Sentinel Tests', () {
    const service = DriverFatigueHosService();

    test('Compliant shift within 8h continuous driving and low fatigue index', () {
      final base = DateTime(2026, 10, 5, 8, 0);
      final periods = [
        DutyPeriod(status: DutyStatus.driving, startTime: base, endTime: base.add(const Duration(hours: 4))),
        DutyPeriod(status: DutyStatus.offDuty, startTime: base.add(const Duration(hours: 4)), endTime: base.add(const Duration(hours: 4, minutes: 45))), // 45-min rest break
        DutyPeriod(status: DutyStatus.driving, startTime: base.add(const Duration(hours: 4, minutes: 45)), endTime: base.add(const Duration(hours: 7, minutes: 45))), // 3h driving
      ];

      final audit = service.evaluateDriverShift(
        driverId: 'drv-01',
        driverName: 'Gurpreet Singh',
        periods: periods,
        currentTime: base.add(const Duration(hours: 8)),
      );

      expect(audit.isHosViolated, isFalse);
      expect(audit.totalDrivingMinutes, 420); // 7 hours
      expect(audit.continuousDrivingMinutes, 180); // 3 hours (reset by 45-min break)
      expect(audit.requiresImmediateStop, isFalse);
    });

    test('Circadian nadir driving and exceeding 11h limit flags immediate stop', () {
      final night = DateTime(2026, 10, 5, 14, 0);
      final periods = [
        DutyPeriod(status: DutyStatus.driving, startTime: night, endTime: night.add(const Duration(hours: 12))), // 12h driving!
      ];

      final audit = service.evaluateDriverShift(
        driverId: 'drv-02',
        driverName: 'Suresh Raina',
        periods: periods,
        currentTime: DateTime(2026, 10, 6, 3, 30), // 03:30 AM (Circadian dip)
      );

      expect(audit.isHosViolated, isTrue);
      expect(audit.isInCircadianHighRiskWindow, isTrue);
      expect(audit.requiresImmediateStop, isTrue);
      expect(audit.fatigueRiskScore >= 75.0, isTrue);
    });
  });

  group('Loop 78: AQIL UI Multi-Viewport & Accessibility Tests', () {
    const service = DriverFatigueHosService();

    final testAudit = service.evaluateDriverShift(
      driverId: 'drv-test',
      driverName: 'Kuldeep Yadav (Inter-State Express Driver)',
      periods: [
        DutyPeriod(status: DutyStatus.driving, startTime: DateTime.now().subtract(const Duration(hours: 5)), endTime: DateTime.now()),
      ],
    );

    testWidgets('DriverFatigueHosCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DriverFatigueHosCard(
                audit: testAudit,
                onAuthorizeRestBreak: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Kuldeep Yadav'), findsOneWidget);
      expect(find.textContaining('HOS Fatigue Sentinel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DriverFatigueHosCard maintains integrity under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: SingleChildScrollView(
                child: DriverFatigueHosCard(
                  audit: testAudit,
                  onAuthorizeRestBreak: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DriverFatigueHosCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
