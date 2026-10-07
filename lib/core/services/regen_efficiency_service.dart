import 'dart:math';

/// Performance rating of regenerative energy recovery.
enum RegenEfficiencyGrade {
  excellentOnePedal, // > 80% capture: optimal one-pedal driving
  goodModerate,      // 60% - 80% capture
  poorFrictionHeavy, // 30% - 60% capture: harsh pedal stabs activating friction brakes
  criticalWastedHeat, // < 30% capture: kinetic energy lost as rotor heat
}

/// Deceleration telemetry event recorded by EV motor controller / CAN bus.
class DecelerationBrakeEvent {
  final double initialSpeedKmh;
  final double finalSpeedKmh;
  final double durationSeconds;
  final double vehicleMassKg;
  final double energyRecapturedKwh; // Measured by inverter shunt
  final double maxMotorRegenPowerKw;

  const DecelerationBrakeEvent({
    required this.initialSpeedKmh,
    required this.finalSpeedKmh,
    required this.durationSeconds,
    required this.vehicleMassKg,
    required this.energyRecapturedKwh,
    this.maxMotorRegenPowerKw = 150.0,
  });
}

/// Diagnostic evaluation of regenerative braking efficiency and recovered kinetic energy.
class RegenEfficiencyAudit {
  final double totalKineticEnergyKwh;
  final double recapturedEnergyKwh;
  final double frictionLostEnergyKwh;
  final double captureEfficiencyPercent;
  final double addedRangeMeters;
  final RegenEfficiencyGrade grade;
  final String coachingTip;

  const RegenEfficiencyAudit({
    required this.totalKineticEnergyKwh,
    required this.recapturedEnergyKwh,
    required this.frictionLostEnergyKwh,
    required this.captureEfficiencyPercent,
    required this.addedRangeMeters,
    required this.grade,
    required this.coachingTip,
  });
}

/// Service computing EV regenerative braking kinetic recovery and eco-braking efficiency.
class RegenEfficiencyService {
  const RegenEfficiencyService();

  /// Evaluates deceleration telemetry to compute kinetic energy capture vs brake pad dissipation.
  RegenEfficiencyAudit evaluateDeceleration(DecelerationBrakeEvent event) {
    if (event.initialSpeedKmh <= event.finalSpeedKmh || event.durationSeconds <= 0.1) {
      return const RegenEfficiencyAudit(
        totalKineticEnergyKwh: 0.0,
        recapturedEnergyKwh: 0.0,
        frictionLostEnergyKwh: 0.0,
        captureEfficiencyPercent: 100.0,
        addedRangeMeters: 0.0,
        grade: RegenEfficiencyGrade.excellentOnePedal,
        coachingTip: 'Steady speed maintained. Zero braking energy dissipated.',
      );
    }

    // Convert speeds from km/h to m/s
    final vInitial = event.initialSpeedKmh / 3.6;
    final vFinal = event.finalSpeedKmh / 3.6;

    // Theoretical kinetic energy dissipated: Delta Ek = 0.5 * m * (v1^2 - v2^2) in Joules
    final deltaJoules = 0.5 * event.vehicleMassKg * (pow(vInitial, 2) - pow(vFinal, 2));
    // Convert Joules to kWh: 1 kWh = 3,600,000 Joules
    final totalTheoreticalKwh = max(0.001, deltaJoules / 3600000.0);

    final actualRecapturedKwh = event.energyRecapturedKwh.clamp(0.0, totalTheoreticalKwh);
    final frictionLossKwh = (totalTheoreticalKwh - actualRecapturedKwh).clamp(0.0, totalTheoreticalKwh);

    final efficiencyPercent = ((actualRecapturedKwh / totalTheoreticalKwh) * 100.0).clamp(0.0, 100.0);

    // Range recovered: assuming light-commercial EV efficiency of 180 Wh/km (0.18 kWh/km = 0.00018 kWh/m)
    final addedMeters = (actualRecapturedKwh * 1000.0) / 0.18;

    RegenEfficiencyGrade grade;
    String tip;

    if (efficiencyPercent >= 82.0) {
      grade = RegenEfficiencyGrade.excellentOnePedal;
      tip = 'EXCELLENT RECOVERY: Smooth one-pedal modulation maximized kinetic recapture.';
    } else if (efficiencyPercent >= 65.0) {
      grade = RegenEfficiencyGrade.goodModerate;
      tip = 'GOOD MODULATION: Most kinetic energy stored. Ease onto brake earlier for peak recovery.';
    } else if (efficiencyPercent >= 38.0) {
      grade = RegenEfficiencyGrade.poorFrictionHeavy;
      tip = 'HARD BRAKING: Hydraulic calipers absorbed significant energy as disc friction heat.';
    } else {
      grade = RegenEfficiencyGrade.criticalWastedHeat;
      tip = 'EMERGENCY / ABRUPT STOP: Over 60% of kinetic energy wasted into brake pads.';
    }

    return RegenEfficiencyAudit(
      totalKineticEnergyKwh: double.parse(totalTheoreticalKwh.toStringAsFixed(3)),
      recapturedEnergyKwh: double.parse(actualRecapturedKwh.toStringAsFixed(3)),
      frictionLostEnergyKwh: double.parse(frictionLossKwh.toStringAsFixed(3)),
      captureEfficiencyPercent: double.parse(efficiencyPercent.toStringAsFixed(1)),
      addedRangeMeters: double.parse(addedMeters.toStringAsFixed(0)),
      grade: grade,
      coachingTip: tip,
    );
  }
}
