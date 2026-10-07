import 'dart:math';

/// Perishable cargo preservation classification.
enum CargoCategory {
  deepFreeze, // -25°C to -18°C (Frozen foods, seafood)
  refrigeratedPharma, // +2°C to +8°C (Vaccines, biologics, dairy)
  controlledAmbient, // +15°C to +25°C (Solid dose pharma, produce)
}

/// Temperature and humidity reading from telematics probe.
class TemperatureSample {
  final DateTime timestamp;
  final double temperatureC;
  final double humidityPercent;
  final bool isReeferUnitActive;
  final bool isDoorOpen;

  const TemperatureSample({
    required this.timestamp,
    required this.temperatureC,
    required this.humidityPercent,
    this.isReeferUnitActive = true,
    this.isDoorOpen = false,
  });
}

/// Temperature specification range.
class CargoThermalSpec {
  final CargoCategory category;
  final String label;
  final double minTempC;
  final double maxTempC;
  final double maxHumidityPercent;

  const CargoThermalSpec({
    required this.category,
    required this.label,
    required this.minTempC,
    required this.maxTempC,
    this.maxHumidityPercent = 70.0,
  });

  static const CargoThermalSpec deepFreeze = CargoThermalSpec(
    category: CargoCategory.deepFreeze,
    label: 'Deep Freeze (-25°C to -18°C)',
    minTempC: -25.0,
    maxTempC: -18.0,
  );

  static const CargoThermalSpec refrigeratedPharma = CargoThermalSpec(
    category: CargoCategory.refrigeratedPharma,
    label: 'Cold Chain Pharma (+2°C to +8°C)',
    minTempC: 2.0,
    maxTempC: 8.0,
  );

  static const CargoThermalSpec controlledAmbient = CargoThermalSpec(
    category: CargoCategory.controlledAmbient,
    label: 'Controlled Ambient (+15°C to +25°C)',
    minTempC: 15.0,
    maxTempC: 25.0,
  );
}

/// Audit report for perishable cargo journey.
class ColdChainAuditReport {
  final String cargoId;
  final CargoCategory category;
  final double meanTemperatureC;
  final double meanKineticTemperatureC; // MKT
  final double minRecordedTempC;
  final double maxRecordedTempC;
  final int totalExcursionMinutes;
  final int doorOpeningsCount;
  final double spoilageRiskScore; // 0 (Prism safe) to 100 (Compromised)
  final bool isCompliant;
  final String complianceVerdict;

  const ColdChainAuditReport({
    required this.cargoId,
    required this.category,
    required this.meanTemperatureC,
    required this.meanKineticTemperatureC,
    required this.minRecordedTempC,
    required this.maxRecordedTempC,
    required this.totalExcursionMinutes,
    required this.doorOpeningsCount,
    required this.spoilageRiskScore,
    required this.isCompliant,
    required this.complianceVerdict,
  });
}

/// Cold-Chain Temperature & Humidity IoT Telemetry Quality Guard.
class ColdChainTelemetryService {
  const ColdChainTelemetryService();

  /// Evaluates sensor stream samples against pharma/food cold-chain standards.
  ColdChainAuditReport auditColdChain({
    required String cargoId,
    required CargoCategory category,
    required List<TemperatureSample> samples,
    int sampleIntervalMinutes = 5,
  }) {
    if (samples.isEmpty) {
      return ColdChainAuditReport(
        cargoId: cargoId,
        category: category,
        meanTemperatureC: 0,
        meanKineticTemperatureC: 0,
        minRecordedTempC: 0,
        maxRecordedTempC: 0,
        totalExcursionMinutes: 0,
        doorOpeningsCount: 0,
        spoilageRiskScore: 0,
        isCompliant: true,
        complianceVerdict: 'No Telemetry Samples Available',
      );
    }

    final spec = _getSpec(category);

    double sumTemp = 0.0;
    double minTemp = samples.first.temperatureC;
    double maxTemp = samples.first.temperatureC;
    int excursionCount = 0;
    int doorOpenCount = 0;

    // For Mean Kinetic Temperature (MKT):
    // Arrhenius activation energy ΔH / R ≈ 10,000 K for pharmaceuticals
    const deltaHOverR = 10000.0;
    double mktSum = 0.0;

    for (final s in samples) {
      final t = s.temperatureC;
      sumTemp += t;
      if (t < minTemp) minTemp = t;
      if (t > maxTemp) maxTemp = t;

      if (t < spec.minTempC || t > spec.maxTempC) {
        excursionCount++;
      }

      if (s.isDoorOpen) {
        doorOpenCount++;
      }

      final kelvin = t + 273.15;
      if (kelvin > 0) {
        mktSum += exp(-deltaHOverR / kelvin);
      }
    }

    final meanTemp = sumTemp / samples.length;
    final totalExcursionMinutes = excursionCount * sampleIntervalMinutes;

    // Calculate MKT
    double mkt = meanTemp;
    if (mktSum > 0) {
      final avgExp = mktSum / samples.length;
      final mktKelvin = -deltaHOverR / log(avgExp);
      mkt = mktKelvin - 273.15;
    }

    // Spoilage risk calculation
    // Excursion tolerance: < 15 min = minimal, > 60 min = severe
    double riskScore = 0.0;
    if (totalExcursionMinutes > 0) {
      riskScore += min(70.0, totalExcursionMinutes * 1.5);
    }
    if (doorOpenCount > 4) {
      riskScore += (doorOpenCount - 4) * 4.0;
    }
    // High temperature delta penalty
    if (maxTemp > spec.maxTempC) {
      final deltaMax = maxTemp - spec.maxTempC;
      riskScore += deltaMax * 5.0;
    }
    riskScore = riskScore.clamp(0.0, 100.0);

    final bool isCompliant = riskScore < 25.0 && totalExcursionMinutes <= 30;
    final String verdict = isCompliant
        ? 'Cold-Chain Integrity Certified (Compliant)'
        : (riskScore > 60.0
            ? 'CRITICAL EXCURSION: Cargo Integrity Compromised'
            : 'Cautionary Thermal Excursion Logged');

    return ColdChainAuditReport(
      cargoId: cargoId,
      category: category,
      meanTemperatureC: double.parse(meanTemp.toStringAsFixed(1)),
      meanKineticTemperatureC: double.parse(mkt.toStringAsFixed(1)),
      minRecordedTempC: double.parse(minTemp.toStringAsFixed(1)),
      maxRecordedTempC: double.parse(maxTemp.toStringAsFixed(1)),
      totalExcursionMinutes: totalExcursionMinutes,
      doorOpeningsCount: doorOpenCount,
      spoilageRiskScore: double.parse(riskScore.toStringAsFixed(1)),
      isCompliant: isCompliant,
      complianceVerdict: verdict,
    );
  }

  CargoThermalSpec _getSpec(CargoCategory category) {
    switch (category) {
      case CargoCategory.deepFreeze:
        return CargoThermalSpec.deepFreeze;
      case CargoCategory.refrigeratedPharma:
        return CargoThermalSpec.refrigeratedPharma;
      case CargoCategory.controlledAmbient:
        return CargoThermalSpec.controlledAmbient;
    }
  }
}
