/// A recorded vehicle idling session with operational classification.
class IdleSession {
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final bool isProductivePto; // Power Take-Off (e.g. concrete mixer, crane, reefer)
  final String locationTag;

  const IdleSession({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.isProductivePto = false,
    this.locationTag = 'Staging Area',
  });
}

/// Comprehensive audit of engine idling hours, wasted fuel, and carbon emissions.
class IdleWasteAudit {
  final double totalEngineHours;
  final double unproductiveIdleHours;
  final double productivePtoHours;
  final double idleRatioPercent; // Unproductive idle hours / total engine hours
  final double wastedFuelLiters;
  final double wastedCostUsd;
  final double excessCo2Kg; // ~2.68 kg CO2 per liter of diesel
  final String efficiencyGrade; // A, B, C, D, F
  final String recommendations;

  const IdleWasteAudit({
    required this.totalEngineHours,
    required this.unproductiveIdleHours,
    required this.productivePtoHours,
    required this.idleRatioPercent,
    required this.wastedFuelLiters,
    required this.wastedCostUsd,
    required this.excessCo2Kg,
    required this.efficiencyGrade,
    required this.recommendations,
  });
}

/// Enterprise Driver Idle Time & Auxiliary Equipment Power Consumption Engine.
class IdleWasteService {
  const IdleWasteService();

  /// Evaluates idle sessions and derives operational fuel waste and financial impact.
  IdleWasteAudit evaluateIdleTelemetry({
    required List<IdleSession> sessions,
    required double totalEngineHours,
    double idleFuelBurnLitersPerHour = 1.2, // Typical 4-6 cylinder commercial diesel idle
    double fuelPricePerLiter = 1.40,
  }) {
    if (totalEngineHours <= 0.0) {
      return const IdleWasteAudit(
        totalEngineHours: 0.0,
        unproductiveIdleHours: 0.0,
        productivePtoHours: 0.0,
        idleRatioPercent: 0.0,
        wastedFuelLiters: 0.0,
        wastedCostUsd: 0.0,
        excessCo2Kg: 0.0,
        efficiencyGrade: 'A',
        recommendations: 'No engine runtime telemetry recorded.',
      );
    }

    int unprodMins = 0;
    int ptoMins = 0;

    for (final s in sessions) {
      if (s.isProductivePto) {
        ptoMins += s.durationMinutes;
      } else {
        // Any stationary session > 3 minutes counts as unproductive idle
        if (s.durationMinutes >= 3) {
          unprodMins += s.durationMinutes;
        }
      }
    }

    final unprodHours = unprodMins / 60.0;
    final ptoHours = ptoMins / 60.0;
    final idleRatio = (unprodHours / totalEngineHours) * 100.0;
    final wastedLiters = unprodHours * idleFuelBurnLitersPerHour;
    final wastedCost = wastedLiters * fuelPricePerLiter;
    final co2 = wastedLiters * 2.68;

    String grade;
    String recommendation;

    if (idleRatio <= 8.0) {
      grade = 'A';
      recommendation = 'EXCELLENT: Idle duration strictly optimized under 8% benchmark.';
    } else if (idleRatio <= 15.0) {
      grade = 'B';
      recommendation = 'GOOD: Moderate idling; instruct drivers to cut engine during long load delays.';
    } else if (idleRatio <= 25.0) {
      grade = 'C';
      recommendation = 'FAIR: High idle ratio (${idleRatio.toStringAsFixed(1)}%). Install automated engine idle shutoff.';
    } else if (idleRatio <= 40.0) {
      grade = 'D';
      recommendation = 'POOR: Excessive idling detected. Significant fuel burn without distance.';
    } else {
      grade = 'F';
      recommendation = 'CRITICAL IDLE WASTE: Over 40% of runtime spent stationary idling.';
    }

    return IdleWasteAudit(
      totalEngineHours: double.parse(totalEngineHours.toStringAsFixed(1)),
      unproductiveIdleHours: double.parse(unprodHours.toStringAsFixed(1)),
      productivePtoHours: double.parse(ptoHours.toStringAsFixed(1)),
      idleRatioPercent: double.parse(idleRatio.clamp(0.0, 100.0).toStringAsFixed(1)),
      wastedFuelLiters: double.parse(wastedLiters.toStringAsFixed(1)),
      wastedCostUsd: double.parse(wastedCost.toStringAsFixed(2)),
      excessCo2Kg: double.parse(co2.toStringAsFixed(1)),
      efficiencyGrade: grade,
      recommendations: recommendation,
    );
  }
}
