import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/predictive_maintenance_scheduler_service.dart';
import 'package:evehicle_logbook/core/widgets/predictive_maintenance_scheduler_card.dart';

void main() {
  group('Loop 75: Predictive Maintenance Scheduler Service Tests', () {
    const service = PredictiveMaintenanceSchedulerService();

    test('Freshly serviced vehicle reports high health and distant service horizon', () {
      const context = VehicleUsageContext(
        vehicleId: 'veh-new',
        registrationNumber: 'KA01-MH-2026',
        currentOdometerKm: 12500,
        kmSinceLastService: 500, // 500 km only
        avgDailyKm: 50,
      );

      final forecast = service.forecastMaintenance(context: context);

      expect(forecast.overallVehicleHealthScore > 90.0, isTrue);
      expect(forecast.isImmediateServiceRequired, isFalse);
      expect(forecast.daysUntilNextService > 50, isTrue);
    });

    test('Heavy dusty and harsh driving accelerates wear and flags upcoming service', () {
      const context = VehicleUsageContext(
        vehicleId: 'veh-mining',
        registrationNumber: 'JH05-TK-8899',
        currentOdometerKm: 98000,
        kmSinceLastService: 9500, // Near 10,000 km oil change limit
        operatesInSevereDust: true,
        harshEventRatePer100Km: 8.0,
        avgDailyKm: 120,
      );

      final forecast = service.forecastMaintenance(context: context);

      expect(forecast.isImmediateServiceRequired, isTrue);
      final oilStatus = forecast.componentStatuses.firstWhere((c) => c.component == FleetComponent.engineOil);
      expect(oilStatus.isReplacementUrgent, isTrue);
      expect(oilStatus.remainingHealthPercent < 20.0, isTrue);
    });
  });

  group('Loop 75: AQIL UI Multi-Viewport & Accessibility Tests', () {
    const service = PredictiveMaintenanceSchedulerService();

    final testForecast = service.forecastMaintenance(
      context: const VehicleUsageContext(
        vehicleId: 'veh-test',
        registrationNumber: 'DL01-AB-1234',
        currentOdometerKm: 45000,
        kmSinceLastService: 7000,
        avgDailyKm: 80,
      ),
    );

    testWidgets('PredictiveMaintenanceSchedulerCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PredictiveMaintenanceSchedulerCard(
                forecast: testForecast,
                registrationNumber: 'DL01-AB-1234 (Ashok Leyland Dost Commercial)',
                onBookServiceSlot: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Predictive Maintenance'), findsOneWidget);
      expect(find.textContaining('Book Preventive Workshop Service'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PredictiveMaintenanceSchedulerCard maintains integrity under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: SingleChildScrollView(
                child: PredictiveMaintenanceSchedulerCard(
                  forecast: testForecast,
                  registrationNumber: 'DL01-AB-1234',
                  onBookServiceSlot: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PredictiveMaintenanceSchedulerCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
