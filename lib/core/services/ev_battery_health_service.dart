import 'dart:math';

/// Discrete cell voltage and temperature reading in an EV traction pack.
class CellVoltageTelemetry {
  final int cellIndex;
  final double voltageVolts;
  final double tempCelsius;

  const CellVoltageTelemetry({
    required this.cellIndex,
    required this.voltageVolts,
    required this.tempCelsius,
  });
}

/// Thermal safety and cell balance condition of the EV battery pack.
enum BatteryThermalStatus {
  optimal,
  elevatedTemperature,
  cellImbalanceWarning,
  criticalThermalRunawayRisk,
}

/// Comprehensive EV high-voltage battery state-of-health and safety audit.
class BatteryHealthAudit {
  final double stateOfHealthPercent; // SoH (100% = factory new, <70% = decommission)
  final double stateOfChargePercent; // SoC
  final double minCellVoltage;
  final double maxCellVoltage;
  final double cellDeltaV; // Imbalance in volts (e.g., 0.02V is good, >0.10V is problematic)
  final double packMaxTempCelsius;
  final BatteryThermalStatus status;
  final int estimatedRemainingCycles;
  final String safetyAdvisory;

  const BatteryHealthAudit({
    required this.stateOfHealthPercent,
    required this.stateOfChargePercent,
    required this.minCellVoltage,
    required this.maxCellVoltage,
    required this.cellDeltaV,
    required this.packMaxTempCelsius,
    required this.status,
    required this.estimatedRemainingCycles,
    required this.safetyAdvisory,
  });
}

/// Enterprise Battery State-of-Health (SoH) & EV Thermal Runaway Guard.
class EvBatteryHealthService {
  const EvBatteryHealthService();

  /// Analyzes battery cell telemetry, charge cycles, and temperatures.
  BatteryHealthAudit evaluateBatteryPack({
    required List<CellVoltageTelemetry> cells,
    required int totalChargeCycleCount,
    required double stateOfChargePercent,
    double factoryCapacityKwh = 75.0,
    double currentCapacityKwh = 71.5,
  }) {
    if (cells.isEmpty) {
      return const BatteryHealthAudit(
        stateOfHealthPercent: 100.0,
        stateOfChargePercent: 0.0,
        minCellVoltage: 0.0,
        maxCellVoltage: 0.0,
        cellDeltaV: 0.0,
        packMaxTempCelsius: 25.0,
        status: BatteryThermalStatus.optimal,
        estimatedRemainingCycles: 2000,
        safetyAdvisory: 'NO DATA: No cell telemetry available.',
      );
    }

    double minV = cells.first.voltageVolts;
    double maxV = cells.first.voltageVolts;
    double maxT = cells.first.tempCelsius;

    for (final c in cells) {
      if (c.voltageVolts < minV) minV = c.voltageVolts;
      if (c.voltageVolts > maxV) maxV = c.voltageVolts;
      if (c.tempCelsius > maxT) maxT = c.tempCelsius;
    }

    final deltaV = max(0.0, maxV - minV);

    // State of Health computation: capacity ratio and cycle aging penalty
    final capacityRatio = (currentCapacityKwh / (factoryCapacityKwh > 0 ? factoryCapacityKwh : 1.0)) * 100.0;
    // Typical LFP / NMC cells lose ~0.015% SoH per full equivalent cycle
    final cycleDegradation = (totalChargeCycleCount * 0.012);
    final rawSoH = capacityRatio - (cycleDegradation * 0.2);
    final soh = rawSoH.clamp(50.0, 100.0);

    // Remaining cycles until 70% end-of-life retirement
    final remainingCycles = max(0, ((soh - 70.0) / 0.015).round());

    // Thermal runaway & safety classification
    BatteryThermalStatus status;
    String advisory;

    if (maxT >= 60.0 || (maxT >= 52.0 && deltaV >= 0.15)) {
      status = BatteryThermalStatus.criticalThermalRunawayRisk;
      advisory = 'CRITICAL THERMAL ALERT: High cell temperature (${maxT.toStringAsFixed(1)}°C). Immediate shutdown recommended.';
    } else if (deltaV >= 0.08) {
      status = BatteryThermalStatus.cellImbalanceWarning;
      advisory = 'CELL IMBALANCE: Delta-V of ${deltaV.toStringAsFixed(3)}V exceeds 80mV threshold. Cell balancing required.';
    } else if (maxT >= 45.0) {
      status = BatteryThermalStatus.elevatedTemperature;
      advisory = 'ELEVATED TEMP: Pack temperature is ${maxT.toStringAsFixed(1)}°C. BMS active cooling engaged.';
    } else {
      status = BatteryThermalStatus.optimal;
      advisory = 'NOMINAL: Traction pack cells balanced and operating within optimal thermal envelope.';
    }

    return BatteryHealthAudit(
      stateOfHealthPercent: double.parse(soh.toStringAsFixed(1)),
      stateOfChargePercent: double.parse(stateOfChargePercent.clamp(0.0, 100.0).toStringAsFixed(1)),
      minCellVoltage: double.parse(minV.toStringAsFixed(3)),
      maxCellVoltage: double.parse(maxV.toStringAsFixed(3)),
      cellDeltaV: double.parse(deltaV.toStringAsFixed(3)),
      packMaxTempCelsius: double.parse(maxT.toStringAsFixed(1)),
      status: status,
      estimatedRemainingCycles: remainingCycles,
      safetyAdvisory: advisory,
    );
  }
}
