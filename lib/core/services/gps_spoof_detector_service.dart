import '../models/journey.dart';
import 'geofence_service.dart';

/// Telemetry security audit result for a journey's GPS route
class GpsAuditResult {
  final bool isSuspicious;
  final double anomalyScore; // 0 (Clean) - 100 (Blatant Mocking/Spoofing)
  final int teleportationJumpsCount;
  final bool zeroJitterDetected;
  final List<String> flaggedReasons;

  const GpsAuditResult({
    required this.isSuspicious,
    required this.anomalyScore,
    required this.teleportationJumpsCount,
    required this.zeroJitterDetected,
    required this.flaggedReasons,
  });
}

/// Service detecting simulated GPS routes, mock location providers, and teleportation outliers
class GpsSpoofDetectorService {
  /// Maximum plausible vehicle speed in meters per second (180 km/h = 50 m/s)
  static const double maxPlausibleSpeedMps = 50.0;

  /// Audit route points for mock location anomalies and teleportation jumps
  static GpsAuditResult evaluateRouteTelemetry(List<JourneyLocationPoint> points) {
    if (points.length < 3) {
      return const GpsAuditResult(
        isSuspicious: false,
        anomalyScore: 0.0,
        teleportationJumpsCount: 0,
        zeroJitterDetected: false,
        flaggedReasons: [],
      );
    }

    int teleportJumps = 0;
    final reasons = <String>[];
    int identicalCoordinateRepeats = 0;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      final seconds = p2.timestamp.difference(p1.timestamp).inSeconds;
      final effectiveSeconds = seconds > 0 ? seconds : 1;

      final distanceMeters = GeofenceService.calculateDistanceMeters(
        lat1: p1.latitude,
        lon1: p1.longitude,
        lat2: p2.latitude,
        lon2: p2.longitude,
      );

      final speedMps = distanceMeters / effectiveSeconds;

      // 1. Teleportation speed check (> 180 km/h jump)
      if (speedMps > maxPlausibleSpeedMps) {
        teleportJumps++;
      }

      // 2. Zero-jitter mock check (identical fractional coordinates with advancing timestamp)
      if (p1.latitude == p2.latitude && p1.longitude == p2.longitude && seconds > 5) {
        identicalCoordinateRepeats++;
      }
    }

    if (teleportJumps > 0) {
      reasons.add(
        '$teleportJumps teleportation anomaly(s) detected with impossible ground speed (>180 km/h)',
      );
    }

    // If more than 60% of points have zero jitter while vehicle allegedly traveling
    final bool zeroJitter = identicalCoordinateRepeats > (points.length * 0.5);
    if (zeroJitter) {
      reasons.add(
        'Zero GPS satellite jitter detected: Artificial coordinate interpolation',
      );
    }

    final double score = ((teleportJumps * 35.0) + (zeroJitter ? 40.0 : 0.0)).clamp(0.0, 100.0);
    final bool suspicious = score >= 35.0;

    return GpsAuditResult(
      isSuspicious: suspicious,
      anomalyScore: score,
      teleportationJumpsCount: teleportJumps,
      zeroJitterDetected: zeroJitter,
      flaggedReasons: reasons,
    );
  }
}
