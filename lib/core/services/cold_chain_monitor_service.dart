import 'dart:math';

/// Cargo thermal category for cold chain compliance.
enum CargoCategory {
  deepFrozen, // -25°C to -18°C
  chilled, // 2°C to 8°C
  ambientControlled, // 15°C to 25°C
  strictPharma, // 2°C to 8°C (zero tolerance for >30min breach)
}

/// Severity classification of a cold chain excursion.
enum ExcursionSeverity {
  nominal,
  warning,
  critical,
}

/// A discrete reading from a vehicle reefer / temperature data logger.
class ReeferReading {
  final DateTime timestamp;
  final double temperatureCelsius;
  final double humidityPercent;
  final bool isDoorOpen;
  final bool isUnitRunning;

  const ReeferReading({
    required this.timestamp,
    required this.temperatureCelsius,
    required this.humidityPercent,
    this.isDoorOpen = false,
    this.isUnitRunning = true,
  });
}

/// Detailed record of a temperature breach excursion.
class ColdChainExcursion {
  final DateTime startTime;
  final DateTime endTime;
  final double peakTemperature;
  final int durationMinutes;
  final ExcursionSeverity severity;
  final String description;

  const ColdChainExcursion({
    required this.startTime,
    required this.endTime,
    required this.peakTemperature,
    required this.durationMinutes,
    required this.severity,
    required this.description,
  });
}

/// Consolidated audit summary of cold chain integrity across a journey.
class ColdChainAuditResult {
  final CargoCategory category;
  final double minTemperature;
  final double maxTemperature;
  final double averageTemperature;
  final int totalExcursionMinutes;
  final double spoilageRiskScore; // 0.0 (pristine) to 100.0 (total loss)
  final bool isCompliant;
  final List<ColdChainExcursion> excursions;
  final int doorOpenEventCount;

  const ColdChainAuditResult({
    required this.category,
    required this.minTemperature,
    required this.maxTemperature,
    required this.averageTemperature,
    required this.totalExcursionMinutes,
    required this.spoilageRiskScore,
    required this.isCompliant,
    required this.excursions,
    required this.doorOpenEventCount,
  });
}

/// Enterprise Cold Chain & Temperature Telemetry Monitoring Engine.
class ColdChainMonitorService {
  const ColdChainMonitorService();

  /// Returns acceptable temperature boundaries (min, max in Celsius).
  (double min, double max) getTemperatureRange(CargoCategory category) {
    switch (category) {
      case CargoCategory.deepFrozen:
        return (-25.0, -18.0);
      case CargoCategory.chilled:
        return (2.0, 8.0);
      case CargoCategory.ambientControlled:
        return (15.0, 25.0);
      case CargoCategory.strictPharma:
        return (2.0, 8.0);
    }
  }

  /// Evaluates reefer readings and yields a comprehensive cold-chain integrity audit.
  ColdChainAuditResult evaluateTelemetry({
    required List<ReeferReading> readings,
    required CargoCategory category,
  }) {
    if (readings.isEmpty) {
      return ColdChainAuditResult(
        category: category,
        minTemperature: 0,
        maxTemperature: 0,
        averageTemperature: 0,
        totalExcursionMinutes: 0,
        spoilageRiskScore: 0.0,
        isCompliant: true,
        excursions: const [],
        doorOpenEventCount: 0,
      );
    }

    final (minAllowed, maxAllowed) = getTemperatureRange(category);
    double minT = readings.first.temperatureCelsius;
    double maxT = readings.first.temperatureCelsius;
    double sumT = 0.0;
    int doorOpens = 0;

    List<ColdChainExcursion> excursions = [];
    DateTime? excursionStart;
    double peakTemp = 0.0;
    int currentExcursionMinutes = 0;

    for (int i = 0; i < readings.length; i++) {
      final r = readings[i];
      if (r.temperatureCelsius < minT) minT = r.temperatureCelsius;
      if (r.temperatureCelsius > maxT) maxT = r.temperatureCelsius;
      sumT += r.temperatureCelsius;

      if (r.isDoorOpen) doorOpens++;

      final isBreach = r.temperatureCelsius < minAllowed || r.temperatureCelsius > maxAllowed;

      if (isBreach) {
        excursionStart ??= r.timestamp;
        peakTemp = (excursions.isEmpty && currentExcursionMinutes == 0)
            ? r.temperatureCelsius
            : (r.temperatureCelsius > maxAllowed
                ? max(peakTemp, r.temperatureCelsius)
                : min(peakTemp, r.temperatureCelsius));
        currentExcursionMinutes += 5; // Default 5-min intervals
      } else {
        if (excursionStart != null) {
          final sev = _calculateSeverity(category, currentExcursionMinutes, peakTemp, maxAllowed, minAllowed);
          excursions.add(ColdChainExcursion(
            startTime: excursionStart,
            endTime: r.timestamp,
            peakTemperature: peakTemp,
            durationMinutes: currentExcursionMinutes,
            severity: sev,
            description: 'Breach of ${peakTemp.toStringAsFixed(1)}°C for $currentExcursionMinutes min',
          ));
          excursionStart = null;
          currentExcursionMinutes = 0;
        }
      }
    }

    // Trailing breach check
    if (excursionStart != null && currentExcursionMinutes > 0) {
      final sev = _calculateSeverity(category, currentExcursionMinutes, peakTemp, maxAllowed, minAllowed);
      excursions.add(ColdChainExcursion(
        startTime: excursionStart,
        endTime: readings.last.timestamp,
        peakTemperature: peakTemp,
        durationMinutes: currentExcursionMinutes,
        severity: sev,
        description: 'Breach of ${peakTemp.toStringAsFixed(1)}°C for $currentExcursionMinutes min',
      ));
    }

    final totalExcursionMins = excursions.fold<int>(0, (sum, e) => sum + e.durationMinutes);
    final avgT = sumT / readings.length;

    // Spoilage calculation
    double baseRisk = (totalExcursionMins / 60.0) * 15.0; // 15% per hour of breach
    if (category == CargoCategory.strictPharma) {
      baseRisk *= 2.5; // Pharma is highly sensitive
    }
    if (doorOpens > 5) {
      baseRisk += (doorOpens - 5) * 4.0;
    }
    final spoilageScore = baseRisk.clamp(0.0, 100.0);
    final isCompliant = excursions.every((e) => e.severity != ExcursionSeverity.critical) && spoilageScore < 20.0;

    return ColdChainAuditResult(
      category: category,
      minTemperature: double.parse(minT.toStringAsFixed(1)),
      maxTemperature: double.parse(maxT.toStringAsFixed(1)),
      averageTemperature: double.parse(avgT.toStringAsFixed(1)),
      totalExcursionMinutes: totalExcursionMins,
      spoilageRiskScore: double.parse(spoilageScore.toStringAsFixed(1)),
      isCompliant: isCompliant,
      excursions: excursions,
      doorOpenEventCount: doorOpens,
    );
  }

  ExcursionSeverity _calculateSeverity(
    CargoCategory category,
    int minutes,
    double peak,
    double maxA,
    double minA,
  ) {
    final delta = (peak > maxA) ? (peak - maxA) : (minA - peak);
    if (category == CargoCategory.strictPharma) {
      if (minutes >= 30 || delta > 3.0) return ExcursionSeverity.critical;
      return ExcursionSeverity.warning;
    }
    if (minutes >= 60 || delta > 6.0) return ExcursionSeverity.critical;
    if (minutes >= 20 || delta > 2.0) return ExcursionSeverity.warning;
    return ExcursionSeverity.nominal;
  }
}
