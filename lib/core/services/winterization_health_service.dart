import 'dart:math';

/// Base formulation of engine coolant / antifreeze.
enum CoolantType {
  ethyleneGlycol, // Standard commercial heavy-duty (50/50 protects to -37°C)
  propyleneGlycol, // Low-toxicity environmentally benign (50/50 protects to -32°C)
}

/// Consolidated audit of vehicle sub-zero winterization and anti-gel safeguards.
class WinterizationAudit {
  final double glycolConcentrationPercent;
  final double freezeProtectionTempCelsius;
  final double forecastMinAmbientTempCelsius;
  final double safetyMarginCelsius;
  final bool isFreezeProtected;
  final bool areGlowPlugsOperational;
  final bool isFuelAntiGelRequired;
  final bool isBlockHeaterRecommended;
  final String readinessRating; // ARCTIC-READY, SUFFICIENT, MARGINAL, CRITICAL-FREEZE-RISK
  final String advisory;

  const WinterizationAudit({
    required this.glycolConcentrationPercent,
    required this.freezeProtectionTempCelsius,
    required this.forecastMinAmbientTempCelsius,
    required this.safetyMarginCelsius,
    required this.isFreezeProtected,
    required this.areGlowPlugsOperational,
    required this.isFuelAntiGelRequired,
    required this.isBlockHeaterRecommended,
    required this.readinessRating,
    required this.advisory,
  });
}

/// Enterprise Sub-Zero Fleet Winterization & Antifreeze Freeze-Point Guard.
class WinterizationHealthService {
  const WinterizationHealthService();

  /// Calculates freeze-point protection temperature from refractometer glycol percentage.
  double calculateFreezePoint(double glycolPercent, CoolantType type) {
    final g = glycolPercent.clamp(0.0, 70.0);
    if (g <= 0.0) return 0.0;

    // Empirical formula for freeze depression
    // 33% ~ -18°C, 50% ~ -37°C, 60% ~ -52°C
    if (type == CoolantType.ethyleneGlycol) {
      if (g <= 50.0) {
        return -(g * 0.74);
      } else {
        return -37.0 - ((g - 50.0) * 1.4);
      }
    } else {
      // Propylene glycol is slightly less dense in freeze depression
      return -(g * 0.65);
    }
  }

  /// Evaluates vehicle winter readiness against expected ambient temperatures.
  WinterizationAudit evaluateWinterization({
    required double glycolConcentrationPercent,
    required double forecastMinAmbientTempCelsius,
    CoolantType coolantType = CoolantType.ethyleneGlycol,
    bool glowPlugsFunctional = true,
    bool isDieselEngine = true,
  }) {
    final freezePoint = calculateFreezePoint(glycolConcentrationPercent, coolantType);
    // Safety margin = freezePoint - ambient (e.g. freezePoint -37°C, ambient -20°C -> safety margin 17°C)
    final margin = (forecastMinAmbientTempCelsius - freezePoint);
    final isProtected = freezePoint <= (forecastMinAmbientTempCelsius - 5.0); // 5°C safety buffer

    // Diesel fuel gels (wax crystals) around -8°C to -12°C without additives
    final needAntiGel = isDieselEngine && forecastMinAmbientTempCelsius <= -5.0;
    // Block heater recommended when ambient drops below -15°C
    final needBlockHeater = forecastMinAmbientTempCelsius <= -15.0;

    String rating;
    String advisory;

    if (!isProtected) {
      rating = 'CRITICAL-FREEZE-RISK';
      advisory = 'ENGINE BLOCK AT RISK: Coolant freeze point (${freezePoint.toStringAsFixed(1)}°C) above forecast low (${forecastMinAmbientTempCelsius.toStringAsFixed(1)}°C). Drain and refill.';
    } else if (!glowPlugsFunctional) {
      rating = 'MARGINAL';
      advisory = 'GLOW PLUG FAULT: Sub-zero cold cranking will fail. Service pre-heat circuit.';
    } else if (needBlockHeater) {
      rating = 'ARCTIC-READY';
      advisory = 'EXTREME COLD: Plug in 120V block heater 2 hours before departure. Fuel anti-gel mandatory.';
    } else {
      rating = 'SUFFICIENT';
      advisory = 'WINTER READY: Coolant freeze point safe down to ${freezePoint.toStringAsFixed(1)}°C with ${glycolConcentrationPercent.toInt()}% glycol.';
    }

    return WinterizationAudit(
      glycolConcentrationPercent: glycolConcentrationPercent,
      freezeProtectionTempCelsius: double.parse(freezePoint.toStringAsFixed(1)),
      forecastMinAmbientTempCelsius: double.parse(forecastMinAmbientTempCelsius.toStringAsFixed(1)),
      safetyMarginCelsius: double.parse(max(0.0, margin).toStringAsFixed(1)),
      isFreezeProtected: isProtected,
      areGlowPlugsOperational: glowPlugsFunctional,
      isFuelAntiGelRequired: needAntiGel,
      isBlockHeaterRecommended: needBlockHeater,
      readinessRating: rating,
      advisory: advisory,
    );
  }
}
