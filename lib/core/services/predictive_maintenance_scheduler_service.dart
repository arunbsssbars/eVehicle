import 'dart:math';

/// Vehicle component classification.
enum FleetComponent {
  engineOil,
  brakePads,
  transmissionFluid,
  engineCoolant,
  timingBelt,
  airFilter,
}

/// Degradation health of a specific component.
class ComponentWearStatus {
  final FleetComponent component;
  final String componentName;
  final double remainingHealthPercent; // 0 to 100
  final int remainingSafeKm;
  final bool isReplacementUrgent;
  final double estimatedCost;

  const ComponentWearStatus({
    required this.component,
    required this.componentName,
    required this.remainingHealthPercent,
    required this.remainingSafeKm,
    required this.isReplacementUrgent,
    required this.estimatedCost,
  });
}

/// Telematics driving and operating context profile.
class VehicleUsageContext {
  final String vehicleId;
  final String registrationNumber;
  final double currentOdometerKm;
  final double kmSinceLastService;
  final double engineIdleHours;
  final double harshEventRatePer100Km; // harsh braking/accel rate
  final bool operatesInSevereDust; // dusty/mining/construction terrain
  final double avgDailyKm;

  const VehicleUsageContext({
    required this.vehicleId,
    required this.registrationNumber,
    required this.currentOdometerKm,
    required this.kmSinceLastService,
    this.engineIdleHours = 20.0,
    this.harshEventRatePer100Km = 3.5,
    this.operatesInSevereDust = false,
    this.avgDailyKm = 80.0,
  });
}

/// Predictive maintenance schedule forecast output.
class MaintenanceScheduleForecast {
  final String vehicleId;
  final double overallVehicleHealthScore; // 0 to 100
  final int daysUntilNextService;
  final DateTime estimatedNextServiceDate;
  final double totalEstimatedServiceCost;
  final bool isImmediateServiceRequired;
  final List<ComponentWearStatus> componentStatuses;

  const MaintenanceScheduleForecast({
    required this.vehicleId,
    required this.overallVehicleHealthScore,
    required this.daysUntilNextService,
    required this.estimatedNextServiceDate,
    required this.totalEstimatedServiceCost,
    required this.isImmediateServiceRequired,
    required this.componentStatuses,
  });
}

/// Dynamic Fleet Preventive Maintenance Predictive Scheduler.
class PredictiveMaintenanceSchedulerService {
  const PredictiveMaintenanceSchedulerService();

  // Baseline service intervals (km)
  static const Map<FleetComponent, double> _baselineIntervals = {
    FleetComponent.engineOil: 10000.0,
    FleetComponent.brakePads: 30000.0,
    FleetComponent.airFilter: 15000.0,
    FleetComponent.engineCoolant: 40000.0,
    FleetComponent.transmissionFluid: 50000.0,
    FleetComponent.timingBelt: 80000.0,
  };

  // Replacement costs
  static const Map<FleetComponent, double> _replacementCosts = {
    FleetComponent.engineOil: 2800.0,
    FleetComponent.brakePads: 4500.0,
    FleetComponent.airFilter: 900.0,
    FleetComponent.engineCoolant: 1800.0,
    FleetComponent.transmissionFluid: 6500.0,
    FleetComponent.timingBelt: 12000.0,
  };

  /// Computes wear degradation and predictive maintenance forecast.
  MaintenanceScheduleForecast forecastMaintenance({
    required VehicleUsageContext context,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();

    // Harshness wear factor:
    // Base 1.0 + harsh event penalty + dust penalty + idle hours penalty
    double wearFactor = 1.0;
    wearFactor += (context.harshEventRatePer100Km / 10.0) * 0.4;
    if (context.operatesInSevereDust) {
      wearFactor += 0.35;
    }
    wearFactor += (context.engineIdleHours / 50.0) * 0.15;

    final List<ComponentWearStatus> components = [];
    double lowestRemainingKm = double.infinity;
    double sumHealth = 0.0;
    double totalCost = 0.0;
    bool immediateNeeded = false;

    for (final comp in FleetComponent.values) {
      final baseInterval = _baselineIntervals[comp] ?? 20000.0;
      final cost = _replacementCosts[comp] ?? 2000.0;

      // Accelerated wear km
      final effectiveUsedKm = context.kmSinceLastService * wearFactor;
      final remainingKm = max(0.0, baseInterval - effectiveUsedKm);
      final healthPercent = max(0.0, min(100.0, (remainingKm / baseInterval) * 100.0));

      final bool urgent = healthPercent <= 15.0 || remainingKm <= 500.0;
      if (urgent) {
        immediateNeeded = true;
        totalCost += cost;
      }

      if (remainingKm < lowestRemainingKm) {
        lowestRemainingKm = remainingKm;
      }

      sumHealth += healthPercent;

      components.add(ComponentWearStatus(
        component: comp,
        componentName: _getComponentName(comp),
        remainingHealthPercent: double.parse(healthPercent.toStringAsFixed(1)),
        remainingSafeKm: remainingKm.toInt(),
        isReplacementUrgent: urgent,
        estimatedCost: cost,
      ));
    }

    final overallHealth = sumHealth / FleetComponent.values.length;
    final dailyKm = max(10.0, context.avgDailyKm);
    final daysUntilService = max(1, (lowestRemainingKm / dailyKm).round());
    final nextServiceDate = now.add(Duration(days: daysUntilService));

    return MaintenanceScheduleForecast(
      vehicleId: context.vehicleId,
      overallVehicleHealthScore: double.parse(overallHealth.toStringAsFixed(1)),
      daysUntilNextService: daysUntilService,
      estimatedNextServiceDate: nextServiceDate,
      totalEstimatedServiceCost: totalCost > 0 ? totalCost : 2800.0,
      isImmediateServiceRequired: immediateNeeded,
      componentStatuses: components,
    );
  }

  String _getComponentName(FleetComponent component) {
    switch (component) {
      case FleetComponent.engineOil:
        return 'Engine Synthetic Oil';
      case FleetComponent.brakePads:
        return 'Brake Rotor Pads';
      case FleetComponent.airFilter:
        return 'Engine Air Intake Filter';
      case FleetComponent.engineCoolant:
        return 'Radiator Engine Coolant';
      case FleetComponent.transmissionFluid:
        return 'Automatic Transmission Fluid';
      case FleetComponent.timingBelt:
        return 'Engine Timing Cam Belt';
    }
  }
}
