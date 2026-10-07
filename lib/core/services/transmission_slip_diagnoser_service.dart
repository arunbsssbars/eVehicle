/// Transmission shift actuator and clutch telemetry reading.
class TransmissionClutchReading {
  final double engineSpeedRpm;
  final double transmissionInputShaftRpm;
  final double transmissionOutputShaftRpm;
  final int currentGear;
  final double clutchEngagementPercent; // 0% = disengaged, 100% = fully locked
  final double transmissionFluidTempCelsius;
  final double shiftEngagementLatencyMs;

  const TransmissionClutchReading({
    required this.engineSpeedRpm,
    required this.transmissionInputShaftRpm,
    required this.transmissionOutputShaftRpm,
    required this.currentGear,
    required this.clutchEngagementPercent,
    required this.transmissionFluidTempCelsius,
    required this.shiftEngagementLatencyMs,
  });

  /// Slip differential RPM between engine and transmission input shaft when engaged.
  double get clutchSlipRpm =>
      clutchEngagementPercent >= 90.0 ? (engineSpeedRpm - transmissionInputShaftRpm).abs() : 0.0;
}

/// Transmission and clutch operational health grade.
enum TransmissionHealthStatus {
  healthy,
  moderateSlipAdvisory,
  severeClutchSlipCritical,
}

/// Diagnostic evaluation result for transmission slip and synchro health.
class TransmissionSlipAuditResult {
  final String vehicleId;
  final TransmissionHealthStatus status;
  final double maxSlipRpm;
  final double fluidTemperatureCelsius;
  final double averageShiftLatencyMs;
  final bool hasThermalFluidDegradation;
  final bool isImmediateServiceRequired;
  final String diagnosticRecommendation;

  const TransmissionSlipAuditResult({
    required this.vehicleId,
    required this.status,
    required this.maxSlipRpm,
    required this.fluidTemperatureCelsius,
    required this.averageShiftLatencyMs,
    required this.hasThermalFluidDegradation,
    required this.isImmediateServiceRequired,
    required this.diagnosticRecommendation,
  });
}

/// Heavy Vehicle Transmission Slip & Torque Converter Efficiency Diagnoser Service.
class TransmissionSlipDiagnoserService {
  const TransmissionSlipDiagnoserService();

  // Thresholds
  static const double severeSlipRpmThreshold = 180.0; // Significant torque loss & friction plate burning
  static const double advisorySlipRpmThreshold = 80.0;
  static const double fluidOverheatCelsius = 115.0;
  static const double sluggishShiftLatencyMs = 650.0;

  TransmissionSlipAuditResult evaluateTransmission({
    required String vehicleId,
    required List<TransmissionClutchReading> readings,
  }) {
    if (readings.isEmpty) {
      return TransmissionSlipAuditResult(
        vehicleId: vehicleId,
        status: TransmissionHealthStatus.healthy,
        maxSlipRpm: 0.0,
        fluidTemperatureCelsius: 0.0,
        averageShiftLatencyMs: 0.0,
        hasThermalFluidDegradation: false,
        isImmediateServiceRequired: false,
        diagnosticRecommendation: 'No transmission telemetry available.',
      );
    }

    double maxSlip = 0.0;
    double maxTemp = 0.0;
    double totalLatency = 0.0;

    for (final r in readings) {
      if (r.clutchSlipRpm > maxSlip) maxSlip = r.clutchSlipRpm;
      if (r.transmissionFluidTempCelsius > maxTemp) maxTemp = r.transmissionFluidTempCelsius;
      totalLatency += r.shiftEngagementLatencyMs;
    }

    final avgLatency = totalLatency / readings.length;
    final isFluidDegraded = maxTemp >= fluidOverheatCelsius;

    TransmissionHealthStatus status;
    bool serviceRequired;
    String recommendation;

    if (maxSlip >= severeSlipRpmThreshold || (isFluidDegraded && maxSlip >= advisorySlipRpmThreshold)) {
      status = TransmissionHealthStatus.severeClutchSlipCritical;
      serviceRequired = true;
      recommendation = 'CRITICAL: Severe clutch slippage (${maxSlip.toStringAsFixed(0)} RPM). Torque converter / friction disc failure imminent.';
    } else if (maxSlip >= advisorySlipRpmThreshold || avgLatency >= sluggishShiftLatencyMs) {
      status = TransmissionHealthStatus.moderateSlipAdvisory;
      serviceRequired = false;
      recommendation = 'ADVISORY: Sluggish synchro engagement or moderate clutch wear. Check transmission fluid level.';
    } else {
      status = TransmissionHealthStatus.healthy;
      serviceRequired = false;
      recommendation = 'Clutch lockup and gear synchronization nominal.';
    }

    return TransmissionSlipAuditResult(
      vehicleId: vehicleId,
      status: status,
      maxSlipRpm: double.parse(maxSlip.toStringAsFixed(1)),
      fluidTemperatureCelsius: double.parse(maxTemp.toStringAsFixed(1)),
      averageShiftLatencyMs: double.parse(avgLatency.toStringAsFixed(0)),
      hasThermalFluidDegradation: isFluidDegraded,
      isImmediateServiceRequired: serviceRequired,
      diagnosticRecommendation: recommendation,
    );
  }
}
