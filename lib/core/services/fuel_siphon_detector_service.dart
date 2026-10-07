/// A discrete fuel level reading with engine state and location.
class FuelLevelReading {
  final DateTime timestamp;
  final double fuelLevelLiters;
  final bool isEngineRunning;
  final double speedKmph;
  final double latitude;
  final double longitude;

  const FuelLevelReading({
    required this.timestamp,
    required this.fuelLevelLiters,
    required this.isEngineRunning,
    this.speedKmph = 0.0,
    required this.latitude,
    required this.longitude,
  });
}

/// Recorded fuel theft / siphoning incident with forensic metadata.
class SiphonIncident {
  final DateTime timestamp;
  final double litersLost;
  final double financialLossUsd;
  final double latitude;
  final double longitude;
  final double durationMinutes;
  final int confidencePercent;

  const SiphonIncident({
    required this.timestamp,
    required this.litersLost,
    required this.financialLossUsd,
    required this.latitude,
    required this.longitude,
    required this.durationMinutes,
    required this.confidencePercent,
  });
}

/// Consolidated audit of vehicle fuel theft and siphoning anomalies.
class FuelTheftAudit {
  final bool hasTheftOccurred;
  final List<SiphonIncident> incidents;
  final double totalLitersLost;
  final double totalFinancialLossUsd;
  final String threatLevel; // LOW, ELEVATED, CRITICAL
  final String advisory;

  const FuelTheftAudit({
    required this.hasTheftOccurred,
    required this.incidents,
    required this.totalLitersLost,
    required this.totalFinancialLossUsd,
    required this.threatLevel,
    required this.advisory,
  });
}

/// Enterprise Fuel Theft & Sudden Siphon Anomaly Detector.
class FuelSiphonDetectorService {
  const FuelSiphonDetectorService();

  /// Scans fuel level time series to detect unauthorized siphoning while engine is off/stationary.
  FuelTheftAudit detectFuelTheft({
    required List<FuelLevelReading> readings,
    double fuelPricePerLiter = 1.35,
    double minSiphonLitersThreshold = 8.0,
  }) {
    if (readings.length < 2) {
      return const FuelTheftAudit(
        hasTheftOccurred: false,
        incidents: [],
        totalLitersLost: 0.0,
        totalFinancialLossUsd: 0.0,
        threatLevel: 'LOW',
        advisory: 'NOMINAL: Insufficient fuel telemetry to detect siphoning.',
      );
    }

    final incidents = <SiphonIncident>[];
    double totalLost = 0.0;

    for (int i = 0; i < readings.length - 1; i++) {
      final current = readings[i];
      final next = readings[i + 1];

      final durationMins = next.timestamp.difference(current.timestamp).inSeconds / 60.0;
      if (durationMins <= 0 || durationMins > 120.0) continue; // Skip stale gaps

      final fuelDelta = current.fuelLevelLiters - next.fuelLevelLiters;

      // Detection condition: Fuel dropped by at least threshold while engine was OFF or vehicle stationary
      final isStationaryOrOff = !current.isEngineRunning || (current.speedKmph < 2.0 && next.speedKmph < 2.0);

      if (fuelDelta >= minSiphonLitersThreshold && isStationaryOrOff) {
        // High confidence if engine was completely off
        final confidence = (!current.isEngineRunning && !next.isEngineRunning) ? 95 : 80;
        final financialLoss = fuelDelta * fuelPricePerLiter;

        incidents.add(SiphonIncident(
          timestamp: next.timestamp,
          litersLost: double.parse(fuelDelta.toStringAsFixed(1)),
          financialLossUsd: double.parse(financialLoss.toStringAsFixed(2)),
          latitude: next.latitude,
          longitude: next.longitude,
          durationMinutes: double.parse(durationMins.toStringAsFixed(1)),
          confidencePercent: confidence,
        ));

        totalLost += fuelDelta;
      }
    }

    final hasTheft = incidents.isNotEmpty;
    final totalLossVal = totalLost * fuelPricePerLiter;

    String threatLevel;
    String advisory;

    if (totalLost >= 40.0) {
      threatLevel = 'CRITICAL';
      advisory = 'SEVERE SIPHON EVENT: ${totalLost.toStringAsFixed(1)}L drained while parked. Possible organized fuel theft.';
    } else if (hasTheft) {
      threatLevel = 'ELEVATED';
      advisory = 'SIPHON DETECTED: Rapid fuel drop detected while vehicle was stationary.';
    } else {
      threatLevel = 'LOW';
      advisory = 'NOMINAL: No unauthorized fuel drops or siphoning anomalies detected.';
    }

    return FuelTheftAudit(
      hasTheftOccurred: hasTheft,
      incidents: incidents,
      totalLitersLost: double.parse(totalLost.toStringAsFixed(1)),
      totalFinancialLossUsd: double.parse(totalLossVal.toStringAsFixed(2)),
      threatLevel: threatLevel,
      advisory: advisory,
    );
  }
}
