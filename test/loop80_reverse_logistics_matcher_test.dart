import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/reverse_logistics_matcher_service.dart';
import 'package:evehicle_logbook/core/widgets/reverse_logistics_matcher_card.dart';

void main() {
  group('Loop 80: Reverse Logistics Freight Matcher Service Tests', () {
    const service = ReverseLogisticsMatcherService();

    final now = DateTime(2026, 10, 5, 10, 0);
    final route = ReturnTripRoute(
      vehicleId: 'trk-100',
      registrationNumber: 'DL01-TK-5544',
      origin: const RoutePoint(locationName: 'Jaipur Logistics Hub', latitude: 26.9124, longitude: 75.7873),
      destination: const RoutePoint(locationName: 'Delhi Central Depot', latitude: 28.6139, longitude: 77.2090),
      returnDepartureTime: now.add(const Duration(hours: 2)),
      emptyDistanceKm: 260.0,
      availablePayloadCapacityKg: 8000,
      availableVolumeCubicMeters: 30,
      fuelEfficiencyKmPerLitre: 4.0,
    );

    test('Viable backhaul load matches route with positive profit and avoided carbon', () {
      final availableLoads = [
        AvailableBackhaulCargo(
          cargoId: 'cargo-jpr-del',
          shipperName: 'Rajasthan Ceramics & Textiles',
          pickupLocation: const RoutePoint(locationName: 'Jaipur Industrial Area', latitude: 26.9200, longitude: 75.7900),
          dropoffLocation: const RoutePoint(locationName: 'Gurugram Warehousing Yard', latitude: 28.4595, longitude: 77.0266),
          weightKg: 5500,
          volumeCubicMeters: 20,
          offeredFreightPayout: 18000.0,
          pickupWindowStart: now,
          pickupWindowEnd: now.add(const Duration(hours: 6)),
        ),
      ];

      final match = service.matchReturnTrip(route: route, availableLoads: availableLoads);

      expect(match.hasViableMatches, isTrue);
      expect(match.potentialRevenueYield > 12000.0, isTrue);
      expect(match.totalCarbonSavingsKg > 50.0, isTrue);
      expect(match.rankedOpportunities.first.isFitApproved, isTrue);
    });

    test('Overweight cargo exceeding payload capacity is marked as unfit', () {
      final availableLoads = [
        AvailableBackhaulCargo(
          cargoId: 'cargo-heavy',
          shipperName: 'Heavy Steel Castings Co.',
          pickupLocation: const RoutePoint(locationName: 'Jaipur', latitude: 26.9124, longitude: 75.7873),
          dropoffLocation: const RoutePoint(locationName: 'Delhi', latitude: 28.6139, longitude: 77.2090),
          weightKg: 15000, // Exceeds 8,000 kg capacity!
          volumeCubicMeters: 10,
          offeredFreightPayout: 35000.0,
          pickupWindowStart: now,
          pickupWindowEnd: now.add(const Duration(hours: 5)),
        ),
      ];

      final match = service.matchReturnTrip(route: route, availableLoads: availableLoads);

      expect(match.hasViableMatches, isFalse);
      expect(match.rankedOpportunities.first.isFitApproved, isFalse);
    });
  });

  group('Loop 80: AQIL UI Multi-Viewport & Accessibility Tests', () {
    const service = ReverseLogisticsMatcherService();

    final testMatch = service.matchReturnTrip(
      route: ReturnTripRoute(
        vehicleId: 'trk-test',
        registrationNumber: 'KA01-TK-9080',
        origin: const RoutePoint(locationName: 'Bengaluru Airport', latitude: 13.1986, longitude: 77.7066),
        destination: const RoutePoint(locationName: 'Mysuru Industrial Estate', latitude: 12.2958, longitude: 76.6394),
        returnDepartureTime: DateTime.now(),
        emptyDistanceKm: 150.0,
        availablePayloadCapacityKg: 6000,
        availableVolumeCubicMeters: 25,
      ),
      availableLoads: [
        AvailableBackhaulCargo(
          cargoId: 'c1',
          shipperName: 'Southern Electronics Logistics',
          pickupLocation: const RoutePoint(locationName: 'Electronic City', latitude: 12.8452, longitude: 77.6602),
          dropoffLocation: const RoutePoint(locationName: 'Mysuru', latitude: 12.2958, longitude: 76.6394),
          weightKg: 3000,
          volumeCubicMeters: 12,
          offeredFreightPayout: 12500.0,
          pickupWindowStart: DateTime.now(),
          pickupWindowEnd: DateTime.now().add(const Duration(hours: 5)),
        ),
      ],
    );

    testWidgets('ReverseLogisticsMatcherCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReverseLogisticsMatcherCard(
                result: testMatch,
                onAcceptBackhaulLoad: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Reverse Logistics Backhaul'), findsOneWidget);
      expect(find.textContaining('Accept Best Backhaul & Assign Route'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ReverseLogisticsMatcherCard maintains integrity under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: SingleChildScrollView(
                child: ReverseLogisticsMatcherCard(
                  result: testMatch,
                  onAcceptBackhaulLoad: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReverseLogisticsMatcherCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
