import 'dart:math';

/// A Time-of-Use (TOU) electricity grid tariff rate bracket.
class TouTariffBracket {
  final String name;
  final int startHour; // 0 to 23
  final int endHour;   // 0 to 23
  final double ratePerKwhUsd;
  final bool isOffPeak;

  const TouTariffBracket({
    required this.name,
    required this.startHour,
    required this.endHour,
    required this.ratePerKwhUsd,
    required this.isOffPeak,
  });
}

/// Consolidated smart charging schedule and utility savings projection.
class SmartChargingPlan {
  final double currentSocPercent;
  final double targetSocPercent;
  final double batteryCapacityKwh;
  final double energyNeededKwh;
  final double chargerPowerKw;
  final double chargeDurationHours;
  final int optimalStartHour;
  final int plannedDepartureHour;
  final double unmanagedPeakCostUsd;
  final double smartScheduledCostUsd;
  final double netSavingsUsd;
  final double savingsPercentage;
  final bool isPreconditioningScheduled;

  const SmartChargingPlan({
    required this.currentSocPercent,
    required this.targetSocPercent,
    required this.batteryCapacityKwh,
    required this.energyNeededKwh,
    required this.chargerPowerKw,
    required this.chargeDurationHours,
    required this.optimalStartHour,
    required this.plannedDepartureHour,
    required this.unmanagedPeakCostUsd,
    required this.smartScheduledCostUsd,
    required this.netSavingsUsd,
    required this.savingsPercentage,
    required this.isPreconditioningScheduled,
  });
}

/// Enterprise EV Smart Charging & Time-of-Use (TOU) Grid Tariff Scheduler.
class EvSmartChargingService {
  const EvSmartChargingService();

  /// Standard enterprise commercial EV fleet TOU brackets:
  /// - Super Off-Peak: 00:00 - 06:00 ($0.08/kWh)
  /// - Standard Off-Peak: 06:00 - 16:00 ($0.15/kWh)
  /// - Peak Demand: 16:00 - 21:00 ($0.38/kWh)
  /// - Evening Off-Peak: 21:00 - 24:00 ($0.16/kWh)
  static const List<TouTariffBracket> defaultBrackets = [
    TouTariffBracket(name: 'Super Off-Peak', startHour: 0, endHour: 6, ratePerKwhUsd: 0.08, isOffPeak: true),
    TouTariffBracket(name: 'Mid-Day Standard', startHour: 6, endHour: 16, ratePerKwhUsd: 0.15, isOffPeak: false),
    TouTariffBracket(name: 'On-Peak Demand', startHour: 16, endHour: 21, ratePerKwhUsd: 0.38, isOffPeak: false),
    TouTariffBracket(name: 'Night Shoulder', startHour: 21, endHour: 24, ratePerKwhUsd: 0.16, isOffPeak: true),
  ];

  /// Plans optimal charging window prior to scheduled departure.
  SmartChargingPlan computeChargingPlan({
    required double currentSocPercent,
    required double targetSocPercent,
    double batteryCapacityKwh = 75.0,
    double chargerPowerKw = 11.0, // Standard 3-phase AC Level 2 charger
    int plannedDepartureHour = 7, // 07:00 AM departure
    List<TouTariffBracket> brackets = defaultBrackets,
    bool enablePreconditioning = true,
  }) {
    final neededSoc = max(0.0, targetSocPercent - currentSocPercent);
    final energyNeededKwh = (neededSoc / 100.0) * batteryCapacityKwh;
    final durationHours = energyNeededKwh / (chargerPowerKw > 0 ? chargerPowerKw : 1.0);

    // Unmanaged charging cost (assumes plugging in immediately at 17:00 peak)
    const peakRate = 0.38;
    final unmanagedCost = energyNeededKwh * peakRate;

    // Optimal charging: finishes just before departure (e.g., 07:00) during super-off-peak (00:00 - 06:00)
    int durationCeil = durationHours.ceil();
    int optimalStart = (plannedDepartureHour - durationCeil);
    if (optimalStart < 0) optimalStart += 24;

    // Smart rate (mainly super off-peak @ $0.08/kWh)
    const offPeakRate = 0.08;
    final smartCost = energyNeededKwh * offPeakRate;
    final netSavings = max(0.0, unmanagedCost - smartCost);
    final savingsPct = unmanagedCost > 0 ? (netSavings / unmanagedCost) * 100.0 : 0.0;

    return SmartChargingPlan(
      currentSocPercent: currentSocPercent,
      targetSocPercent: targetSocPercent,
      batteryCapacityKwh: batteryCapacityKwh,
      energyNeededKwh: double.parse(energyNeededKwh.toStringAsFixed(1)),
      chargerPowerKw: chargerPowerKw,
      chargeDurationHours: double.parse(durationHours.toStringAsFixed(1)),
      optimalStartHour: optimalStart,
      plannedDepartureHour: plannedDepartureHour,
      unmanagedPeakCostUsd: double.parse(unmanagedCost.toStringAsFixed(2)),
      smartScheduledCostUsd: double.parse(smartCost.toStringAsFixed(2)),
      netSavingsUsd: double.parse(netSavings.toStringAsFixed(2)),
      savingsPercentage: double.parse(savingsPct.toStringAsFixed(1)),
      isPreconditioningScheduled: enablePreconditioning,
    );
  }
}
