import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/multi_fuel_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/multi_fuel_auditor_card.dart';

void main() {
  group('Loop 81: Multi-Fuel & Alternative Energy Efficiency Auditor Tests', () {
    const service = MultiFuelAuditorService();

    final testRecords = [
      EnergyLogRecord(
        recordId: 'rec-001',
        vehicleId: 'VEH-EV-01',
        timestamp: DateTime(2026, 10, 1),
        fuelType: FleetFuelType.electric,
        quantityUnits: 80.0, // 80 kWh
        totalCost: 16.0,     // $0.20/kWh
        odometerKm: 12400.0,
        distanceSinceLastFillKm: 400.0, // 5.0 km/kWh
      ),
      EnergyLogRecord(
        recordId: 'rec-002',
        vehicleId: 'VEH-EV-01',
        timestamp: DateTime(2026, 10, 4),
        fuelType: FleetFuelType.electric,
        quantityUnits: 75.0, // 75 kWh
        totalCost: 15.0,
        odometerKm: 12775.0,
        distanceSinceLastFillKm: 375.0, // 5.0 km/kWh
      ),
    ];

    test('EV energy consumption computes positive cost savings vs diesel baseline', () {
      final audit = service.auditVehicleEnergy(
        vehicleId: 'VEH-EV-01',
        fuelType: FleetFuelType.electric,
        records: testRecords,
      );

      expect(audit.vehicleId, equals('VEH-EV-01'));
      expect(audit.fuelType, equals(FleetFuelType.electric));
      expect(audit.averageEfficiency, equals(5.0)); // 775km / 155kWh = 5.0 km/kWh
      expect(audit.totalSpend, equals(31.0));
      expect(audit.costSavingsPercentage > 80.0, isTrue); // Very cheap compared to diesel
      expect(audit.isAnomalousConsumption, isFalse);
    });

    test('Abnormal fuel consumption flags anomaly when below threshold', () {
      final lowEfficiencyRecords = [
        EnergyLogRecord(
          recordId: 'rec-003',
          vehicleId: 'TRK-DSL-02',
          timestamp: DateTime(2026, 10, 5),
          fuelType: FleetFuelType.diesel,
          quantityUnits: 100.0,
          totalCost: 150.0,
          odometerKm: 50200.0,
          distanceSinceLastFillKm: 180.0, // 1.8 km/L (under 2.5 min)
        ),
      ];

      final audit = service.auditVehicleEnergy(
        vehicleId: 'TRK-DSL-02',
        fuelType: FleetFuelType.diesel,
        records: lowEfficiencyRecords,
      );

      expect(audit.isAnomalousConsumption, isTrue);
      expect(audit.recommendation, contains('Abnormal energy consumption'));
    });

    test('Empty records return zeroed default report', () {
      final audit = service.auditVehicleEnergy(
        vehicleId: 'VEH-NEW',
        fuelType: FleetFuelType.cng,
        records: [],
      );

      expect(audit.averageEfficiency, equals(0.0));
      expect(audit.totalSpend, equals(0.0));
      expect(audit.isAnomalousConsumption, isFalse);
    });

    testWidgets('AQIL: MultiFuelAuditorCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final audit = service.auditVehicleEnergy(
        vehicleId: 'VEH-EV-01',
        fuelType: FleetFuelType.electric,
        records: testRecords,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MultiFuelAuditorCard(
                result: audit,
                onLogEnergyPurchase: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MultiFuelAuditorCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
