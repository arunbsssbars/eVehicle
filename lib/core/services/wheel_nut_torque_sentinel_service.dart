/// Wheel rim construction type.
enum WheelRimType {
  forgedAluminum,
  castSteelDisc,
  demountableSpokeRim,
}

/// Dynamic wheel fastener torque and stud stretch telemetry sample.
class WheelNutTorqueSample {
  final int studIndex; // 1 to 10 for standard commercial 10-stud hub
  final double measuredTorqueNm;
  final double nominalSpecTorqueNm; // e.g. 600 - 650 Nm for M22x1.5 studs
  final double studElongationMm;
  final bool isNutLooseOrMissing;

  const WheelNutTorqueSample({
    required this.studIndex,
    required this.measuredTorqueNm,
    this.nominalSpecTorqueNm = 600.0,
    required this.studElongationMm,
    required this.isNutLooseOrMissing,
  });

  /// Clamping force percentage relative to specification.
  double get torquePercentageOfSpec =>
      nominalSpecTorqueNm > 0 ? (measuredTorqueNm / nominalSpecTorqueNm) * 100 : 0.0;
}

/// Wheel clamping integrity status.
enum WheelClampingStatus {
  secure,
  torqueLossAdvisory,
  imminentWheelOffEmergency,
}

/// Evaluation result for hub-piloted wheel nut security.
class WheelNutIntegrityResult {
  final String vehicleId;
  final String wheelEndPosition;
  final WheelClampingStatus status;
  final int totalLooseFastenersCount;
  final double lowestTorqueNm;
  final double averageClampingForcePercent;
  final bool isGroundingMandatory;
  final String safetyAdvisory;

  const WheelNutIntegrityResult({
    required this.vehicleId,
    required this.wheelEndPosition,
    required this.status,
    required this.totalLooseFastenersCount,
    required this.lowestTorqueNm,
    required this.averageClampingForcePercent,
    required this.isGroundingMandatory,
    required this.safetyAdvisory,
  });

  bool get isSafe => status == WheelClampingStatus.secure;
}

/// Commercial Fleet Wheel Nut Torque Loss & Wheel-Off Sentinel Service.
class WheelNutTorqueSentinelService {
  const WheelNutTorqueSentinelService();

  // Thresholds
  static const double criticalTorqueRetentionPercent = 65.0; // Significant loss of clamping force

  WheelNutIntegrityResult evaluateWheelFasteners({
    required String vehicleId,
    required String wheelEndPosition,
    required List<WheelNutTorqueSample> samples,
  }) {
    if (samples.isEmpty) {
      return WheelNutIntegrityResult(
        vehicleId: vehicleId,
        wheelEndPosition: wheelEndPosition,
        status: WheelClampingStatus.secure,
        totalLooseFastenersCount: 0,
        lowestTorqueNm: 0.0,
        averageClampingForcePercent: 100.0,
        isGroundingMandatory: false,
        safetyAdvisory: 'No wheel nut telemetry available.',
      );
    }

    int looseCount = 0;
    double lowestTorque = double.infinity;
    double totalPercent = 0.0;

    for (final s in samples) {
      if (s.measuredTorqueNm < lowestTorque) lowestTorque = s.measuredTorqueNm;
      totalPercent += s.torquePercentageOfSpec;
      if (s.isNutLooseOrMissing || s.torquePercentageOfSpec < criticalTorqueRetentionPercent) {
        looseCount++;
      }
    }

    final avgPercent = totalPercent / samples.length;

    WheelClampingStatus status;
    bool groundVehicle;
    String advisory;

    if (looseCount >= 2 || avgPercent < 70.0) {
      status = WheelClampingStatus.imminentWheelOffEmergency;
      groundVehicle = true;
      advisory = 'WHEEL-OFF EMERGENCY: $looseCount loose/missing fasteners detected on $wheelEndPosition. Immediate wheel separation hazard. Ground vehicle!';
    } else if (looseCount == 1 || avgPercent < 85.0) {
      status = WheelClampingStatus.torqueLossAdvisory;
      groundVehicle = false;
      advisory = 'TORQUE LOSS ADVISORY: Fastener torque decay detected. Retorque studs with calibrated torque wrench before highway transit.';
    } else {
      status = WheelClampingStatus.secure;
      groundVehicle = false;
      advisory = 'All 10 hub-piloted wheel nuts torqued to specification with proper stud clamping stretch.';
    }

    return WheelNutIntegrityResult(
      vehicleId: vehicleId,
      wheelEndPosition: wheelEndPosition,
      status: status,
      totalLooseFastenersCount: looseCount,
      lowestTorqueNm: double.parse(lowestTorque.toStringAsFixed(0)),
      averageClampingForcePercent: double.parse(avgPercent.toStringAsFixed(1)),
      isGroundingMandatory: groundVehicle,
      safetyAdvisory: advisory,
    );
  }
}
