import 'dart:math';

/// A scheduled stop in a multi-leg transport or delivery manifest.
class DispatchStop {
  final String id;
  final String title;
  final double latitude;
  final double longitude;
  final int dwellTimeMinutes;
  final bool isUrgent;

  const DispatchStop({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    this.dwellTimeMinutes = 15,
    this.isUrgent = false,
  });
}

/// Optimized route calculation result with distance and time savings.
class OptimizedItinerary {
  final List<DispatchStop> orderedStops;
  final double originalDistanceKm;
  final double optimizedDistanceKm;
  final double distanceSavedKm;
  final double percentageSaved;
  final int totalEstimatedMinutes;

  const OptimizedItinerary({
    required this.orderedStops,
    required this.originalDistanceKm,
    required this.optimizedDistanceKm,
    required this.distanceSavedKm,
    required this.percentageSaved,
    required this.totalEstimatedMinutes,
  });
}

/// Enterprise Multi-Leg Route Optimizer & Dynamic Dispatch Sequencer.
class RouteDispatchService {
  const RouteDispatchService();

  /// Calculates Haversine spherical distance between two coordinates in kilometers.
  double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  /// Optimizes stop sequence using greedy nearest-neighbor with priority weighting.
  OptimizedItinerary optimizeRoute({
    required double originLat,
    required double originLon,
    required List<DispatchStop> stops,
    double averageSpeedKmph = 40.0,
  }) {
    if (stops.isEmpty) {
      return const OptimizedItinerary(
        orderedStops: [],
        originalDistanceKm: 0.0,
        optimizedDistanceKm: 0.0,
        distanceSavedKm: 0.0,
        percentageSaved: 0.0,
        totalEstimatedMinutes: 0,
      );
    }

    // Original unoptimized distance calculation
    double originalDist = 0.0;
    double curLat = originLat;
    double curLon = originLon;
    for (final s in stops) {
      originalDist += calculateDistanceKm(curLat, curLon, s.latitude, s.longitude);
      curLat = s.latitude;
      curLon = s.longitude;
    }

    // Optimization: separate urgent stops first, then nearest neighbor
    final remaining = List<DispatchStop>.from(stops);
    final ordered = <DispatchStop>[];
    curLat = originLat;
    curLon = originLon;

    while (remaining.isNotEmpty) {
      // Find urgent stops first
      final urgentCandidates = remaining.where((s) => s.isUrgent).toList();
      final pool = urgentCandidates.isNotEmpty ? urgentCandidates : remaining;

      DispatchStop? bestStop;
      double bestDist = double.infinity;

      for (final s in pool) {
        final d = calculateDistanceKm(curLat, curLon, s.latitude, s.longitude);
        if (d < bestDist) {
          bestDist = d;
          bestStop = s;
        }
      }

      if (bestStop != null) {
        ordered.add(bestStop);
        remaining.remove(bestStop);
        curLat = bestStop.latitude;
        curLon = bestStop.longitude;
      }
    }

    // Compute optimized distance
    double optDist = 0.0;
    curLat = originLat;
    curLon = originLon;
    int totalDwell = 0;

    for (final s in ordered) {
      optDist += calculateDistanceKm(curLat, curLon, s.latitude, s.longitude);
      totalDwell += s.dwellTimeMinutes;
      curLat = s.latitude;
      curLon = s.longitude;
    }

    final savedKm = max(0.0, originalDist - optDist);
    final pctSaved = originalDist > 0 ? (savedKm / originalDist) * 100.0 : 0.0;
    final drivingMinutes = (optDist / (averageSpeedKmph > 0 ? averageSpeedKmph : 40.0)) * 60.0;
    final totalMinutes = (drivingMinutes + totalDwell).round();

    return OptimizedItinerary(
      orderedStops: ordered,
      originalDistanceKm: double.parse(originalDist.toStringAsFixed(1)),
      optimizedDistanceKm: double.parse(optDist.toStringAsFixed(1)),
      distanceSavedKm: double.parse(savedKm.toStringAsFixed(1)),
      percentageSaved: double.parse(pctSaved.toStringAsFixed(1)),
      totalEstimatedMinutes: totalMinutes,
    );
  }
}
