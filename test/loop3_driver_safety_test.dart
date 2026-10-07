import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/journey.dart';
import 'package:evehicle_logbook/core/services/driver_safety_service.dart';
import 'package:evehicle_logbook/core/widgets/driver_leaderboard_card.dart';
import 'package:evehicle_logbook/features/fleet/fleet_intelligence_screen.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });
  group('Loop 3: Driver Performance & Safety Scoring Engine Tests', () {
    final now = DateTime.now();

    final safeJourney1 = Journey(
      id: 'JRN-SAFE-1',
      localId: 'LOC-1',
      clientOperationId: 'OP-1',
      vehicleId: 'VEH-01',
      vehicleRegistration: 'DL01-AB-1234',
      vehicleModel: 'Toyota Innova',
      driverId: 'DRV-001',
      driverName: 'Rajesh Kumar',
      officerId: 'USR-01',
      officerName: 'Director Sharma',
      department: 'Admin',
      office: 'HQ',
      journeyDate: now,
      startTime: now.subtract(const Duration(hours: 1)),
      endTime: now,
      startLocation: 'North Block',
      destination: 'South Block',
      purpose: 'Official Meeting',
      openingOdometer: 10000.0,
      closingOdometer: 10050.0, // 50 km in 60 min = 50 km/h (optimal)
      officialDistance: 50.0,
      createdAt: now,
      updatedAt: now,
    );

    final harshJourney2 = Journey(
      id: 'JRN-HARSH-1',
      localId: 'LOC-2',
      clientOperationId: 'OP-2',
      vehicleId: 'VEH-02',
      vehicleRegistration: 'DL01-CD-5678',
      vehicleModel: 'Mahindra Scorpio',
      driverId: 'DRV-002',
      driverName: 'Vikram Singh',
      officerId: 'USR-02',
      officerName: 'Inspector Patel',
      department: 'Logistics',
      office: 'Depot',
      journeyDate: now,
      startTime: now.subtract(const Duration(minutes: 30)),
      endTime: now,
      startLocation: 'Depot A',
      destination: 'Depot B',
      purpose: 'Urgent Delivery',
      openingOdometer: 20000.0,
      closingOdometer: 20070.0, // 70 km in 30 min = 140 km/h (harsh speed alert)
      officialDistance: 70.0,
      createdAt: now,
      updatedAt: now,
    );

    test('DriverSafetyService scores smooth driver higher than speeding driver', () {
      final safeProfile = DriverSafetyService.calculateDriverProfile(
        driverId: 'DRV-001',
        driverName: 'Rajesh Kumar',
        journeys: [safeJourney1],
      );

      final harshProfile = DriverSafetyService.calculateDriverProfile(
        driverId: 'DRV-002',
        driverName: 'Vikram Singh',
        journeys: [harshJourney2],
      );

      expect(safeProfile.safetyScore, greaterThan(harshProfile.safetyScore));
      expect(safeProfile.compositeScore, greaterThan(harshProfile.compositeScore));
      expect(safeProfile.tier, anyOf(equals(DriverTier.platinum), equals(DriverTier.gold)));
    });

    test('DriverSafetyService ranks drivers descending by composite score', () {
      final leaderboard = DriverSafetyService.rankDrivers(
        journeys: [safeJourney1, harshJourney2],
      );

      expect(leaderboard.length, equals(2));
      expect(leaderboard[0].rank, equals(1));
      expect(leaderboard[0].profile.driverName, equals('Rajesh Kumar'));
      expect(leaderboard[1].rank, equals(2));
      expect(leaderboard[1].profile.driverName, equals('Vikram Singh'));
    });

    testWidgets('AQIL: DriverLeaderboardCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final leaderboard = DriverSafetyService.rankDrivers(
        journeys: [safeJourney1, harshJourney2],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: DriverLeaderboardCard(leaderboard: leaderboard),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DriverLeaderboardCard), findsOneWidget);
      expect(find.text('Rajesh Kumar'), findsOneWidget);
      expect(find.text('Vikram Singh'), findsOneWidget);
    });

    testWidgets('AQIL: DriverLeaderboardCard scales under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final leaderboard = DriverSafetyService.rankDrivers(
        journeys: [safeJourney1],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DriverLeaderboardCard(leaderboard: leaderboard),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DriverLeaderboardCard), findsOneWidget);
    });

    testWidgets('AQIL: FleetIntelligenceScreen integrates DriverLeaderboardCard cleanly', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
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
      expect(find.byType(DriverLeaderboardCard), findsOneWidget);
    });
  });
}
