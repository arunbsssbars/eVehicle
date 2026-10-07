import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/journey.dart';
import 'package:evehicle_logbook/core/storage/local_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PRD Core Principle & Odometer Verification Tests', () {
    test('Official Distance is calculated strictly as Closing KM - Opening KM', () {
      final journey = Journey(
        id: 'JRN-TEST-01',
        localId: 'LOC-01',
        clientOperationId: 'OP-01',
        vehicleId: 'VEH-01',
        vehicleRegistration: 'UP16 AB 1234',
        vehicleModel: 'Toyota Innova Crysta',
        driverId: 'DRV-01',
        driverName: 'Rajesh Kumar',
        officerId: 'USR-01',
        officerName: 'Dr. S. K. Verma',
        department: 'Public Works Department',
        office: 'District Division',
        journeyDate: DateTime.now(),
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        startLocation: 'Division Office',
        destination: 'Site 150',
        purpose: 'Site Inspection',
        openingOdometer: 52340.0,
        closingOdometer: 52485.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Section 3: Official Distance = Closing (52485) - Opening (52340) = 145 KM
      expect(journey.calculatedDistance, equals(145.0));
    });

    test('GPS distance is treated as supporting information without replacing official distance', () {
      final journey = Journey(
        id: 'JRN-TEST-02',
        localId: 'LOC-02',
        clientOperationId: 'OP-02',
        vehicleId: 'VEH-01',
        vehicleRegistration: 'UP16 AB 1234',
        vehicleModel: 'Toyota Innova Crysta',
        driverId: 'DRV-01',
        driverName: 'Rajesh Kumar',
        officerId: 'USR-01',
        officerName: 'Dr. S. K. Verma',
        department: 'Public Works Department',
        office: 'District Division',
        journeyDate: DateTime.now(),
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        startLocation: 'Division Office',
        destination: 'Site 150',
        purpose: 'Site Inspection',
        openingOdometer: 50000.0,
        closingOdometer: 50100.0,
        officialDistance: 100.0,
        gpsDistance: 98.4, // supporting GPS distance
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(journey.calculatedDistance, equals(100.0));
      expect(journey.gpsDistance, equals(98.4));
      expect(journey.hasDistanceDiscrepancy, isFalse);
    });

    test('Excessive discrepancy between GPS and Odometer triggers anomaly flag', () {
      final journey = Journey(
        id: 'JRN-TEST-03',
        localId: 'LOC-03',
        clientOperationId: 'OP-03',
        vehicleId: 'VEH-01',
        vehicleRegistration: 'UP16 AB 1234',
        vehicleModel: 'Toyota Innova Crysta',
        driverId: 'DRV-01',
        driverName: 'Rajesh Kumar',
        officerId: 'USR-01',
        officerName: 'Dr. S. K. Verma',
        department: 'Public Works Department',
        office: 'District Division',
        journeyDate: DateTime.now(),
        startTime: DateTime.now(),
        startLocation: 'Division Office',
        destination: 'Site 150',
        purpose: 'Site Inspection',
        openingOdometer: 50000.0,
        closingOdometer: 50150.0, // 150 KM official
        gpsDistance: 80.0, // Large gap > 20%
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(journey.hasDistanceDiscrepancy, isTrue);
    });

    test('LocalDatabase initializes with seed data and supports journey operations', () async {
      final db = LocalDatabase.instance;
      await db.init();

      expect(db.vehicles.isNotEmpty, isTrue);
      expect(db.journeys.isNotEmpty, isTrue);

      final vehicle = db.vehicles.first;
      final startOdo = vehicle.currentOdometer;

      // Start new journey
      final started = await db.startJourney(
        vehicle: vehicle,
        driverId: 'DRV-01',
        driverName: 'Rajesh Kumar',
        startLocation: 'Office HQ',
        purpose: 'Official Inspection',
        openingOdometer: startOdo,
      );

      expect(started.status, equals(JourneyStatus.active));
      expect(started.openingOdometer, equals(startOdo));

      // Complete and submit journey
      final completed = await db.completeAndSubmitJourney(
        journeyId: started.id,
        destination: 'Field Station',
        closingOdometer: startOdo + 35.0,
      );

      expect(completed.status, equals(JourneyStatus.pendingApproval));
      expect(completed.calculatedDistance, equals(35.0));

      // Approve journey
      final approved = await db.approveJourney(completed.id, 'Anjali Sharma, IAS');
      expect(approved.status, equals(JourneyStatus.approved));
      expect(approved.approvedBy, equals('Anjali Sharma, IAS'));
    });
  });
}
