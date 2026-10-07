/// Convoy position and role in the platoon.
enum PlatoonRole {
  leadVehicle,
  followerMiddle,
  tailVehicle,
  soloDissolved,
}

/// Operational state of the aerodynamic platoon coupling.
enum PlatoonCouplingState {
  tightAerodynamicLock, // Time headway 0.6s - 1.0s, high fuel savings
  safeCruisingGap,       // Time headway 1.1s - 1.8s
  v2vLatencyDegraded,   // Radio packet drop > 25ms, gap expanding
  emergencyDecouple,    // Emergency braking or V2V radio signal loss
}

/// Telemetry shared over V2V C-V2X / 5.9 GHz DSRC wireless link.
class V2vPlatoonTelemetry {
  final String platoonId;
  final PlatoonRole role;
  final double interVehicleGapMeters;    // e.g. 12m to 40m
  final double vehicleSpeedKmh;          // Cruising speed (e.g. 85 km/h)
  final int v2vPacketLatencyMs;          // Must be < 20ms for tight lock
  final double leadVehicleBrakeCommandG; // Forward G-force deceleration
  final int convoyTruckCount;

  const V2vPlatoonTelemetry({
    required this.platoonId,
    required this.role,
    required this.interVehicleGapMeters,
    required this.vehicleSpeedKmh,
    required this.v2vPacketLatencyMs,
    required this.leadVehicleBrakeCommandG,
    required this.convoyTruckCount,
  });
}

/// Diagnostic evaluation of platoon slipstream efficiency and spacing safety.
class PlatoonSafetyAudit {
  final PlatoonCouplingState state;
  final double timeHeadwaySeconds;
  final double aerodynamicFuelSavingsPercent; // Up to ~15% for followers, ~6% for lead
  final String statusSummary;
  final bool synchronizedBrakeArmed;
  final bool requiresEmergencyDecouple;

  const PlatoonSafetyAudit({
    required this.state,
    required this.timeHeadwaySeconds,
    required this.aerodynamicFuelSavingsPercent,
    required this.statusSummary,
    required this.synchronizedBrakeArmed,
    required this.requiresEmergencyDecouple,
  });
}

/// Service managing cooperative vehicle platooning, V2V latency, and slipstream aerodynamic benefits.
class FleetPlatooningService {
  const FleetPlatooningService();

  /// Evaluates V2V communications link, inter-vehicle time headway, and aerodynamic slipstream benefits.
  PlatoonSafetyAudit evaluatePlatoon(V2vPlatoonTelemetry telemetry) {
    if (telemetry.convoyTruckCount <= 1 || telemetry.role == PlatoonRole.soloDissolved) {
      return const PlatoonSafetyAudit(
        state: PlatoonCouplingState.safeCruisingGap,
        timeHeadwaySeconds: 2.5,
        aerodynamicFuelSavingsPercent: 0.0,
        statusSummary: 'SOLO TRANSIT: Platooning inactive. Standard single-vehicle aerodynamic drag.',
        synchronizedBrakeArmed: false,
        requiresEmergencyDecouple: false,
      );
    }

    // Time headway = gap_distance / speed_in_m_per_s
    final speedMps = telemetry.vehicleSpeedKmh / 3.6;
    final double timeHeadway = speedMps > 1.0
        ? telemetry.interVehicleGapMeters / speedMps
        : 2.0;

    // V2V signal loss or emergency brake trigger
    if (telemetry.v2vPacketLatencyMs >= 60 || telemetry.leadVehicleBrakeCommandG <= -0.45) {
      return PlatoonSafetyAudit(
        state: PlatoonCouplingState.emergencyDecouple,
        timeHeadwaySeconds: double.parse(timeHeadway.toStringAsFixed(2)),
        aerodynamicFuelSavingsPercent: 0.0,
        statusSummary: 'EMERGENCY DECOUPLE: Severe deceleration (${telemetry.leadVehicleBrakeCommandG.toStringAsFixed(2)}G) or V2V radio dropout (${telemetry.v2vPacketLatencyMs}ms). Disengaging automated throttle.',
        synchronizedBrakeArmed: true,
        requiresEmergencyDecouple: true,
      );
    }

    // Degraded wireless link
    if (telemetry.v2vPacketLatencyMs >= 25) {
      return PlatoonSafetyAudit(
        state: PlatoonCouplingState.v2vLatencyDegraded,
        timeHeadwaySeconds: double.parse(timeHeadway.toStringAsFixed(2)),
        aerodynamicFuelSavingsPercent: 4.5,
        statusSummary: 'V2V LATENCY WARNING: C-V2X latency elevated (${telemetry.v2vPacketLatencyMs}ms). Expanding safety buffer to > 1.4s headway.',
        synchronizedBrakeArmed: true,
        requiresEmergencyDecouple: false,
      );
    }

    // Tight aerodynamic coupling vs standard gap
    if (timeHeadway <= 1.0 && telemetry.interVehicleGapMeters <= 24.0) {
      final double savings = telemetry.role == PlatoonRole.leadVehicle ? 5.8 : 14.2;
      return PlatoonSafetyAudit(
        state: PlatoonCouplingState.tightAerodynamicLock,
        timeHeadwaySeconds: double.parse(timeHeadway.toStringAsFixed(2)),
        aerodynamicFuelSavingsPercent: savings,
        statusSummary: 'AERODYNAMIC LOCK: Drafting in slipstream at ${timeHeadway.toStringAsFixed(2)}s headway (${telemetry.interVehicleGapMeters.toStringAsFixed(0)}m). Saving ~$savings% fuel.',
        synchronizedBrakeArmed: true,
        requiresEmergencyDecouple: false,
      );
    } else {
      final double savings = telemetry.role == PlatoonRole.leadVehicle ? 3.0 : 7.5;
      return PlatoonSafetyAudit(
        state: PlatoonCouplingState.safeCruisingGap,
        timeHeadwaySeconds: double.parse(timeHeadway.toStringAsFixed(2)),
        aerodynamicFuelSavingsPercent: savings,
        statusSummary: 'CRUISING GAP: Safe spacing maintained in ${telemetry.convoyTruckCount}-truck platoon.',
        synchronizedBrakeArmed: true,
        requiresEmergencyDecouple: false,
      );
    }
  }
}
