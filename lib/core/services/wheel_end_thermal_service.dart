
/// Axle position on vehicle or trailer.
enum AxlePosition {
  steer,
  drive,
  trailerLead,
  trailerTrail,
}

/// Dynamic tyre reading captured from wireless wheel-end sensors.
class WheelSensorReading {
  final String sensorId;
  final AxlePosition axle;
  final bool isLeft;
  final double pressurePsi;
  final double temperatureCelsius;
  final double baselinePressurePsi;

  const WheelSensorReading({
    required this.sensorId,
    required this.axle,
    required this.isLeft,
    required this.pressurePsi,
    required this.temperatureCelsius,
    required this.baselinePressurePsi,
  });

  /// Pressure variance percentage relative to cold baseline.
  double get pressureVariancePercent =>
      baselinePressurePsi > 0 ? ((pressurePsi - baselinePressurePsi) / baselinePressurePsi) * 100 : 0.0;
}

/// Alert severity for wheel-end faults.
enum WheelEndAlertSeverity {
  nominal,
  advisory,
  critical,
}

/// Result of thermal and pressure diagnostics across wheel ends.
class WheelEndDiagnosis {
  final AxlePosition axle;
  final bool isLeft;
  final WheelEndAlertSeverity severity;
  final String title;
  final String message;
  final double currentTemp;
  final double currentPressure;
  final bool isBearingLockoutRisk;

  const WheelEndDiagnosis({
    required this.axle,
    required this.isLeft,
    required this.severity,
    required this.title,
    required this.message,
    required this.currentTemp,
    required this.currentPressure,
    required this.isBearingLockoutRisk,
  });
}

/// Overall vehicle wheel-end thermal and TPMS evaluation result.
class WheelEndThermalResult {
  final String vehicleId;
  final DateTime timestamp;
  final List<WheelEndDiagnosis> anomalies;
  final double maxTemperatureCelsius;
  final double minPressurePsi;
  final bool hasCriticalBearingAlert;
  final bool hasUnderinflationAlert;
  final String summaryStatus;

  const WheelEndThermalResult({
    required this.vehicleId,
    required this.timestamp,
    required this.anomalies,
    required this.maxTemperatureCelsius,
    required this.minPressurePsi,
    required this.hasCriticalBearingAlert,
    required this.hasUnderinflationAlert,
    required this.summaryStatus,
  });

  bool get isSafe => !hasCriticalBearingAlert && anomalies.isEmpty;
}

/// Wheel-End Thermal & Bearing Hub Health Monitor Service.
class WheelEndThermalService {
  const WheelEndThermalService();

  // Safety thresholds
  static const double criticalTemperatureCelsius = 95.0; // Bearing grease breakdown temperature
  static const double advisoryTemperatureCelsius = 80.0;
  static const double lowPressureThresholdPercent = -20.0; // 20% below cold baseline
  static const double highPressureThresholdPercent = 30.0;  // Thermal expansion / overinflation

  WheelEndThermalResult evaluateWheelEnds({
    required String vehicleId,
    required List<WheelSensorReading> readings,
  }) {
    if (readings.isEmpty) {
      return WheelEndThermalResult(
        vehicleId: vehicleId,
        timestamp: DateTime.now(),
        anomalies: [],
        maxTemperatureCelsius: 0.0,
        minPressurePsi: 0.0,
        hasCriticalBearingAlert: false,
        hasUnderinflationAlert: false,
        summaryStatus: 'No sensor data available',
      );
    }

    final anomalies = <WheelEndDiagnosis>[];
    double maxTemp = 0.0;
    double minPressure = double.infinity;
    bool criticalBearing = false;
    bool underinflation = false;

    // Calculate axle temperature averages to detect single hub outliers
    final axleTemps = <AxlePosition, List<double>>{};
    for (final r in readings) {
      axleTemps.putIfAbsent(r.axle, () => []).add(r.temperatureCelsius);
      if (r.temperatureCelsius > maxTemp) maxTemp = r.temperatureCelsius;
      if (r.pressurePsi < minPressure) minPressure = r.pressurePsi;
    }

    for (final r in readings) {
      final side = r.isLeft ? 'Left' : 'Right';
      final axleName = r.axle.name.toUpperCase();

      // Check temperature vs axle average (Delta-T > 20°C across same axle indicates bearing friction)
      final siblings = axleTemps[r.axle] ?? [];
      final axleAvg = siblings.isNotEmpty ? siblings.reduce((a, b) => a + b) / siblings.length : r.temperatureCelsius;
      final deltaT = r.temperatureCelsius - axleAvg;

      if (r.temperatureCelsius >= criticalTemperatureCelsius || deltaT >= 25.0) {
        criticalBearing = true;
        anomalies.add(WheelEndDiagnosis(
          axle: r.axle,
          isLeft: r.isLeft,
          severity: WheelEndAlertSeverity.critical,
          title: '$axleName $side Bearing Thermal Runaway',
          message: 'Hub temperature reached ${r.temperatureCelsius.toStringAsFixed(1)}°C (ΔT ${deltaT.toStringAsFixed(1)}°C). Immediate stop required.',
          currentTemp: r.temperatureCelsius,
          currentPressure: r.pressurePsi,
          isBearingLockoutRisk: true,
        ));
      } else if (r.temperatureCelsius >= advisoryTemperatureCelsius) {
        anomalies.add(WheelEndDiagnosis(
          axle: r.axle,
          isLeft: r.isLeft,
          severity: WheelEndAlertSeverity.advisory,
          title: '$axleName $side Elevated Hub Temp',
          message: 'Hub temperature at ${r.temperatureCelsius.toStringAsFixed(1)}°C. Inspect wheel seals and brake dragging.',
          currentTemp: r.temperatureCelsius,
          currentPressure: r.pressurePsi,
          isBearingLockoutRisk: false,
        ));
      }

      // Check tyre pressure variance
      if (r.pressureVariancePercent <= lowPressureThresholdPercent) {
        underinflation = true;
        anomalies.add(WheelEndDiagnosis(
          axle: r.axle,
          isLeft: r.isLeft,
          severity: WheelEndAlertSeverity.advisory,
          title: '$axleName $side Severe Underinflation',
          message: 'Tyre pressure at ${r.pressurePsi.toStringAsFixed(1)} PSI (${r.pressureVariancePercent.toStringAsFixed(1)}% below cold baseline).',
          currentTemp: r.temperatureCelsius,
          currentPressure: r.pressurePsi,
          isBearingLockoutRisk: false,
        ));
      }
    }

    String summary;
    if (criticalBearing) {
      summary = 'CRITICAL: Wheel hub bearing overheat detected. Risk of wheel separation!';
    } else if (underinflation || anomalies.isNotEmpty) {
      summary = 'WARNING: Wheel-end anomalies detected. Review maintenance diagnostics.';
    } else {
      summary = 'All wheel ends operating within normal thermal & pressure limits.';
    }

    return WheelEndThermalResult(
      vehicleId: vehicleId,
      timestamp: DateTime.now(),
      anomalies: anomalies,
      maxTemperatureCelsius: maxTemp,
      minPressurePsi: minPressure == double.infinity ? 0.0 : minPressure,
      hasCriticalBearingAlert: criticalBearing,
      hasUnderinflationAlert: underinflation,
      summaryStatus: summary,
    );
  }
}
