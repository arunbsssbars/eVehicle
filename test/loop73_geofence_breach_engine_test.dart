import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/geofence_breach_engine_service.dart';
import 'package:evehicle_logbook/core/widgets/geofence_breach_engine_card.dart';

void main() {
  group('Loop 73: Geofence Breach Engine Service Tests', () {
    const service = GeofenceBreachEngineService();

    final zones = [
      const GeofenceZone(
        id: 'depot-01',
        name: 'Central Depot & Maintenance Hub',
        type: GeofenceType.depotHomeBase,
        center: GeoCoordinate(latitude: 28.6139, longitude: 77.2090),
        radiusMeters: 500, // 500m radius
        hasCurfew: true,
        curfewStartHour: 22,
        curfewEndHour: 5,
      ),
      const GeofenceZone(
        id: 'restricted-01',
        name: 'Unauthorized High-Theft Industrial Yard',
        type: GeofenceType.restrictedZone,
        center: GeoCoordinate(latitude: 28.7041, longitude: 77.1025),
        radiusMeters: 800,
      ),
      const GeofenceZone(
        id: 'polygon-ncr',
        name: 'Delhi NCR Authorized Delivery Zone',
        type: GeofenceType.allowedOperatingArea,
        center: GeoCoordinate(latitude: 28.60, longitude: 77.20),
        isPolygon: true,
        polygonVertices: [
          GeoCoordinate(latitude: 28.50, longitude: 77.10),
          GeoCoordinate(latitude: 28.50, longitude: 77.30),
          GeoCoordinate(latitude: 28.75, longitude: 77.30),
          GeoCoordinate(latitude: 28.75, longitude: 77.10),
        ],
      ),
    ];

    test('Vehicle safely inside depot satisfies operating rules', () {
      final result = service.evaluateLocation(
        vehicleId: 'veh-001',
        location: const GeoCoordinate(latitude: 28.6140, longitude: 77.2091), // ~15m from depot
        timestamp: DateTime(2026, 10, 5, 14, 0),
        zones: zones,
      );

      expect(result.isInsideDepot, isTrue);
      expect(result.isBreachingRestrictedZone, isFalse);
      expect(result.isCurfewViolated, isFalse);
    });

    test('Curfew violation triggered when vehicle is outside depot during night', () {
      final result = service.evaluateLocation(
        vehicleId: 'veh-002',
        location: const GeoCoordinate(latitude: 28.65, longitude: 77.22), // Outside depot
        timestamp: DateTime(2026, 10, 5, 23, 30), // 11:30 PM
        zones: zones,
      );

      expect(result.isInsideDepot, isFalse);
      expect(result.isCurfewViolated, isTrue);
      expect(result.activeAlerts.any((a) => a.reason.contains('Curfew Violation')), isTrue);
    });

    test('Polygon containment correctly detects authorized vs out-of-bounds', () {
      final insideResult = service.evaluateLocation(
        vehicleId: 'veh-003',
        location: const GeoCoordinate(latitude: 28.60, longitude: 77.20), // Inside polygon
        timestamp: DateTime(2026, 10, 5, 10, 0),
        zones: zones,
      );
      expect(insideResult.isInsideOperatingArea, isTrue);

      final outsideResult = service.evaluateLocation(
        vehicleId: 'veh-004',
        location: const GeoCoordinate(latitude: 29.50, longitude: 78.50), // Far outside polygon
        timestamp: DateTime(2026, 10, 5, 10, 0),
        zones: zones,
      );
      expect(outsideResult.isInsideOperatingArea, isFalse);
      expect(outsideResult.activeAlerts.any((a) => a.reason.contains('out-of-bounds') || a.reason.contains('deviated')), isTrue);
    });
  });

  group('Loop 73: AQIL UI Multi-Viewport & Accessibility Tests', () {
    const service = GeofenceBreachEngineService();

    final testAudit = service.evaluateLocation(
      vehicleId: 'veh-alarm',
      location: const GeoCoordinate(latitude: 28.7042, longitude: 77.1026),
      timestamp: DateTime(2026, 10, 5, 23, 45),
      zones: [
        const GeofenceZone(
          id: 'depot-01',
          name: 'Central Fleet Base',
          type: GeofenceType.depotHomeBase,
          center: GeoCoordinate(latitude: 28.6139, longitude: 77.2090),
          hasCurfew: true,
        ),
        const GeofenceZone(
          id: 'res-01',
          name: 'Forbidden Industrial Yard',
          type: GeofenceType.restrictedZone,
          center: GeoCoordinate(latitude: 28.7041, longitude: 77.1025),
          radiusMeters: 1000,
        ),
      ],
    );

    testWidgets('GeofenceBreachEngineCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GeofenceBreachEngineCard(
                audit: testAudit,
                registrationNumber: 'DL04-TRK-7711 (BharatBenz Multi-Axle)',
                onAcknowledgeAlerts: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Geofence & Curfew Sentinel'), findsOneWidget);
      expect(find.textContaining('Acknowledge & Notify Dispatch'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GeofenceBreachEngineCard maintains integrity under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: SingleChildScrollView(
                child: GeofenceBreachEngineCard(
                  audit: testAudit,
                  registrationNumber: 'DL04-TRK-7711',
                  onAcknowledgeAlerts: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GeofenceBreachEngineCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
