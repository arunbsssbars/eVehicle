import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/vehicle.dart';
import 'package:evehicle_logbook/core/models/journey.dart';
import 'package:evehicle_logbook/core/services/carbon_emissions_service.dart';
import 'package:evehicle_logbook/core/widgets/green_fleet_card.dart';
import 'package:evehicle_logbook/features/fleet/fleet_intelligence_screen.dart';
import 'package:evehicle_logbook/core/storage/local_database.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await LocalDatabase.instance.init();
  });

  group('Loop 2: Real-time Fuel Efficiency & Carbon Emissions (CO2) Analytics Tests', () {
    test('CarbonEmissionsService calculates accurate journey emissions across fuel types', () {
      // 100 KM on Diesel @ 10 KM/L = 10 L * 2.68 kg/L = 26.8 kg CO2
      final dieselKg = CarbonEmissionsService.calculateJourneyEmissionsKg(
        distanceKm: 100.0,
        fuelType: 'Diesel',
        efficiencyKmPerUnit: 10.0,
      );
      expect(dieselKg, closeTo(26.8, 0.01));

      // 100 KM on Petrol @ 10 KM/L = 10 L * 2.31 kg/L = 23.1 kg CO2
      final petrolKg = CarbonEmissionsService.calculateJourneyEmissionsKg(
        distanceKm: 100.0,
        fuelType: 'Petrol',
        efficiencyKmPerUnit: 10.0,
      );
      expect(petrolKg, closeTo(23.1, 0.01));

      // 100 KM on Electric (EV) = 100 * 0.052 = 5.2 kg CO2 (Grid indirect)
      final evKg = CarbonEmissionsService.calculateJourneyEmissionsKg(
        distanceKm: 100.0,
        fuelType: 'Electric (EV)',
      );
      expect(evKg, closeTo(5.2, 0.01));
    });

    test('CarbonEmissionsService calculates carbon saved by green vehicles compared to baseline', () {
      final now = DateTime.now();
      final evVehicle = Vehicle(
        id: 'VEH-EV-01',
        registrationNumber: 'DL01-EV-9999',
        make: 'Tata',
        model: 'Nexon EV',
        vehicleType: 'EV SUV',
        fuelType: 'Electric',
        manufacturingYear: 2024,
        currentOdometer: 5000.0,
        assignedOffice: 'HQ',
        assignedDriverId: 'D1',
        assignedDriverName: 'Driver 1',
        nextServiceKm: 15000.0,
        nextServiceDate: now.add(const Duration(days: 90)),
      );

      final evJourney = Journey(
        id: 'JRN-EV-1',
        localId: 'LOC-EV-1',
        clientOperationId: 'OP-EV-1',
        vehicleId: 'VEH-EV-01',
        vehicleRegistration: 'DL01-EV-9999',
        vehicleModel: 'Tata Nexon EV',
        driverId: 'D1',
        driverName: 'Driver 1',
        officerId: 'USR-01',
        officerName: 'Officer 1',
        department: 'Operations',
        office: 'HQ',
        journeyDate: now,
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now,
        startLocation: 'Point A',
        destination: 'Point B',
        purpose: 'Official Inspection',
        openingOdometer: 4900.0,
        closingOdometer: 5000.0, // 100 KM
        officialDistance: 100.0,
        createdAt: now,
        updatedAt: now,
      );

      final savedKg = CarbonEmissionsService.calculateCarbonSavedKg(
        journeys: [evJourney],
        vehicles: [evVehicle],
      );

      // Baseline (18.1 kg) - EV (5.2 kg) = 12.9 kg saved
      expect(savedKg, closeTo(12.9, 0.1));
    });

    test('EcoRating grades accurately from Green Fleet Leader to High Emitter', () {
      // Very low emissions (< 60 g/km) -> A+
      final ratingA = CarbonEmissionsService.getEcoRating(
        totalDistanceKm: 1000.0,
        totalEmissionsKg: 50.0, // 50 g/km
      );
      expect(ratingA.grade, equals('A+'));
      expect(ratingA.label, equals('Green Fleet Leader'));

      // Normal efficient fleet (60-120 g/km) -> B
      final ratingB = CarbonEmissionsService.getEcoRating(
        totalDistanceKm: 1000.0,
        totalEmissionsKg: 100.0, // 100 g/km
      );
      expect(ratingB.grade, equals('B'));
      expect(ratingB.label, equals('Eco Efficient'));

      // High emitter (> 180 g/km) -> D
      final ratingD = CarbonEmissionsService.getEcoRating(
        totalDistanceKm: 1000.0,
        totalEmissionsKg: 250.0, // 250 g/km
      );
      expect(ratingD.grade, equals('D'));
      expect(ratingD.label, equals('High Emission Alert'));
    });

    testWidgets('AQIL: GreenFleetCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: GreenFleetCard(
                totalDistanceKm: 45200.0,
                totalEmissionsKg: 825.4,
                carbonSavedKg: 142.8,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GreenFleetCard), findsOneWidget);
    });

    testWidgets('AQIL: FleetIntelligenceScreen renders with GreenFleetCard on mobile viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FleetIntelligenceScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GreenFleetCard), findsOneWidget);
    });
  });
}
