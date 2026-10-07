import '../models/fleet_scorecard_index.dart';

/// Autonomous calculation service generating high-level enterprise fleet scorecards
class FleetScorecardService {
  /// Calculate composite index and determine executive grade and recommendations
  static FleetScorecardIndex calculateScorecard({
    required double safetyScore,
    required double esgGreenScore,
    required double maintenanceReliabilityScore,
    required double regulatoryComplianceScore,
  }) {
    final clampedSafety = safetyScore.clamp(0.0, 100.0);
    final clampedEsg = esgGreenScore.clamp(0.0, 100.0);
    final clampedMaintenance = maintenanceReliabilityScore.clamp(0.0, 100.0);
    final clampedCompliance = regulatoryComplianceScore.clamp(0.0, 100.0);

    // Composite weighted formula:
    // Safety: 35%, Maintenance: 25%, Compliance: 25%, ESG: 15%
    final double composite = (clampedSafety * 0.35) +
        (clampedMaintenance * 0.25) +
        (clampedCompliance * 0.25) +
        (clampedEsg * 0.15);

    // Letter Grade Assignment
    final FleetGrade grade;
    if (composite >= 90.0) {
      grade = FleetGrade.aPlus;
    } else if (composite >= 80.0) {
      grade = FleetGrade.a;
    } else if (composite >= 70.0) {
      grade = FleetGrade.b;
    } else if (composite >= 60.0) {
      grade = FleetGrade.c;
    } else {
      grade = FleetGrade.needsAttention;
    }

    // Dynamic strategic recommendations
    final recommendations = <String>[];

    if (clampedSafety < 80.0) {
      recommendations.add(
        'Implement driver fatigue and speeding remediation workshops to curb safety violations.',
      );
    }
    if (clampedMaintenance < 80.0) {
      recommendations.add(
        'Accelerate pre-trip DVIR defect rectification to prevent roadside vehicle groundings.',
      );
    }
    if (clampedCompliance < 85.0) {
      recommendations.add(
        'Renew approaching insurance policies and reconcile unmatched FASTag toll charges.',
      );
    }
    if (clampedEsg < 75.0) {
      recommendations.add(
        'Optimize route dispatch to minimize vehicle idling and reduce fleet carbon footprint.',
      );
    }
    if (recommendations.isEmpty) {
      recommendations.add(
        'Outstanding fleet operations: Maintain current maintenance cadence and driver safety standards.',
      );
    }

    return FleetScorecardIndex(
      safetyScore: clampedSafety,
      esgGreenScore: clampedEsg,
      maintenanceReliabilityScore: clampedMaintenance,
      regulatoryComplianceScore: clampedCompliance,
      compositeScore: composite,
      grade: grade,
      strategicRecommendations: recommendations,
    );
  }
}
