/// Suspension ride height and axle load balance state.
enum SuspensionBalanceStatus {
  balancedOptimal,
  driveAxleOverloaded,
  trailerBogieOverloaded,
  dockLevelingActive,
}

/// Pressure and height sensor readings from tractor & trailer air suspension.
class EcasSuspensionTelemetry {
  final double steerAxleKg;              // Legal rating approx 5,500 - 6,000 kg
  final double driveBellowsPressureBar;  // Pressure in drive axle air bags
  final double trailerBellowsPressureBar;// Pressure in trailer tridem/tandem
  final double suspensionRideHeightOffsetMm; // -80mm (kneel) to +120mm (ramp level)
  final int fifthWheelSlideNotch;        // Current pin position (1 to 10)
  final bool loadingDockModeActive;

  const EcasSuspensionTelemetry({
    required this.steerAxleKg,
    required this.driveBellowsPressureBar,
    required this.trailerBellowsPressureBar,
    required this.suspensionRideHeightOffsetMm,
    required this.fifthWheelSlideNotch,
    required this.loadingDockModeActive,
  });
}

/// Comprehensive suspension leveling and bridge law weight distribution audit.
class AxleBalanceAudit {
  final SuspensionBalanceStatus status;
  final double estimatedDriveAxleKg;
  final double estimatedTrailerAxleKg;
  final int recommendedSlideAdjustmentNotches; // Positive = slide forward, negative = slide rearward
  final String statusSummary;
  final bool rebalancingRequired;

  const AxleBalanceAudit({
    required this.status,
    required this.estimatedDriveAxleKg,
    required this.estimatedTrailerAxleKg,
    required this.recommendedSlideAdjustmentNotches,
    required this.statusSummary,
    required this.rebalancingRequired,
  });
}

/// Service optimizing pneumatic axle load balance, ECAS height, and 5th-wheel slide settings.
class AxleLoadLevelerService {
  const AxleLoadLevelerService();

  /// Standard air bellow calibration constants:
  /// Drive tandem: ~2,400 kg per bar of air pressure
  /// Trailer tandem/tridem: ~3,200 kg per bar of air pressure
  static const double driveBellowsScale = 2400.0;
  static const double trailerBellowsScale = 3200.0;
  static const double maxLegalDriveKg = 11500.0;  // Standard European drive axle limit
  static const double maxLegalTrailerKg = 24000.0; // Standard tridem limit

  /// Evaluates axle weights and calculates fifth-wheel pin slide adjustment to balance load.
  AxleBalanceAudit evaluateSuspension(EcasSuspensionTelemetry telemetry) {
    if (telemetry.loadingDockModeActive) {
      return AxleBalanceAudit(
        status: SuspensionBalanceStatus.dockLevelingActive,
        estimatedDriveAxleKg: telemetry.driveBellowsPressureBar * driveBellowsScale,
        estimatedTrailerAxleKg: telemetry.trailerBellowsPressureBar * trailerBellowsScale,
        recommendedSlideAdjustmentNotches: 0,
        statusSummary: 'DOCK LEVELING ACTIVE: Suspension offset at ${telemetry.suspensionRideHeightOffsetMm > 0 ? "+" : ""}${telemetry.suspensionRideHeightOffsetMm.toStringAsFixed(0)} mm for warehouse ramp alignment.',
        rebalancingRequired: false,
      );
    }

    final driveKg = telemetry.driveBellowsPressureBar * driveBellowsScale;
    final trailerKg = telemetry.trailerBellowsPressureBar * trailerBellowsScale;

    SuspensionBalanceStatus status;
    int slideNotchDelta = 0;
    String summary;
    bool needsRebalance = false;

    if (driveKg > maxLegalDriveKg) {
      status = SuspensionBalanceStatus.driveAxleOverloaded;
      // Overweight on drive: slide fifth wheel rearward (-notches) to transfer weight to trailer
      final excessKg = driveKg - maxLegalDriveKg;
      slideNotchDelta = -((excessKg / 220.0).ceil().clamp(1, 5));
      needsRebalance = true;
      summary = 'DRIVE AXLE OVERWEIGHT: Drive axle at ${(driveKg / 1000).toStringAsFixed(1)} t (max 11.5 t). Slide fifth wheel $slideNotchDelta notches rearward.';
    } else if (trailerKg > maxLegalTrailerKg) {
      status = SuspensionBalanceStatus.trailerBogieOverloaded;
      // Overweight on trailer: slide fifth wheel forward (+notches) to transfer weight to tractor
      final excessKg = trailerKg - maxLegalTrailerKg;
      slideNotchDelta = ((excessKg / 250.0).ceil().clamp(1, 5));
      needsRebalance = true;
      summary = 'TRAILER BOGIE OVERWEIGHT: Trailer axles at ${(trailerKg / 1000).toStringAsFixed(1)} t (max 24.0 t). Slide fifth wheel +$slideNotchDelta notches forward.';
    } else {
      status = SuspensionBalanceStatus.balancedOptimal;
      summary = 'SUSPENSION BALANCED: Drive and trailer axles within statutory bridge weight limits.';
    }

    return AxleBalanceAudit(
      status: status,
      estimatedDriveAxleKg: double.parse(driveKg.toStringAsFixed(0)),
      estimatedTrailerAxleKg: double.parse(trailerKg.toStringAsFixed(0)),
      recommendedSlideAdjustmentNotches: slideNotchDelta,
      statusSummary: summary,
      rebalancingRequired: needsRebalance,
    );
  }
}
