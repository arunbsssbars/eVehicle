import 'dart:math';

/// Latitude and Longitude coordinate representation.
class GeoCoordinate {
  final double latitude;
  final double longitude;

  const GeoCoordinate({
    required this.latitude,
    required this.longitude,
  });
}

/// Geofence zone types.
enum GeofenceType {
  allowedOperatingArea,
  depotHomeBase,
  restrictedZone,
  noGoHazardZone,
}

/// Defined spatial geofence boundary.
class GeofenceZone {
  final String id;
  final String name;
  final GeofenceType type;
  final GeoCoordinate center;
  final double radiusMeters; // For radial fences
  final List<GeoCoordinate> polygonVertices; // For polygon fences
  final bool isPolygon;
  final int curfewStartHour; // e.g. 22 (10 PM)
  final int curfewEndHour; // e.g. 5 (5 AM)
  final bool hasCurfew;

  const GeofenceZone({
    required this.id,
    required this.name,
    required this.type,
    required this.center,
    this.radiusMeters = 500.0,
    this.polygonVertices = const [],
    this.isPolygon = false,
    this.curfewStartHour = 22,
    this.curfewEndHour = 5,
    this.hasCurfew = false,
  });
}

/// Breach severity level.
enum BreachSeverity {
  warning,
  critical,
  violation,
}

/// Triggered breach alarm details.
class BreachAlert {
  final String zoneId;
  final String zoneName;
  final BreachSeverity severity;
  final String reason;
  final DateTime timestamp;

  const BreachAlert({
    required this.zoneId,
    required this.zoneName,
    required this.severity,
    required this.reason,
    required this.timestamp,
  });
}

/// Geofence audit evaluation summary.
class GeofenceAuditResult {
  final String vehicleId;
  final GeoCoordinate currentLocation;
  final bool isInsideOperatingArea;
  final bool isInsideDepot;
  final bool isBreachingRestrictedZone;
  final bool isCurfewViolated;
  final List<BreachAlert> activeAlerts;

  const GeofenceAuditResult({
    required this.vehicleId,
    required this.currentLocation,
    required this.isInsideOperatingArea,
    required this.isInsideDepot,
    required this.isBreachingRestrictedZone,
    required this.isCurfewViolated,
    required this.activeAlerts,
  });
}

/// Real-Time Fleet Geofencing & Restricted Area Breach Alarm Engine.
class GeofenceBreachEngineService {
  const GeofenceBreachEngineService();

  /// Evaluates vehicle location against defined geofence zones.
  GeofenceAuditResult evaluateLocation({
    required String vehicleId,
    required GeoCoordinate location,
    required DateTime timestamp,
    required List<GeofenceZone> zones,
  }) {
    bool insideOperating = false;
    bool insideDepot = false;
    bool restrictedBreach = false;
    bool curfewViolated = false;
    final List<BreachAlert> alerts = [];

    for (final zone in zones) {
      final bool isInside = zone.isPolygon
          ? _isPointInPolygon(location, zone.polygonVertices)
          : _isPointInCircle(location, zone.center, zone.radiusMeters);

      switch (zone.type) {
        case GeofenceType.allowedOperatingArea:
          if (isInside) insideOperating = true;
          break;
        case GeofenceType.depotHomeBase:
          if (isInside) insideDepot = true;
          // Check curfew if not in depot during night
          if (zone.hasCurfew && !isInside) {
            final hour = timestamp.hour;
            final inCurfewWindow = (zone.curfewStartHour > zone.curfewEndHour)
                ? (hour >= zone.curfewStartHour || hour < zone.curfewEndHour)
                : (hour >= zone.curfewStartHour && hour < zone.curfewEndHour);

            if (inCurfewWindow) {
              curfewViolated = true;
              alerts.add(BreachAlert(
                zoneId: zone.id,
                zoneName: zone.name,
                severity: BreachSeverity.critical,
                reason: 'Curfew Violation: Vehicle outside authorized depot during restricted hours (${zone.curfewStartHour}:00 - ${zone.curfewEndHour}:00).',
                timestamp: timestamp,
              ));
            }
          }
          break;
        case GeofenceType.restrictedZone:
        case GeofenceType.noGoHazardZone:
          if (isInside) {
            restrictedBreach = true;
            alerts.add(BreachAlert(
              zoneId: zone.id,
              zoneName: zone.name,
              severity: zone.type == GeofenceType.noGoHazardZone
                  ? BreachSeverity.critical
                  : BreachSeverity.violation,
              reason: 'Unauthorized Intrusion: Vehicle entered ${zone.type == GeofenceType.noGoHazardZone ? 'Hazard No-Go' : 'Restricted'} Zone.',
              timestamp: timestamp,
            ));
          }
          break;
      }
    }

    // Check if vehicle is completely outside all authorized operational areas
    final hasOperatingZones = zones.any((z) => z.type == GeofenceType.allowedOperatingArea);
    if (hasOperatingZones && !insideOperating && !insideDepot) {
      alerts.add(BreachAlert(
        zoneId: 'out-of-bounds',
        zoneName: 'Authorized Fleet Operating Bounds',
        severity: BreachSeverity.warning,
        reason: 'Vehicle has deviated outside all designated operating territories.',
        timestamp: timestamp,
      ));
    }

    return GeofenceAuditResult(
      vehicleId: vehicleId,
      currentLocation: location,
      isInsideOperatingArea: insideOperating,
      isInsideDepot: insideDepot,
      isBreachingRestrictedZone: restrictedBreach,
      isCurfewViolated: curfewViolated,
      activeAlerts: alerts,
    );
  }

  /// Haversine distance formula to check circular geofences.
  bool _isPointInCircle(GeoCoordinate point, GeoCoordinate center, double radiusMeters) {
    const earthRadiusM = 6371000.0;
    final dLat = _degreesToRadians(point.latitude - center.latitude);
    final dLon = _degreesToRadians(point.longitude - center.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(center.latitude)) *
            cos(_degreesToRadians(point.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distanceMeters = earthRadiusM * c;

    return distanceMeters <= radiusMeters;
  }

  /// Ray-casting algorithm to test point inclusion in arbitrary 2D polygon.
  bool _isPointInPolygon(GeoCoordinate point, List<GeoCoordinate> vertices) {
    if (vertices.length < 3) return false;

    bool isInside = false;
    int j = vertices.length - 1;

    for (int i = 0; i < vertices.length; i++) {
      final vi = vertices[i];
      final vj = vertices[j];

      final intersect = ((vi.latitude > point.latitude) != (vj.latitude > point.latitude)) &&
          (point.longitude <
              (vj.longitude - vi.longitude) *
                      (point.latitude - vi.latitude) /
                      (vj.latitude - vi.latitude) +
                  vi.longitude);

      if (intersect) isInside = !isInside;
      j = i;
    }

    return isInside;
  }

  double _degreesToRadians(double degrees) => degrees * (pi / 180.0);
}
