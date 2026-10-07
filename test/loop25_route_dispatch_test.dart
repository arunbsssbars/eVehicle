import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/route_dispatch_service.dart';
import 'package:evehicle_logbook/core/widgets/multi_leg_dispatch_card.dart';

void main() {
  group('Loop 25 - Multi-Leg Route Optimizer & Dispatch Service', () {
    const service = RouteDispatchService();

    test('Optimizing a zig-zag route saves distance compared to arbitrary input order', () {
      // Depot at (12.9716, 77.5946)
      const originLat = 12.9716;
      const originLon = 77.5946;

      // Stop 1 is far, Stop 2 is close, Stop 3 is farthest
      const stops = [
        DispatchStop(id: 's1', title: 'Hub East (Far)', latitude: 12.9800, longitude: 77.6500),
        DispatchStop(id: 's2', title: 'Hub Central (Close)', latitude: 12.9720, longitude: 77.5980),
        DispatchStop(id: 's3', title: 'Hub North (Medium)', latitude: 12.9850, longitude: 77.6000),
      ];

      final itinerary = service.optimizeRoute(
        originLat: originLat,
        originLon: originLon,
        stops: stops,
      );

      expect(itinerary.orderedStops.first.id, equals('s2')); // Closer stop chosen first
      expect(itinerary.optimizedDistanceKm, lessThanOrEqualTo(itinerary.originalDistanceKm));
      expect(itinerary.totalEstimatedMinutes, greaterThan(0));
    });

    test('Urgent delivery stops take priority in sequence', () {
      const originLat = 12.9716;
      const originLon = 77.5946;

      const stops = [
        DispatchStop(id: 's1', title: 'Normal Close Stop', latitude: 12.9720, longitude: 77.5950, isUrgent: false),
        DispatchStop(id: 's2', title: 'Urgent Far Medical Supply', latitude: 12.9900, longitude: 77.6200, isUrgent: true),
      ];

      final itinerary = service.optimizeRoute(
        originLat: originLat,
        originLon: originLon,
        stops: stops,
      );

      expect(itinerary.orderedStops.first.id, equals('s2'));
    });

    test('Empty stops input returns zero distance itinerary without errors', () {
      final itinerary = service.optimizeRoute(
        originLat: 0.0,
        originLon: 0.0,
        stops: [],
      );

      expect(itinerary.orderedStops, isEmpty);
      expect(itinerary.optimizedDistanceKm, equals(0.0));
    });
  });

  group('Loop 25 - Dispatch Optimizer AQIL Responsive UI Tests', () {
    testWidgets('MultiLegDispatchCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const itinerary = OptimizedItinerary(
        orderedStops: [
          DispatchStop(id: 's1', title: 'Downtown Pharmacy Distribution Hub', latitude: 12.97, longitude: 77.59),
          DispatchStop(id: 's2', title: 'Northside Clinic', latitude: 12.98, longitude: 77.60, isUrgent: true),
          DispatchStop(id: 's3', title: 'Airport Cargo Terminal 3', latitude: 13.01, longitude: 77.65),
        ],
        originalDistanceKm: 42.5,
        optimizedDistanceKm: 31.8,
        distanceSavedKm: 10.7,
        percentageSaved: 25.2,
        totalEstimatedMinutes: 75,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiLegDispatchCard(
              itinerary: itinerary,
              onStartRoute: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dispatch Optimizer'), findsOneWidget);
      expect(find.text('-25.2% KM'), findsOneWidget);
      expect(find.text('Launch Multi-Leg Navigation'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MultiLegDispatchCard preserves layout stability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const itinerary = OptimizedItinerary(
        orderedStops: [
          DispatchStop(id: 's1', title: 'Express Drop 1', latitude: 12.97, longitude: 77.59),
          DispatchStop(id: 's2', title: 'Express Drop 2', latitude: 12.98, longitude: 77.60),
        ],
        originalDistanceKm: 15.0,
        optimizedDistanceKm: 15.0,
        distanceSavedKm: 0.0,
        percentageSaved: 0.0,
        totalEstimatedMinutes: 35,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: const Scaffold(
              body: MultiLegDispatchCard(
                itinerary: itinerary,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dispatch Optimizer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
