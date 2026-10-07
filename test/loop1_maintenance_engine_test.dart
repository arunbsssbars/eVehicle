import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/vehicle.dart';
import 'package:evehicle_logbook/core/models/fuel_and_service.dart';
import 'package:evehicle_logbook/core/storage/local_database.dart';
import 'package:evehicle_logbook/features/vehicles/vehicle_details_screen.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await LocalDatabase.instance.init();
  });

  group('Loop 1: Fleet Maintenance Scheduling & Reminder Engine Tests', () {
    test('Vehicle service calculation getters compute accurate urgency and remaining distance/days', () {
      final now = DateTime.now();

      // Case 1: Healthy vehicle
      final healthyVehicle = Vehicle(
        id: 'VEH-H1',
        registrationNumber: 'UP32-H-1001',
        make: 'Toyota',
        model: 'Innova',
        vehicleType: 'MPV',
        fuelType: 'Diesel',
        manufacturingYear: 2023,
        currentOdometer: 40000.0,
        assignedOffice: 'HQ',
        assignedDriverId: 'D1',
        assignedDriverName: 'Driver 1',
        nextServiceKm: 45000.0,
        nextServiceDate: now.add(const Duration(days: 60)),
      );

      expect(healthyVehicle.isServiceDue, isFalse);
      expect(healthyVehicle.isServiceDueSoon, isFalse);
      expect(healthyVehicle.remainingKmToService, equals(5000.0));
      expect(healthyVehicle.serviceUrgencyLabel, equals('HEALTHY'));

      // Case 2: Due soon by KM (within 500 KM)
      final dueSoonVehicle = healthyVehicle.copyWith(
        currentOdometer: 44600.0,
        nextServiceKm: 45000.0,
      );
      expect(dueSoonVehicle.isServiceDue, isFalse);
      expect(dueSoonVehicle.isServiceDueSoon, isTrue);
      expect(dueSoonVehicle.remainingKmToService, equals(400.0));
      expect(dueSoonVehicle.serviceUrgencyLabel, equals('DUE SOON'));

      // Case 3: Overdue by KM
      final overdueVehicle = healthyVehicle.copyWith(
        currentOdometer: 45200.0,
        nextServiceKm: 45000.0,
      );
      expect(overdueVehicle.isServiceDue, isTrue);
      expect(overdueVehicle.remainingKmToService, equals(-200.0));
      expect(overdueVehicle.serviceUrgencyLabel, equals('OVERDUE'));

      // Case 4: Overdue by Date
      final dateOverdueVehicle = healthyVehicle.copyWith(
        currentOdometer: 40000.0,
        nextServiceKm: 45000.0,
        nextServiceDate: now.subtract(const Duration(days: 2)),
      );
      expect(dateOverdueVehicle.isServiceDue, isTrue);
      expect(dateOverdueVehicle.remainingDaysToService, lessThan(0));
      expect(dateOverdueVehicle.serviceUrgencyLabel, equals('OVERDUE'));
    });

    test('LocalDatabase automatically updates vehicle nextServiceKm and nextServiceDate upon logging maintenance', () async {
      final db = LocalDatabase.instance;
      final vehicle = db.vehicles.first;
      final initialNextKm = vehicle.nextServiceKm;
      final newServiceDate = DateTime.now().add(const Duration(days: 120));
      final newNextKm = initialNextKm + 10000.0;

      final record = MaintenanceRecord(
        id: 'MAINT-TEST-01',
        vehicleId: vehicle.id,
        serviceDate: DateTime.now(),
        odometerKm: vehicle.currentOdometer,
        serviceType: '10,000 KM Major Inspection',
        workPerformed: 'Replaced engine oil, oil filter, air filter, and brake pads.',
        cost: 6500.0,
        vendor: 'Authorized Service Center',
        nextServiceKm: newNextKm,
        nextServiceDate: newServiceDate,
      );

      await db.addMaintenanceRecord(record);

      final updatedVehicle = db.vehicles.firstWhere((v) => v.id == vehicle.id);
      expect(updatedVehicle.nextServiceKm, equals(newNextKm));
      expect(updatedVehicle.nextServiceDate.day, equals(newServiceDate.day));

      final vehicleRecords = db.getMaintenanceRecordsForVehicle(vehicle.id);
      expect(vehicleRecords.any((m) => m.id == 'MAINT-TEST-01'), isTrue);

      final totalCost = db.getTotalMaintenanceCostForVehicle(vehicle.id);
      expect(totalCost, greaterThanOrEqualTo(6500.0));
    });

    testWidgets('AQIL: VehicleDetailsScreen renders elevated service card without overflow on 320px phone viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VehicleDetailsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(VehicleDetailsScreen), findsOneWidget);
    });
  });
}
