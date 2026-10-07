/// Aerodynamic drag reduction active aerodynamic elements.
enum AeroComponentType {
  trailerTailFairing,
  sideSkirtPanels,
  roofDeflectorVane,
  activeGrilleShutter,
}

/// Dynamic speed, wind, and deployment status telemetry.
class ActiveAeroTelemetry {
  final double vehicleSpeedKmh;
  final double headwindSpeedKmh;
  final double crosswindAngleDegrees;
  final bool isTrailerTailDeployed;
  final bool areSideSkirtsIntact;
  final double activeGrilleShutterOpenPercent; // 0% closed (aerodynamic), 100% open (cooling)
  final double engineCoolantTempCelsius;

  const ActiveAeroTelemetry({
    required this.vehicleSpeedKmh,
    this.headwindSpeedKmh = 10.0,
    this.crosswindAngleDegrees = 0.0,
    required this.isTrailerTailDeployed,
    required this.areSideSkirtsIntact,
    required this.activeGrilleShutterOpenPercent,
    required this.engineCoolantTempCelsius,
  });

  /// Total relative airspeed seen by tractor-trailer front face.
  double get effectiveAirspeedKmh => vehicleSpeedKmh + headwindSpeedKmh;
}

/// Evaluation result for active aerodynamic drag and fuel economy optimization.
class ActiveAeroEvaluationResult {
  final String vehicleId;
  final double dragCoefficientReductionPercent; // e.g. 8.5% Cd reduction
  final double fuelSavingsLitersPer100Km;
  final bool shouldDeployTrailerTail;
  final bool shouldCloseGrilleShutters;
  final String operationalStatus;
  final String aerodynamicAdvice;

  const ActiveAeroEvaluationResult({
    required this.vehicleId,
    required this.dragCoefficientReductionPercent,
    required this.fuelSavingsLitersPer100Km,
    required this.shouldDeployTrailerTail,
    required this.shouldCloseGrilleShutters,
    required this.operationalStatus,
    required this.aerodynamicAdvice,
  });
}

/// Active Aerodynamic Drag Reduction & Deployable Fairing Controller Service.
class ActiveAeroControllerService {
  const ActiveAeroControllerService();

  // Highway deployment speed threshold for trailer boat tails / rear fairings
  static const double tailDeploymentSpeedKmh = 60.0;
  static const double safeCoolantTempForShutterCloseCelsius = 92.0;

  ActiveAeroEvaluationResult evaluateAeroState({
    required String vehicleId,
    required ActiveAeroTelemetry telemetry,
  }) {
    final isHighwaySpeed = telemetry.vehicleSpeedKmh >= tailDeploymentSpeedKmh;
    final shouldDeployTail = isHighwaySpeed;
    final shouldCloseShutters = isHighwaySpeed && telemetry.engineCoolantTempCelsius < safeCoolantTempForShutterCloseCelsius;

    double cdReduction = 0.0;
    if (telemetry.areSideSkirtsIntact) cdReduction += 4.5;
    if (telemetry.isTrailerTailDeployed) cdReduction += 5.2;
    if (telemetry.activeGrilleShutterOpenPercent <= 20.0) cdReduction += 2.3;

    // Fuel savings model: at 85 km/h, every 10% Cd reduction yields ~1.8 L/100km fuel reduction
    final fuelSavings = isHighwaySpeed ? (cdReduction / 10.0) * 1.8 : 0.0;

    String status;
    String advice;

    if (isHighwaySpeed && !telemetry.isTrailerTailDeployed) {
      status = 'SUB-OPTIMAL FAIRING';
      advice = 'Deploy trailer rear boat-tail fairings to reduce turbulent wake drag.';
    } else if (isHighwaySpeed && telemetry.isTrailerTailDeployed) {
      status = 'AERODYNAMIC OPTIMAL';
      advice = 'Active aerodynamic elements fully engaged. Fuel burn reduced by ${fuelSavings.toStringAsFixed(1)} L/100km.';
    } else {
      status = 'CITY LOW DRAG';
      advice = 'Vehicle in low-speed urban envelope. Deployable fairings retracted.';
    }

    return ActiveAeroEvaluationResult(
      vehicleId: vehicleId,
      dragCoefficientReductionPercent: double.parse(cdReduction.toStringAsFixed(1)),
      fuelSavingsLitersPer100Km: double.parse(fuelSavings.toStringAsFixed(2)),
      shouldDeployTrailerTail: shouldDeployTail,
      shouldCloseGrilleShutters: shouldCloseShutters,
      operationalStatus: status,
      aerodynamicAdvice: advice,
    );
  }
}
