/// Heavy vehicle driveline differential component.
enum DifferentialType {
  singleReductionHypoid,
  tandemInterAxlePowerDivider,
  planetaryHubReduction,
}

/// Differential vibration and operating temperature telemetry reading.
class DifferentialVibrationTelemetry {
  final DifferentialType diffType;
  final double oilSumpTemperatureCelsius;
  final double crownWheelPinionVibrationMmSec; // Velocity severity RMS (mm/s)
  final double magneticDrainPlugMetalFinesGrams; // Accumulated ferrous debris
  final double gearToothMeshingFrequencyHz;
  final double drivelineBacklashDegrees;
  final double accumulatedKilometers;

  const DifferentialVibrationTelemetry({
    required this.diffType,
    required this.oilSumpTemperatureCelsius,
    required this.crownWheelPinionVibrationMmSec,
    required this.magneticDrainPlugMetalFinesGrams,
    required this.gearToothMeshingFrequencyHz,
    required this.drivelineBacklashDegrees,
    required this.accumulatedKilometers,
  });
}

/// Differential health status classification.
enum DifferentialHealthStatus {
  normal,
  backlashAdvisory,
  gearToothChippingCritical,
}

/// Evaluation result for differential hypoid gear wear and bearing spalling.
class DifferentialHealthResult {
  final String vehicleId;
  final DifferentialHealthStatus status;
  final double gearMeshingVibrationMmSec;
  final double sumpTemperatureCelsius;
  final double backlashDegrees;
  final bool hasSevereMetalSpalling;
  final bool isOverhaulMandatory;
  final String diagnosticFinding;

  const DifferentialHealthResult({
    required this.vehicleId,
    required this.status,
    required this.gearMeshingVibrationMmSec,
    required this.sumpTemperatureCelsius,
    required this.backlashDegrees,
    required this.hasSevereMetalSpalling,
    required this.isOverhaulMandatory,
    required this.diagnosticFinding,
  });

  bool get isSafe => status == DifferentialHealthStatus.normal;
}

/// Differential Crown-Wheel & Pinion Backlash Vibration Diagnoser Service.
class DifferentialVibrationDiagnoserService {
  const DifferentialVibrationDiagnoserService();

  // Thresholds (ISO 10816-3 Zone C/D for heavy gearboxes)
  static const double vibrationChippingThresholdMmSec = 7.5; // Gear tooth pitting / spalling
  static const double vibrationAdvisoryThresholdMmSec = 4.5;
  static const double excessiveBacklashDegrees = 3.5;         // Severe ring & pinion play
  static const double dangerousMetalDebrisGrams = 4.0;

  DifferentialHealthResult evaluateDifferential({
    required String vehicleId,
    required DifferentialVibrationTelemetry telemetry,
  }) {
    final vib = telemetry.crownWheelPinionVibrationMmSec;
    final metalSpalling = telemetry.magneticDrainPlugMetalFinesGrams >= dangerousMetalDebrisGrams;
    final highBacklash = telemetry.drivelineBacklashDegrees >= excessiveBacklashDegrees;

    DifferentialHealthStatus status;
    bool overhaul = false;
    String finding;

    if (vib >= vibrationChippingThresholdMmSec || metalSpalling) {
      status = DifferentialHealthStatus.gearToothChippingCritical;
      overhaul = true;
      finding = 'CRITICAL: Severe hypoid gear tooth chipping / pinion bearing spalling (${vib.toStringAsFixed(1)} mm/s RMS). Overhaul carrier assembly immediately.';
    } else if (vib >= vibrationAdvisoryThresholdMmSec || highBacklash) {
      status = DifferentialHealthStatus.backlashAdvisory;
      overhaul = false;
      finding = 'ADVISORY: Elevated ring & pinion backlash (${telemetry.drivelineBacklashDegrees.toStringAsFixed(1)}°). Inspect carrier bearing preload shims.';
    } else {
      status = DifferentialHealthStatus.normal;
      overhaul = false;
      finding = 'Differential hypoid tooth contact pattern, oil temperature, and vibration nominal.';
    }

    return DifferentialHealthResult(
      vehicleId: vehicleId,
      status: status,
      gearMeshingVibrationMmSec: double.parse(vib.toStringAsFixed(1)),
      sumpTemperatureCelsius: double.parse(telemetry.oilSumpTemperatureCelsius.toStringAsFixed(1)),
      backlashDegrees: double.parse(telemetry.drivelineBacklashDegrees.toStringAsFixed(1)),
      hasSevereMetalSpalling: metalSpalling,
      isOverhaulMandatory: overhaul,
      diagnosticFinding: finding,
    );
  }
}
