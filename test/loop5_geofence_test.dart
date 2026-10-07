import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/geofence_zone.dart';
import 'package:evehicle_logbook/core/models/journey.dart';
import 'package:evehicle_logbook/core/services/geofence_service.dart';
import 'package:evehicle_logbook/core/widgets/geofence_status_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Loop 5: Geofencing & Operational Route Polygon Checker Tests', () {
    // Connaught Place, New Delhi: 28.6315, 77.2167
    // India Gate, New Delhi: 28.6129, 77.2295 (~2.4 km)
    const cpLat = 28.6315;
    const cpLon = 77.2167;
    const igLat = 28.6129;
    const igLon = 77.2295;

    test('Haversine distance calculates accurate real-world distance in meters', () {
      final distance = GeofenceService.calculateDistanceMeters(
        lat1: cpLat,
        lon1: cpLon,
        lat2: igLat,
        lon2: igLon,
      );

      // Distance should be approximately 2420 meters (+/- 100 meters)
      expect(distance, greaterThan(2300.0));
      expect(distance, lessThan(2600.0));
    });

    test('isInsideCircle detects points within radius and rejects points outside', () {
      const radiusM = 500.0;

      // Center point itself is inside
      expect(
        GeofenceService.isInsideCircle(
          lat: cpLat,
          lon: cpLon,
          centerLat: cpLat,
          centerLon: cpLon,
          radiusMeters: radiusM,
        ),
        isTrue,
      );

      // Point ~2.4 km away is well outside 500m radius
      expect(
        GeofenceService.isInsideCircle(
          lat: igLat,
          lon: igLon,
          centerLat: cpLat,
          centerLon: cpLon,
          radiusMeters: radiusM,
        ),
        isFalse,
      );
    });

    test('Ray-casting algorithm correctly detects point in polygon', () {
      // Define a polygon bounding Delhi Central Area
      final polygon = [
        const GeoCoordinate(28.6500, 77.2000),
        const GeoCoordinate(28.6500, 77.2400),
        const GeoCoordinate(28.6000, 77.2400),
        const GeoCoordinate(28.6000, 77.2000),
      ];

      // CP is inside this box (28.6315 is between 28.60 and 28.65; 77.2167 is between 77.20 and 77.24)
      expect(
        GeofenceService.isPointInPolygon(
          lat: cpLat,
          lon: cpLon,
          vertices: polygon,
        ),
        isTrue,
      );

      // Point far away (Noida: 28.5355, 77.3910) is outside
      expect(
        GeofenceService.isPointInPolygon(
          lat: 28.5355,
          lon: 77.3910,
          vertices: polygon,
        ),
        isFalse,
      );
    });

    test('evaluateJourney detects breach when route passes through restricted zone', () {
      const restrictedZone = GeofenceZone(
        id: 'ZONE-RESTRICTED-01',
        name: 'High Security Perimeter',
        type: GeofenceType.restrictedArea,
        centerLatitude: cpLat,
        centerLongitude: cpLon,
        radiusMeters: 1000.0,
        isRestricted: true,
      );

      final now = DateTime.now();
      final breachingJourney = Journey(
        id: 'JRN-BREACH-1',
        localId: 'LOC-B1',
        clientOperationId: 'OP-B1',
        vehicleId: 'VEH-01',
        vehicleRegistration: 'DL01-AB-1234',
        vehicleModel: 'Toyota Innova',
        driverId: 'DRV-1',
        driverName: 'Driver A',
        officerId: 'USR-1',
        officerName: 'Officer A',
        department: 'Logistics',
        office: 'HQ',
        journeyDate: now,
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now,
        startLocation: 'Point A',
        destination: 'Point B',
        purpose: 'Transit',
        openingOdometer: 1000.0,
        closingOdometer: 1010.0,
        startLatitude: cpLat, // Starts inside the restricted circle!
        startLongitude: cpLon,
        createdAt: now,
        updatedAt: now,
      );

      final result = GeofenceService.evaluateJourney(
        journey: breachingJourney,
        zones: [restrictedZone],
      );

      expect(result.hasViolation, isTrue);
      expect(result.violatedZoneNames, contains('High Security Perimeter'));
    });

    testWidgets('AQIL: GeofenceStatusCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const zone = GeofenceZone(
        id: 'Z1',
        name: 'HQ Campus',
        type: GeofenceType.headquarters,
        centerLatitude: 28.6315,
        centerLongitude: 77.2167,
        radiusMeters: 500,
      );

      const evalResult = GeofenceEvaluationResult(
        hasViolation: false,
        violatedZoneNames: [],
        activeZoneNames: ['HQ Campus'],
        summary: 'Route verified: Compliant within authorized perimeters',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(12),
              child: GeofenceStatusCard(
                result: evalResult,
                zones: [zone],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GeofenceStatusCard), findsOneWidget);
      expect(find.text('Geofence & Boundary Audit'), findsOneWidget);
    });

    testWidgets('AQIL: GeofenceStatusCard scales gracefully under 1.5x dynamic font scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const zone = GeofenceZone(
        id: 'Z1',
        name: 'HQ Campus',
        type: GeofenceType.headquarters,
        centerLatitude: 28.6315,
        centerLongitude: 77.2167,
        radiusMeters: 500,
      );

      const evalResult = GeofenceEvaluationResult(
        hasViolation: true,
        violatedZoneNames: ['Restricted Military Zone'],
        activeZoneNames: [],
        summary: 'Alert: Vehicle breached 1 restricted zone(s): Restricted Military Zone',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: GeofenceStatusCard(
                    result: evalResult,
                    zones: [zone],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GeofenceStatusCard), findsOneWidget);
    });
  });
}
