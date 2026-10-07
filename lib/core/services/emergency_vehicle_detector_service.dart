/// Move-Over status and emergency response vehicle proximity.
enum EmergencyYieldStatus {
  noEmergencyVehicleDetected,
  distantSirenAdvisory,
  imminentYieldRequired,
}

/// Category of responding emergency emergency service.
enum EmergencyServiceType {
  none,
  policePursuit,
  ambulanceMedical,
  fireApparatus,
}

/// Acoustic frequency and optical strobe telemetry captured by external microphone & camera.
class SirenDetectorTelemetry {
  final double dominantFrequencyHz;       // Typical wail/yelp 600 - 1400 Hz
  final double acousticVolumeDecibels;    // Alert > 75 dB outside cabin
  final double opticalStrobeRateHz;       // High-intensity flash rate (1.0 to 2.5 Hz)
  final bool approachingFromRear;         // Directional audio phase delay
  final double estimatedDistanceMeters;

  const SirenDetectorTelemetry({
    required this.dominantFrequencyHz,
    required this.acousticVolumeDecibels,
    required this.opticalStrobeRateHz,
    required this.approachingFromRear,
    required this.estimatedDistanceMeters,
  });
}

/// Comprehensive Move-Over legal advisory and yield action audit.
class MoveOverSafetyAudit {
  final EmergencyYieldStatus status;
  final EmergencyServiceType estimatedServiceType;
  final double timeToOvertakeSeconds;
  final String yieldAdvisory;
  final bool requiresImmediateLaneChange;

  const MoveOverSafetyAudit({
    required this.status,
    required this.estimatedServiceType,
    required this.timeToOvertakeSeconds,
    required this.yieldAdvisory,
    required this.requiresImmediateLaneChange,
  });
}

/// Service detecting approaching emergency sirens and optical strobes to advise move-over compliance.
class EmergencyVehicleDetectorService {
  const EmergencyVehicleDetectorService();

  /// Audits acoustic FFT peak frequencies and strobe rates to identify emergency vehicles.
  MoveOverSafetyAudit evaluateSiren(SirenDetectorTelemetry telemetry) {
    final bool isSirenFrequency = telemetry.dominantFrequencyHz >= 550.0 &&
        telemetry.dominantFrequencyHz <= 1650.0;
    final bool isStrobeActive = telemetry.opticalStrobeRateHz >= 0.8 &&
        telemetry.opticalStrobeRateHz <= 3.0;

    final bool isEmergencyDetected = (isSirenFrequency && telemetry.acousticVolumeDecibels >= 72.0) ||
        (isStrobeActive && telemetry.acousticVolumeDecibels >= 65.0);

    if (!isEmergencyDetected) {
      return const MoveOverSafetyAudit(
        status: EmergencyYieldStatus.noEmergencyVehicleDetected,
        estimatedServiceType: EmergencyServiceType.none,
        timeToOvertakeSeconds: 99.0,
        yieldAdvisory: 'TRAFFIC NORMAL: Zero active emergency sirens or optical strobes detected.',
        requiresImmediateLaneChange: false,
      );
    }

    // Classify emergency vehicle by siren frequency spectrum
    EmergencyServiceType serviceType;
    if (telemetry.dominantFrequencyHz >= 1100.0) {
      serviceType = EmergencyServiceType.policePursuit;
    } else if (telemetry.dominantFrequencyHz >= 800.0) {
      serviceType = EmergencyServiceType.ambulanceMedical;
    } else {
      serviceType = EmergencyServiceType.fireApparatus;
    }

    // Estimate overtake time: distance / approx speed differential (~15 m/s)
    final double ttOvertake = (telemetry.estimatedDistanceMeters / 15.0).clamp(1.0, 99.0);

    EmergencyYieldStatus status;
    String advisory;
    bool immediateYield = false;

    if (telemetry.approachingFromRear && (telemetry.estimatedDistanceMeters <= 120.0 || ttOvertake <= 8.0)) {
      status = EmergencyYieldStatus.imminentYieldRequired;
      immediateYield = true;
      advisory = 'MOVE-OVER ALERT! ${serviceType.name.toUpperCase()} rapidly approaching from rear (${telemetry.estimatedDistanceMeters.toStringAsFixed(0)}m). Safely indicate and merge right!';
    } else {
      status = EmergencyYieldStatus.distantSirenAdvisory;
      immediateYield = false;
      advisory = 'DISTANT SIREN DETECTED: Emergency responder within ~${telemetry.estimatedDistanceMeters.toStringAsFixed(0)}m. Monitor mirrors and prepare to yield corridor.';
    }

    return MoveOverSafetyAudit(
      status: status,
      estimatedServiceType: serviceType,
      timeToOvertakeSeconds: double.parse(ttOvertake.toStringAsFixed(1)),
      yieldAdvisory: advisory,
      requiresImmediateLaneChange: immediateYield,
    );
  }
}
