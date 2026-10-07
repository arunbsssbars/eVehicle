import 'dart:math';

/// Charging temperature band category.
enum BatteryThermalBand {
  freezingPlateRisk, // < 5°C: Severe charging throttle to prevent lithium dendrites
  coldSuboptimal,     // 5°C - 20°C: Moderate charging speed reduction
  optimalFastAcceptance, // 20°C - 35°C: Maximum kW charging curve
  hotDerating,        // 35°C - 50°C: Throttling for thermal dissipation
  overheatCutoff,     // > 50°C: Emergency charge suspension
}

/// Instantaneous battery cell state prior to or during fast charging.
class EvChargeThermalState {
  final double currentPackTempCelsius;  // Current mean cell temperature
  final double stateOfChargePercent;    // Current SoC (e.g. 15% to 80%)
  final double dispenserMaxPowerKw;     // Rated dispenser output (e.g. 150kW or 300kW)
  final double packHeatCapacityKwhPerC; // Thermal mass factor (approx 0.08 kWh/°C for 80kWh pack)

  const EvChargeThermalState({
    required this.currentPackTempCelsius,
    required this.stateOfChargePercent,
    required this.dispenserMaxPowerKw,
    this.packHeatCapacityKwhPerC = 0.08,
  });
}

/// Comprehensive thermal pre-conditioning and charge speed forecast.
class ChargeThermalAudit {
  final BatteryThermalBand thermalBand;
  final double deliverablePowerKw;
  final double powerThrottlePercentage; // % lost due to temperature
  final int preconditioningMinutesRequired;
  final double preconditioningEnergyCostKwh;
  final int estimatedSessionMinutesSaved;
  final String recommendation;
  final bool preconditioningActive;

  const ChargeThermalAudit({
    required this.thermalBand,
    required this.deliverablePowerKw,
    required this.powerThrottlePercentage,
    required this.preconditioningMinutesRequired,
    required this.preconditioningEnergyCostKwh,
    required this.estimatedSessionMinutesSaved,
    required this.recommendation,
    required this.preconditioningActive,
  });
}

/// Service optimizing battery temperature before and during DC fast charging.
class EvChargingThermalService {
  const EvChargingThermalService();

  /// Target optimal temperature for maximum DC fast charging acceptance
  static const double targetOptimalTemp = 28.0;

  /// Audits deliverable kW and calculates pre-conditioning time and energy.
  ChargeThermalAudit evaluateChargeReadiness(EvChargeThermalState state) {
    BatteryThermalBand band;
    double throttleFactor = 1.0; // 1.0 = full power, 0.2 = 80% throttle

    if (state.currentPackTempCelsius < 5.0) {
      band = BatteryThermalBand.freezingPlateRisk;
      // Below 5°C, fast chargers cap rate to ~30kW to avoid lithium dendrite short circuits
      throttleFactor = 0.25;
    } else if (state.currentPackTempCelsius < 20.0) {
      band = BatteryThermalBand.coldSuboptimal;
      // Linear ramp from 25% at 5°C to 100% at 20°C
      throttleFactor = 0.25 + 0.75 * ((state.currentPackTempCelsius - 5.0) / 15.0);
    } else if (state.currentPackTempCelsius <= 35.0) {
      band = BatteryThermalBand.optimalFastAcceptance;
      throttleFactor = 1.0;
    } else if (state.currentPackTempCelsius <= 48.0) {
      band = BatteryThermalBand.hotDerating;
      // Linear derate from 100% at 35°C down to 30% at 48°C
      throttleFactor = 1.0 - 0.70 * ((state.currentPackTempCelsius - 35.0) / 13.0);
    } else {
      band = BatteryThermalBand.overheatCutoff;
      throttleFactor = 0.05;
    }

    final double deliverableKw = state.dispenserMaxPowerKw * throttleFactor;
    final double throttlePercent = (1.0 - throttleFactor) * 100.0;

    // Calculate heat pump pre-conditioning duration and energy
    final double tempDiff = (targetOptimalTemp - state.currentPackTempCelsius).abs();
    // Heat pump heats/cools at approximately 0.6°C per minute at 5 kW thermal load
    final int precondMinutes = (tempDiff / 0.6).ceil().clamp(0, 45);
    final double precondKwh = (precondMinutes / 60.0) * 4.5; // ~4.5 kW heat pump draw

    // Session time saved: Throttled session vs unthrottled session for a 40 kWh fill
    final double baselineHours = 40.0 / (deliverableKw > 10.0 ? deliverableKw : 10.0);
    final double optimalHours = 40.0 / state.dispenserMaxPowerKw;
    final int minutesSaved = max(0, ((baselineHours - optimalHours) * 60.0).round());

    String recommendation;
    bool active = false;

    switch (band) {
      case BatteryThermalBand.freezingPlateRisk:
        recommendation = 'BATTERY FREEZING: Pre-condition pack for $precondMinutes min to prevent irreversible lithium plating.';
        active = true;
        break;
      case BatteryThermalBand.coldSuboptimal:
        recommendation = 'COLD PACK: Pre-conditioning will save ~$minutesSaved min at the DC charger.';
        active = precondMinutes > 5;
        break;
      case BatteryThermalBand.optimalFastAcceptance:
        recommendation = 'OPTIMAL CHARGE WINDOW: Battery temperature at ${state.currentPackTempCelsius.toStringAsFixed(0)}°C. Full ${state.dispenserMaxPowerKw.toStringAsFixed(0)} kW accepted.';
        active = false;
        break;
      case BatteryThermalBand.hotDerating:
        recommendation = 'BATTERY HOT: Active chiller running to avoid thermal runaway derating.';
        active = true;
        break;
      case BatteryThermalBand.overheatCutoff:
        recommendation = 'OVERHEAT SAFETY CUTOFF: Pack exceeding 50°C! DC charging suspended until cooled.';
        active = true;
        break;
    }

    return ChargeThermalAudit(
      thermalBand: band,
      deliverablePowerKw: double.parse(deliverableKw.toStringAsFixed(1)),
      powerThrottlePercentage: double.parse(throttlePercent.clamp(0.0, 100.0).toStringAsFixed(1)),
      preconditioningMinutesRequired: precondMinutes,
      preconditioningEnergyCostKwh: double.parse(precondKwh.toStringAsFixed(2)),
      estimatedSessionMinutesSaved: minutesSaved,
      recommendation: recommendation,
      preconditioningActive: active,
    );
  }
}
