import 'dart:math';
import '../models/journey.dart';
import 'geofence_service.dart';

/// Instantaneous state of journey route playback
class RoutePlaybackState {
  final int currentPointIndex;
  final JourneyLocationPoint currentPoint;
  final double progress; // 0.0 to 1.0
  final double distanceTraveledKm;
  final double totalDistanceKm;
  final Duration elapsedTime;
  final Duration totalDuration;
  final double speedKmH;
  final double bearingDegrees; // 0 - 360

  const RoutePlaybackState({
    required this.currentPointIndex,
    required this.currentPoint,
    required this.progress,
    required this.distanceTraveledKm,
    required this.totalDistanceKm,
    required this.elapsedTime,
    required this.totalDuration,
    required this.speedKmH,
    required this.bearingDegrees,
  });
}

/// Detected dwell/stop event along a route
class RouteStopEvent {
  final JourneyLocationPoint point;
  final Duration dwellDuration;
  final DateTime arrivedAt;
  final DateTime departedAt;

  const RouteStopEvent({
    required this.point,
    required this.dwellDuration,
    required this.arrivedAt,
    required this.departedAt,
  });
}

/// Service providing telemetry playback interpolation, bearing calculations, and stop detection
class JourneyPlaybackService {
  /// Calculate initial compass bearing from point 1 to point 2 (0° - 360°)
  static double calculateBearing({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLon = _deg2rad(lon2 - lon1);
    final phi1 = _deg2rad(lat1);
    final phi2 = _deg2rad(lat2);

    final y = sin(dLon) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLon);

    final radians = atan2(y, x);
    final degrees = (radians * 180.0 / pi + 360.0) % 360.0;
    return degrees;
  }

  static double _deg2rad(double deg) => deg * (pi / 180.0);

  /// Calculate cumulative distance of route points in kilometers
  static double calculateRouteDistanceKm(List<JourneyLocationPoint> points) {
    if (points.length < 2) return 0.0;
    double meters = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      meters += GeofenceService.calculateDistanceMeters(
        lat1: points[i].latitude,
        lon1: points[i].longitude,
        lat2: points[i + 1].latitude,
        lon2: points[i + 1].longitude,
      );
    }
    return meters / 1000.0;
  }

  /// Get playback state at normalized progress [0.0, 1.0]
  static RoutePlaybackState getPlaybackState({
    required List<JourneyLocationPoint> routePoints,
    required double progress,
  }) {
    final clamped = progress.clamp(0.0, 1.0);

    if (routePoints.isEmpty) {
      final dummy = JourneyLocationPoint(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
      );
      return RoutePlaybackState(
        currentPointIndex: 0,
        currentPoint: dummy,
        progress: clamped,
        distanceTraveledKm: 0.0,
        totalDistanceKm: 0.0,
        elapsedTime: Duration.zero,
        totalDuration: Duration.zero,
        speedKmH: 0.0,
        bearingDegrees: 0.0,
      );
    }

    if (routePoints.length == 1) {
      return RoutePlaybackState(
        currentPointIndex: 0,
        currentPoint: routePoints.first,
        progress: clamped,
        distanceTraveledKm: 0.0,
        totalDistanceKm: 0.0,
        elapsedTime: Duration.zero,
        totalDuration: Duration.zero,
        speedKmH: routePoints.first.speed != null ? (routePoints.first.speed! * 3.6) : 0.0,
        bearingDegrees: 0.0,
      );
    }

    final totalDuration = routePoints.last.timestamp.difference(routePoints.first.timestamp);
    final totalDistance = calculateRouteDistanceKm(routePoints);

    // Approximate point index by progress
    final targetIndex = ((routePoints.length - 1) * clamped).round();
    final currentPoint = routePoints[targetIndex];

    // Distance traveled up to targetIndex
    final traveledDistance = calculateRouteDistanceKm(routePoints.sublist(0, targetIndex + 1));
    final elapsedTime = currentPoint.timestamp.difference(routePoints.first.timestamp);

    // Bearing
    double bearing = 0.0;
    if (targetIndex < routePoints.length - 1) {
      bearing = calculateBearing(
        lat1: currentPoint.latitude,
        lon1: currentPoint.longitude,
        lat2: routePoints[targetIndex + 1].latitude,
        lon2: routePoints[targetIndex + 1].longitude,
      );
    } else if (targetIndex > 0) {
      bearing = calculateBearing(
        lat1: routePoints[targetIndex - 1].latitude,
        lon1: routePoints[targetIndex - 1].longitude,
        lat2: currentPoint.latitude,
        lon2: currentPoint.longitude,
      );
    }

    final speedKmH = currentPoint.speed != null ? (currentPoint.speed! * 3.6) : 0.0;

    return RoutePlaybackState(
      currentPointIndex: targetIndex,
      currentPoint: currentPoint,
      progress: clamped,
      distanceTraveledKm: traveledDistance,
      totalDistanceKm: totalDistance,
      elapsedTime: elapsedTime,
      totalDuration: totalDuration,
      speedKmH: speedKmH,
      bearingDegrees: bearing,
    );
  }

  /// Detect stops/dwell locations where vehicle remained within [radiusMeters] for >= [minStopDuration]
  static List<RouteStopEvent> detectRouteStops(
    List<JourneyLocationPoint> points, {
    double radiusMeters = 35.0,
    Duration minStopDuration = const Duration(minutes: 3),
  }) {
    if (points.length < 2) return const [];

    final stops = <RouteStopEvent>[];
    int startIdx = 0;

    for (int i = 1; i < points.length; i++) {
      final dist = GeofenceService.calculateDistanceMeters(
        lat1: points[startIdx].latitude,
        lon1: points[startIdx].longitude,
        lat2: points[i].latitude,
        lon2: points[i].longitude,
      );

      if (dist > radiusMeters) {
        // Vehicle moved out of cluster
        final dwell = points[i - 1].timestamp.difference(points[startIdx].timestamp);
        if (dwell >= minStopDuration) {
          stops.add(RouteStopEvent(
            point: points[startIdx],
            dwellDuration: dwell,
            arrivedAt: points[startIdx].timestamp,
            departedAt: points[i - 1].timestamp,
          ));
        }
        startIdx = i;
      }
    }

    return stops;
  }
}
