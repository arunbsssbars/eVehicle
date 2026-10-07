/// Executive Fleet Performance Grade
enum FleetGrade {
  aPlus('A+', 'Pinnacle Enterprise Fleet', 0xFF16A34A),
  a('A', 'Industry Benchmark', 0xFF2563EB),
  b('B', 'Compliant Operational', 0xFF0284C7),
  c('C', 'Moderate Risk Flags', 0xFFEA580C),
  needsAttention('D', 'Critical Audit Required', 0xFFDC2626);

  final String letter;
  final String label;
  final int colorValue;
  const FleetGrade(this.letter, this.label, this.colorValue);
}

/// Comprehensive multi-dimensional fleet scorecard index
class FleetScorecardIndex {
  final double safetyScore; // 0.0 - 100.0
  final double esgGreenScore; // 0.0 - 100.0
  final double maintenanceReliabilityScore; // 0.0 - 100.0
  final double regulatoryComplianceScore; // 0.0 - 100.0
  final double compositeScore; // 0.0 - 100.0
  final FleetGrade grade;
  final List<String> strategicRecommendations;

  const FleetScorecardIndex({
    required this.safetyScore,
    required this.esgGreenScore,
    required this.maintenanceReliabilityScore,
    required this.regulatoryComplianceScore,
    required this.compositeScore,
    required this.grade,
    required this.strategicRecommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'safetyScore': safetyScore,
      'esgGreenScore': esgGreenScore,
      'maintenanceReliabilityScore': maintenanceReliabilityScore,
      'regulatoryComplianceScore': regulatoryComplianceScore,
      'compositeScore': compositeScore,
      'grade': grade.name,
      'strategicRecommendations': strategicRecommendations,
    };
  }

  factory FleetScorecardIndex.fromJson(Map<String, dynamic> json) {
    return FleetScorecardIndex(
      safetyScore: (json['safetyScore'] as num).toDouble(),
      esgGreenScore: (json['esgGreenScore'] as num).toDouble(),
      maintenanceReliabilityScore: (json['maintenanceReliabilityScore'] as num).toDouble(),
      regulatoryComplianceScore: (json['regulatoryComplianceScore'] as num).toDouble(),
      compositeScore: (json['compositeScore'] as num).toDouble(),
      grade: FleetGrade.values.firstWhere(
        (g) => g.name == json['grade'],
        orElse: () => FleetGrade.b,
      ),
      strategicRecommendations: (json['strategicRecommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
