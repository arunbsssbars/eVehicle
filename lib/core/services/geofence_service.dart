import 'dart:math';
import '../models/geofence_zone.dart';
import '../models/journey.dart';

/// Autonomous calculation engine for geofencing, ray-casting polygon boundary checks, and breach auditing.
class GeofenceService {
  /// Earth's mean radius in meters
  static const double earthRadiusMeters = 6371000.0;

  /// Calculate great-circle distance between two coordinates using the Haversine formula
  static double calculateDistanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180.0);

  /// Check if a point (lat, lon) is inside a circular geofence
  static bool isInsideCircle({
    required double lat,
    required double lon,
    required double centerLat,
    required double centerLon,
    required double radiusMeters,
  }) {
    final distance = calculateDistanceMeters(
      lat1: lat,
      lon1: lon,
      lat2: centerLat,
      lon2: centerLon,
    );
    return distance <= radiusMeters;
  }

  /// Ray-casting algorithm to determine if a point is inside a polygon (Jordan Curve Theorem)
  static bool isPointInPolygon({
    required double lat,
    required double lon,
    required List<GeoCoordinate> vertices,
  }) {
    if (vertices.length < 3) return false;

    bool inside = false;
    int j = vertices.length - 1;

    for (int i = 0; i < vertices.length; i++) {
      final xi = vertices[i].longitude;
      final yi = vertices[i].latitude;
      final xj = vertices[j].longitude;
      final yj = vertices[j].latitude;

      final intersect = ((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi);

      if (intersect) inside = !inside;
      j = i;
    }

    return inside;
  }

  /// Check if a coordinate is inside a given geofence zone
  static bool isCoordinateInZone(double lat, double lon, GeofenceZone zone) {
    if (!zone.isActive) return false;

    if (zone.isPolygon) {
      return isPointInPolygon(
        lat: lat,
        lon: lon,
        vertices: zone.polygonVertices,
      );
    } else {
      return isInsideCircle(
        lat: lat,
        lon: lon,
        centerLat: zone.centerLatitude,
        centerLon: zone.centerLongitude,
        radiusMeters: zone.radiusMeters,
      );
    }
  }

  /// Evaluate journey waypoints and start/destination points against active geofences
  static GeofenceEvaluationResult evaluateJourney({
    required Journey journey,
    required List<GeofenceZone> zones,
  }) {
    if (zones.isEmpty) {
      return const GeofenceEvaluationResult(
        hasViolation: false,
        violatedZoneNames: [],
        activeZoneNames: [],
        summary: 'No active geofences defined',
      );
    }

    final violated = <String>{};
    final activeEncountered = <String>{};

    // Gather points to test
    final pointsToTest = <GeoCoordinate>[];
    if (journey.startLatitude != null && journey.startLongitude != null) {
      pointsToTest.add(GeoCoordinate(journey.startLatitude!, journey.startLongitude!));
    }
    if (journey.endLatitude != null && journey.endLongitude != null) {
      pointsToTest.add(GeoCoordinate(journey.endLatitude!, journey.endLongitude!));
    }
    for (final p in journey.routePoints) {
      pointsToTest.add(GeoCoordinate(p.latitude, p.longitude));
    }

    if (pointsToTest.isEmpty) {
      return const GeofenceEvaluationResult(
        hasViolation: false,
        violatedZoneNames: [],
        activeZoneNames: [],
        summary: 'No GPS telemetry available for geofence verification',
      );
    }

    for (final point in pointsToTest) {
      for (final zone in zones) {
        if (!zone.isActive) continue;

        final isInside = isCoordinateInZone(point.latitude, point.longitude, zone);
        if (isInside) {
          if (zone.isRestricted) {
            violated.add(zone.name);
          } else {
            activeEncountered.add(zone.name);
          }
        }
      }
    }

    final hasViolation = violated.isNotEmpty;
    final summary = hasViolation
        ? 'Alert: Vehicle breached ${violated.length} restricted zone(s): ${violated.join(', ')}'
        : 'Route verified: Compliant within ${activeEncountered.length} authorized perimeters';

    return GeofenceEvaluationResult(
      hasViolation: hasViolation,
      violatedZoneNames: violated.toList(),
      activeZoneNames: activeEncountered.toList(),
      summary: summary,
    );
  }
}
