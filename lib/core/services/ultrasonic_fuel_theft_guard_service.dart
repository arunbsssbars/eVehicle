
/// Fuel tank physical capacity profile.
class FuelTankGeometry {
  final String tankId;
  final double grossCapacityLitres;
  final double diameterOrHeightCm;
  final double lengthCm;

  const FuelTankGeometry({
    required this.tankId,
    required this.grossCapacityLitres,
    this.diameterOrHeightCm = 65.0,
    this.lengthCm = 150.0,
  });
}

/// Dynamic ultrasonic fuel sensor telemetry reading.
class UltrasonicFuelSensorSample {
  final DateTime timestamp;
  final double fuelLevelMillimeters; // Height of liquid column from transducer
  final double computedVolumeLitres;
  final double fuelTemperatureCelsius;
  final double vehicleSpeedKmh;
  final double rollAngleDegrees;
  final double pitchAngleDegrees;

  const UltrasonicFuelSensorSample({
    required this.timestamp,
    required this.fuelLevelMillimeters,
    required this.computedVolumeLitres,
    required this.fuelTemperatureCelsius,
    required this.vehicleSpeedKmh,
    this.rollAngleDegrees = 0.0,
    this.pitchAngleDegrees = 0.0,
  });
}

/// Fuel tank event type.
enum FuelEventClassification {
  normalConsumption,
  legitimateRefueling,
  illicitSiphonTheft,
  sloshTransient,
}

/// Comprehensive fuel tank audit result.
class FuelSiphonTheftResult {
  final String vehicleId;
  final FuelEventClassification classification;
  final double volumeDeltaLitres;
  final double currentVolumeLitres;
  final bool isTheftAlarmTriggered;
  final String incidentTimestampIso;
  final String alarmSummary;

  const FuelSiphonTheftResult({
    required this.vehicleId,
    required this.classification,
    required this.volumeDeltaLitres,
    required this.currentVolumeLitres,
    required this.isTheftAlarmTriggered,
    required this.incidentTimestampIso,
    required this.alarmSummary,
  });

  bool get isNormal => classification == FuelEventClassification.normalConsumption || classification == FuelEventClassification.sloshTransient;
}

/// High-Precision Ultrasonic Fuel Level & Siphon Theft Detection Guard Service.
class UltrasonicFuelTheftGuardService {
  const UltrasonicFuelTheftGuardService();

  // Thresholds
  static const double rapidDrainVolumeThresholdLitres = 15.0; // Over 15 Litres dropped while parked
  static const double rapidRefuelThresholdLitres = 20.0;

  FuelSiphonTheftResult analyzeFuelEvent({
    required String vehicleId,
    required UltrasonicFuelSensorSample baselineSample,
    required UltrasonicFuelSensorSample currentSample,
  }) {
    final deltaLitres = currentSample.computedVolumeLitres - baselineSample.computedVolumeLitres;
    final isStationary = baselineSample.vehicleSpeedKmh <= 2.0 && currentSample.vehicleSpeedKmh <= 2.0;

    FuelEventClassification event;
    bool theftAlarm = false;
    String summary;

    if (deltaLitres <= -rapidDrainVolumeThresholdLitres && isStationary) {
      event = FuelEventClassification.illicitSiphonTheft;
      theftAlarm = true;
      summary = 'CRITICAL ALARM: Sudden fuel drain (-${deltaLitres.abs().toStringAsFixed(1)} L) detected while vehicle was parked! Probable illicit siphon.';
    } else if (deltaLitres >= rapidRefuelThresholdLitres && isStationary) {
      event = FuelEventClassification.legitimateRefueling;
      theftAlarm = false;
      summary = 'Refueling verified (+${deltaLitres.toStringAsFixed(1)} L) while vehicle stationary.';
    } else if (currentSample.rollAngleDegrees.abs() > 5.0 || currentSample.pitchAngleDegrees.abs() > 5.0) {
      event = FuelEventClassification.sloshTransient;
      theftAlarm = false;
      summary = 'Level variation attributed to road grade tilt or dynamic fluid slosh.';
    } else {
      event = FuelEventClassification.normalConsumption;
      theftAlarm = false;
      summary = 'Fuel level nominal. Normal engine burn consumption observed.';
    }

    return FuelSiphonTheftResult(
      vehicleId: vehicleId,
      classification: event,
      volumeDeltaLitres: double.parse(deltaLitres.toStringAsFixed(1)),
      currentVolumeLitres: double.parse(currentSample.computedVolumeLitres.toStringAsFixed(1)),
      isTheftAlarmTriggered: theftAlarm,
      incidentTimestampIso: currentSample.timestamp.toIso8601String(),
      alarmSummary: summary,
    );
  }
}
