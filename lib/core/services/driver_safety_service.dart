import 'dart:math';
import '../models/journey.dart';
import '../models/vehicle.dart';

/// Performance tier classification for drivers
enum DriverTier {
  platinum('Platinum Master', 0xFF10B981, 'Mastery of road safety and efficiency'),
  gold('Gold Pro', 0xFF3B82F6, 'Consistent safe and eco-friendly driving'),
  silver('Silver Safe', 0xFFF59E0B, 'Standard compliant driving with minor room for improvement'),
  needsCoaching('Needs Coaching', 0xFFEF4444, 'Requires driver education on speed and braking');

  final String title;
  final int colorValue;
  final String description;

  const DriverTier(this.title, this.colorValue, this.description);
}

/// Comprehensive safety and eco metrics for an individual driver
class DriverSafetyProfile {
  final String driverId;
  final String driverName;
  final int totalJourneys;
  final double totalDistanceKm;
  final double totalHoursLogged;
  final double safetyScore; // 0 - 100
  final double ecoScore; // 0 - 100
  final double compositeScore; // 0 - 100
  final DriverTier tier;
  final List<String> badges;

  const DriverSafetyProfile({
    required this.driverId,
    required this.driverName,
    required this.totalJourneys,
    required this.totalDistanceKm,
    required this.totalHoursLogged,
    required this.safetyScore,
    required this.ecoScore,
    required this.compositeScore,
    required this.tier,
    required this.badges,
  });
}

/// Leaderboard item for driver ranking
class DriverLeaderboardEntry {
  final int rank;
  final DriverSafetyProfile profile;

  const DriverLeaderboardEntry({
    required this.rank,
    required this.profile,
  });
}

/// Autonomous calculation engine for Driver Safety, Eco-Driving, and Fleet Leaderboards.
class DriverSafetyService {
  /// Calculate safety and performance profile for a driver based on their journey records
  static DriverSafetyProfile calculateDriverProfile({
    required String driverId,
    required String driverName,
    required List<Journey> journeys,
    List<Vehicle> vehicles = const [],
  }) {
    final driverJourneys = journeys.where((j) => j.driverId == driverId || j.driverName == driverName).toList();

    if (driverJourneys.isEmpty) {
      return DriverSafetyProfile(
        driverId: driverId,
        driverName: driverName,
        totalJourneys: 0,
        totalDistanceKm: 0.0,
        totalHoursLogged: 0.0,
        safetyScore: 100.0,
        ecoScore: 100.0,
        compositeScore: 100.0,
        tier: DriverTier.gold,
        badges: const ['New Driver'],
      );
    }

    double totalKm = 0.0;
    double totalMinutes = 0.0;
    int harshSpeedEvents = 0;
    int rapidDurationEvents = 0;

    for (final j in driverJourneys) {
      final closing = j.closingOdometer ?? j.openingOdometer;
      final distance = (j.officialDistance != null && j.officialDistance! > 0)
          ? j.officialDistance!
          : (closing - j.openingOdometer);
      final km = distance > 0 ? distance : 0.0;
      totalKm += km;

      final endTime = j.endTime ?? j.startTime.add(const Duration(hours: 1));
      final durationMinutes = endTime.difference(j.startTime).inMinutes;
      final effectiveMinutes = durationMinutes > 0 ? durationMinutes : 1;
      totalMinutes += effectiveMinutes;

      // Heuristic speed check: average speed > 90 km/h in Indian/city context triggers high speed caution
      final avgSpeedKmH = (km / (effectiveMinutes / 60.0));
      if (avgSpeedKmH > 95.0) {
        harshSpeedEvents++;
      }

      // Continuous long haul without rest (> 4.5 hours in a single journey)
      if (effectiveMinutes > 270) {
        rapidDurationEvents++;
      }
    }

    final totalHours = totalMinutes / 60.0;

    // Safety score calculation: base 100, deducted by speed penalties and fatigue violations
    double safetyDeduction = (harshSpeedEvents * 12.0) + (rapidDurationEvents * 8.0);
    // If distance is high without incidents, award bonus resiliency
    final reliabilityBonus = min(8.0, (totalKm / 1000.0) * 1.5);
    final calculatedSafety = (100.0 - safetyDeduction + reliabilityBonus).clamp(30.0, 100.0);

    // Eco score calculation: smooth pacing and consistency
    // If average speed is in the golden eco range (45 - 75 km/h), score is maximized
    final fleetAvgSpeed = totalHours > 0 ? (totalKm / totalHours) : 50.0;
    double ecoScore = 95.0;
    if (fleetAvgSpeed > 80.0) {
      ecoScore -= (fleetAvgSpeed - 80.0) * 1.2;
    } else if (fleetAvgSpeed < 30.0) {
      ecoScore -= (30.0 - fleetAvgSpeed) * 0.8;
    }
    ecoScore = ecoScore.clamp(40.0, 100.0);

    // Composite: 65% Safety + 35% Eco
    final composite = (0.65 * calculatedSafety) + (0.35 * ecoScore);

    // Tier
    final DriverTier tier;
    if (composite >= 90.0) {
      tier = DriverTier.platinum;
    } else if (composite >= 80.0) {
      tier = DriverTier.gold;
    } else if (composite >= 68.0) {
      tier = DriverTier.silver;
    } else {
      tier = DriverTier.needsCoaching;
    }

    // Badges
    final badges = <String>[];
    if (composite >= 90.0) badges.add('Safety Champion');
    if (totalKm >= 2000.0) badges.add('Road Veteran');
    if (harshSpeedEvents == 0 && driverJourneys.length >= 5) badges.add('Zero Infractions');
    if (ecoScore >= 88.0) badges.add('Eco Pioneer');
    if (badges.isEmpty) badges.add('Safe Commuter');

    return DriverSafetyProfile(
      driverId: driverId,
      driverName: driverName,
      totalJourneys: driverJourneys.length,
      totalDistanceKm: totalKm,
      totalHoursLogged: totalHours,
      safetyScore: double.parse(calculatedSafety.toStringAsFixed(1)),
      ecoScore: double.parse(ecoScore.toStringAsFixed(1)),
      compositeScore: double.parse(composite.toStringAsFixed(1)),
      tier: tier,
      badges: badges,
    );
  }

  /// Produce a sorted leaderboard of all drivers across the fleet
  static List<DriverLeaderboardEntry> rankDrivers({
    required List<Journey> journeys,
    List<Vehicle> vehicles = const [],
  }) {
    final driverMap = <String, String>{}; // id -> name
    for (final j in journeys) {
      if (j.driverId.isNotEmpty) {
        driverMap[j.driverId] = j.driverName.isNotEmpty ? j.driverName : 'Driver ${j.driverId}';
      }
    }

    if (driverMap.isEmpty) return const [];

    final profiles = <DriverSafetyProfile>[];
    for (final entry in driverMap.entries) {
      final profile = calculateDriverProfile(
        driverId: entry.key,
        driverName: entry.value,
        journeys: journeys,
        vehicles: vehicles,
      );
      profiles.add(profile);
    }

    // Sort descending by composite score, then by total distance
    profiles.sort((a, b) {
      final comp = b.compositeScore.compareTo(a.compositeScore);
      if (comp != 0) return comp;
      return b.totalDistanceKm.compareTo(a.totalDistanceKm);
    });

    final leaderboard = <DriverLeaderboardEntry>[];
    for (int i = 0; i < profiles.length; i++) {
      leaderboard.add(DriverLeaderboardEntry(
        rank: i + 1,
        profile: profiles[i],
      ));
    }

    return leaderboard;
  }
}
