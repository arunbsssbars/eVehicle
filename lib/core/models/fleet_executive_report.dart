enum FleetReportType {
  dailySnapshot('Daily Operational Snapshot'),
  weeklyExecutive('Weekly Fleet Executive Briefing'),
  monthlyAudit('Monthly Operational & Compliance Audit');

  final String label;
  const FleetReportType(this.label);
}

/// Structured data model representing an aggregated executive fleet briefing
class FleetExecutiveReport {
  final String id;
  final FleetReportType type;
  final DateTime generatedAt;
  final String dateRangeLabel;
  final int totalVehicles;
  final int activeVehicles;
  final double totalDistanceKm;
  final double totalFuelSpend;
  final double averageCpk;
  final int safetyIncidentCount;
  final int pendingMaintenanceAlerts;
  final double fleetUtilizationPercent;
  final double complianceScore; // 0.0 to 100.0
  final List<String> highlights;

  const FleetExecutiveReport({
    required this.id,
    required this.type,
    required this.generatedAt,
    required this.dateRangeLabel,
    required this.totalVehicles,
    required this.activeVehicles,
    required this.totalDistanceKm,
    required this.totalFuelSpend,
    required this.averageCpk,
    required this.safetyIncidentCount,
    required this.pendingMaintenanceAlerts,
    required this.fleetUtilizationPercent,
    required this.complianceScore,
    required this.highlights,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'generatedAt': generatedAt.toIso8601String(),
      'dateRangeLabel': dateRangeLabel,
      'totalVehicles': totalVehicles,
      'activeVehicles': activeVehicles,
      'totalDistanceKm': totalDistanceKm,
      'totalFuelSpend': totalFuelSpend,
      'averageCpk': averageCpk,
      'safetyIncidentCount': safetyIncidentCount,
      'pendingMaintenanceAlerts': pendingMaintenanceAlerts,
      'fleetUtilizationPercent': fleetUtilizationPercent,
      'complianceScore': complianceScore,
      'highlights': highlights,
    };
  }

  factory FleetExecutiveReport.fromJson(Map<String, dynamic> json) {
    return FleetExecutiveReport(
      id: json['id'] as String,
      type: FleetReportType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => FleetReportType.weeklyExecutive,
      ),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      dateRangeLabel: json['dateRangeLabel'] as String,
      totalVehicles: json['totalVehicles'] as int,
      activeVehicles: json['activeVehicles'] as int,
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      totalFuelSpend: (json['totalFuelSpend'] as num).toDouble(),
      averageCpk: (json['averageCpk'] as num).toDouble(),
      safetyIncidentCount: json['safetyIncidentCount'] as int,
      pendingMaintenanceAlerts: json['pendingMaintenanceAlerts'] as int,
      fleetUtilizationPercent: (json['fleetUtilizationPercent'] as num).toDouble(),
      complianceScore: (json['complianceScore'] as num).toDouble(),
      highlights: (json['highlights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
