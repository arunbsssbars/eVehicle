import 'dart:math';

/// Geographic waypoint coordinate.
class RoutePoint {
  final String locationName;
  final double latitude;
  final double longitude;

  const RoutePoint({
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });
}

/// Commercial vehicle empty return journey.
class ReturnTripRoute {
  final String vehicleId;
  final String registrationNumber;
  final RoutePoint origin;
  final RoutePoint destination;
  final DateTime returnDepartureTime;
  final double emptyDistanceKm;
  final double availablePayloadCapacityKg;
  final double availableVolumeCubicMeters;
  final double fuelEfficiencyKmPerLitre;

  const ReturnTripRoute({
    required this.vehicleId,
    required this.registrationNumber,
    required this.origin,
    required this.destination,
    required this.returnDepartureTime,
    required this.emptyDistanceKm,
    required this.availablePayloadCapacityKg,
    required this.availableVolumeCubicMeters,
    this.fuelEfficiencyKmPerLitre = 4.0, // Commercial truck baseline
  });
}

/// Available backhaul load seeking transport.
class AvailableBackhaulCargo {
  final String cargoId;
  final String shipperName;
  final RoutePoint pickupLocation;
  final RoutePoint dropoffLocation;
  final double weightKg;
  final double volumeCubicMeters;
  final double offeredFreightPayout; // in currency units
  final DateTime pickupWindowStart;
  final DateTime pickupWindowEnd;

  const AvailableBackhaulCargo({
    required this.cargoId,
    required this.shipperName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.weightKg,
    required this.volumeCubicMeters,
    required this.offeredFreightPayout,
    required this.pickupWindowStart,
    required this.pickupWindowEnd,
  });
}

/// Matched reverse logistics opportunity.
class BackhaulMatchOpportunity {
  final AvailableBackhaulCargo cargo;
  final double matchScore; // 0 to 100
  final double routeDeviationKm;
  final double netProfitGain;
  final double carbonAvoidedKg;
  final bool isFitApproved;

  const BackhaulMatchOpportunity({
    required this.cargo,
    required this.matchScore,
    required this.routeDeviationKm,
    required this.netProfitGain,
    required this.carbonAvoidedKg,
    required this.isFitApproved,
  });
}

/// Comprehensive reverse logistics matching summary.
class BackhaulMatchResult {
  final String vehicleId;
  final String registrationNumber;
  final double originalDeadheadKm;
  final double potentialRevenueYield;
  final double totalCarbonSavingsKg;
  final List<BackhaulMatchOpportunity> rankedOpportunities;

  const BackhaulMatchResult({
    required this.vehicleId,
    required this.registrationNumber,
    required this.originalDeadheadKm,
    required this.potentialRevenueYield,
    required this.totalCarbonSavingsKg,
    required this.rankedOpportunities,
  });

  bool get hasViableMatches => rankedOpportunities.any((m) => m.isFitApproved);
}

/// Intelligent Fleet Reverse Logistics & Empty-Mile Freight Matcher.
class ReverseLogisticsMatcherService {
  const ReverseLogisticsMatcherService();

  /// Matches empty return trips with available freight loads.
  BackhaulMatchResult matchReturnTrip({
    required ReturnTripRoute route,
    required List<AvailableBackhaulCargo> availableLoads,
    double dieselCostPerLitre = 90.0,
  }) {
    final List<BackhaulMatchOpportunity> opportunities = [];
    double bestRevenue = 0.0;
    double bestCo2 = 0.0;

    for (final load in availableLoads) {
      // 1. Capacity and volume checks
      final fitsWeight = load.weightKg <= route.availablePayloadCapacityKg;
      final fitsVolume = load.volumeCubicMeters <= route.availableVolumeCubicMeters;

      // 2. Spatial deviation calculation
      final pickupDeviationKm = _calculateDistanceKm(route.origin, load.pickupLocation);
      final dropoffDeviationKm = _calculateDistanceKm(route.destination, load.dropoffLocation);
      final totalDeviationKm = pickupDeviationKm + dropoffDeviationKm;

      // 3. Time feasibility check
      final timingFeasible = load.pickupWindowEnd.isAfter(route.returnDepartureTime);

      final isFit = fitsWeight && fitsVolume && timingFeasible && totalDeviationKm <= 50.0;

      // 4. Financial yield and carbon calculation
      // Fuel cost for deviation
      final extraLitres = totalDeviationKm / route.fuelEfficiencyKmPerLitre;
      final extraFuelCost = extraLitres * dieselCostPerLitre;
      final netProfit = load.offeredFreightPayout - extraFuelCost;

      // CO2 avoided: each km of deadhead freight consolidated eliminates ~2.68 kg CO2/L of diesel
      final savedLitres = (route.emptyDistanceKm - totalDeviationKm).clamp(0.0, route.emptyDistanceKm) / route.fuelEfficiencyKmPerLitre;
      final co2Saved = savedLitres * 2.68;

      // Match score calculation
      double score = 0.0;
      if (isFit) {
        score = 100.0 - (totalDeviationKm * 1.2);
        score = score.clamp(10.0, 100.0);
      } else {
        score = max(0.0, 40.0 - totalDeviationKm);
      }

      final opp = BackhaulMatchOpportunity(
        cargo: load,
        matchScore: double.parse(score.toStringAsFixed(1)),
        routeDeviationKm: double.parse(totalDeviationKm.toStringAsFixed(1)),
        netProfitGain: double.parse(netProfit.toStringAsFixed(2)),
        carbonAvoidedKg: double.parse(co2Saved.toStringAsFixed(1)),
        isFitApproved: isFit && netProfit > 0,
      );

      opportunities.add(opp);

      if (opp.isFitApproved && opp.netProfitGain > bestRevenue) {
        bestRevenue = opp.netProfitGain;
        bestCo2 = opp.carbonAvoidedKg;
      }
    }

    // Sort opportunities by highest match score
    opportunities.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return BackhaulMatchResult(
      vehicleId: route.vehicleId,
      registrationNumber: route.registrationNumber,
      originalDeadheadKm: route.emptyDistanceKm,
      potentialRevenueYield: double.parse(bestRevenue.toStringAsFixed(2)),
      totalCarbonSavingsKg: double.parse(bestCo2.toStringAsFixed(1)),
      rankedOpportunities: opportunities,
    );
  }

  double _calculateDistanceKm(RoutePoint a, RoutePoint b) {
    const r = 6371.0; // Earth radius in km
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final sinLat = sin(dLat / 2);
    final sinLon = sin(dLon / 2);

    final h = sinLat * sinLat +
        cos(_degToRad(a.latitude)) * cos(_degToRad(b.latitude)) * sinLon * sinLon;
    final c = 2 * atan2(sqrt(h), sqrt(1 - h));
    return r * c;
  }

  double _degToRad(double deg) => deg * (pi / 180.0);
}
