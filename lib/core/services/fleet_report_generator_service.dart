import '../models/fleet_executive_report.dart';

/// Service responsible for aggregating fleet telemetry, safety incidents,
/// maintenance alerts, and fuel costs into structured executive briefings.
class FleetReportGeneratorService {
  /// Generate an executive fleet briefing
  static FleetExecutiveReport generateBriefing({
    required String id,
    required FleetReportType type,
    required String dateRangeLabel,
    required int totalVehicles,
    required int activeVehicles,
    required double totalDistanceKm,
    required double totalFuelSpend,
    required int safetyIncidentCount,
    required int pendingMaintenanceAlerts,
    DateTime? generatedAt,
  }) {
    final effectiveGeneratedAt = generatedAt ?? DateTime.now();

    // Utilization calculation
    final double utilization = totalVehicles > 0
        ? ((activeVehicles / totalVehicles) * 100.0).clamp(0.0, 100.0)
        : 0.0;

    // Cost Per Km calculation
    final double cpk = totalDistanceKm > 0
        ? (totalFuelSpend / totalDistanceKm)
        : 0.0;

    // Compliance & Safety Scoring (100 base, penalize incidents and neglected maintenance)
    double compliance = 100.0;
    compliance -= (safetyIncidentCount * 8.0);
    compliance -= (pendingMaintenanceAlerts * 4.0);
    compliance = compliance.clamp(0.0, 100.0);

    // Dynamic executive highlights
    final highlights = <String>[];
    highlights.add(
      'Fleet utilization at ${utilization.toStringAsFixed(1)}% with $activeVehicles of $totalVehicles vehicles operational.',
    );
    highlights.add(
      'Total distance traveled: ${totalDistanceKm.toStringAsFixed(0)} km with an average CPK of ₹${cpk.toStringAsFixed(2)}/km.',
    );

    if (safetyIncidentCount == 0) {
      highlights.add('Zero safety violations or speeding anomalies recorded in this cycle.');
    } else {
      highlights.add(
        '$safetyIncidentCount safety incidents or speeding events flagged for managerial review.',
      );
    }

    if (pendingMaintenanceAlerts > 0) {
      highlights.add(
        '$pendingMaintenanceAlerts vehicle(s) require scheduled service or defect resolution.',
      );
    } else {
      highlights.add('All vehicle preventive maintenance and DVIR checklists fully resolved.');
    }

    return FleetExecutiveReport(
      id: id,
      type: type,
      generatedAt: effectiveGeneratedAt,
      dateRangeLabel: dateRangeLabel,
      totalVehicles: totalVehicles,
      activeVehicles: activeVehicles,
      totalDistanceKm: totalDistanceKm,
      totalFuelSpend: totalFuelSpend,
      averageCpk: cpk,
      safetyIncidentCount: safetyIncidentCount,
      pendingMaintenanceAlerts: pendingMaintenanceAlerts,
      fleetUtilizationPercent: utilization,
      complianceScore: compliance,
      highlights: highlights,
    );
  }

  /// Formats structured report into clean text document suitable for PDF or plain-text sharing
  static String exportStructuredBriefingText(FleetExecutiveReport report) {
    final buffer = StringBuffer();
    buffer.writeln('==============================================');
    buffer.writeln('    FLEET EXECUTIVE BRIEFING: ${report.type.label.toUpperCase()}');
    buffer.writeln('==============================================');
    buffer.writeln('Report ID: ${report.id}');
    buffer.writeln('Period: ${report.dateRangeLabel}');
    buffer.writeln('Generated: ${report.generatedAt.toIso8601String()}');
    buffer.writeln('----------------------------------------------');
    buffer.writeln('OPERATIONAL METRICS');
    buffer.writeln('Total Fleet Size: ${report.totalVehicles} units');
    buffer.writeln('Active Vehicles: ${report.activeVehicles} (${report.fleetUtilizationPercent.toStringAsFixed(1)}%)');
    buffer.writeln('Total Distance: ${report.totalDistanceKm.toStringAsFixed(1)} km');
    buffer.writeln('Total Fuel Spend: ₹${report.totalFuelSpend.toStringAsFixed(2)}');
    buffer.writeln('Average CPK: ₹${report.averageCpk.toStringAsFixed(2)}/km');
    buffer.writeln('Safety Incidents: ${report.safetyIncidentCount}');
    buffer.writeln('Pending Alerts: ${report.pendingMaintenanceAlerts}');
    buffer.writeln('Compliance Score: ${report.complianceScore.toStringAsFixed(1)} / 100.0');
    buffer.writeln('----------------------------------------------');
    buffer.writeln('EXECUTIVE HIGHLIGHTS');
    for (final highlight in report.highlights) {
      buffer.writeln('• $highlight');
    }
    buffer.writeln('==============================================');
    return buffer.toString();
  }
}
