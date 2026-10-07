import '../models/journey.dart';
import '../models/toll_transaction.dart';
import 'geofence_service.dart';

/// Crossing event detected when a vehicle drives through a toll plaza's geofence
class DetectedTollCrossing {
  final TollPlaza plaza;
  final DateTime crossingTime;
  final double distanceToPlazaMeters;

  const DetectedTollCrossing({
    required this.plaza,
    required this.crossingTime,
    required this.distanceToPlazaMeters,
  });
}

/// Service that automates matching between route GPS location points and electronic FASTag toll debits
class SmartTollReconcilerService {
  /// Detect all toll plaza crossings along a recorded route
  static List<DetectedTollCrossing> detectTollCrossings({
    required List<JourneyLocationPoint> routePoints,
    required List<TollPlaza> plazas,
  }) {
    final crossings = <DetectedTollCrossing>[];
    final visitedPlazas = <String>{};

    for (final point in routePoints) {
      for (final plaza in plazas) {
        if (visitedPlazas.contains(plaza.id)) continue;

        final distance = GeofenceService.calculateDistanceMeters(
          lat1: point.latitude,
          lon1: point.longitude,
          lat2: plaza.latitude,
          lon2: plaza.longitude,
        );

        if (distance <= plaza.radiusMeters) {
          crossings.add(
            DetectedTollCrossing(
              plaza: plaza,
              crossingTime: point.timestamp,
              distanceToPlazaMeters: distance,
            ),
          );
          visitedPlazas.add(plaza.id);
        }
      }
    }

    return crossings;
  }

  /// Reconciles an electronic FASTag statement debit against GPS telemetry route points
  static TollReconciliationResult reconcileFastagTransaction({
    required FastagTransaction transaction,
    required List<JourneyLocationPoint> routePoints,
    required List<TollPlaza> plazas,
    Duration toleranceWindow = const Duration(minutes: 25),
  }) {
    final anomalies = <String>[];
    final detectedCrossings = detectTollCrossings(
      routePoints: routePoints,
      plazas: plazas,
    );

    // Look for matching toll plaza
    final matchingCrossing = detectedCrossings.where((c) {
      final isSamePlaza = c.plaza.id == transaction.plazaId ||
          c.plaza.name.toLowerCase() == transaction.plazaName.toLowerCase();
      final timeDiff = c.crossingTime.difference(transaction.timestamp).abs();
      return isSamePlaza && timeDiff <= toleranceWindow;
    }).firstOrNull;

    if (matchingCrossing == null) {
      anomalies.add(
        'Ghost FASTag Deduction: Vehicle GPS was not within ${transaction.plazaName} at ${transaction.timestamp}',
      );
      return TollReconciliationResult(
        isMatched: false,
        varianceAmount: transaction.deductedAmount,
        matchedPlazaName: null,
        crossingTime: null,
        flaggedAnomalies: anomalies,
      );
    }

    // Price check
    final standardFee = matchingCrossing.plaza.standardFee;
    final variance = transaction.deductedAmount - standardFee;

    if (variance.abs() > 5.0) {
      if (variance > 0) {
        anomalies.add(
          'Overcharge detected: Deducted ₹${transaction.deductedAmount.toStringAsFixed(0)} vs standard tariff ₹${standardFee.toStringAsFixed(0)}',
        );
      } else {
        anomalies.add(
          'Concession / Return trip discount applied: ₹${variance.abs().toStringAsFixed(0)} less than standard tariff',
        );
      }
    }

    return TollReconciliationResult(
      isMatched: true,
      varianceAmount: variance,
      matchedPlazaName: matchingCrossing.plaza.name,
      crossingTime: matchingCrossing.crossingTime,
      flaggedAnomalies: anomalies,
    );
  }
}
