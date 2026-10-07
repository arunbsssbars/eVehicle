import 'dart:math';

/// A discrete cabin sound level reading measured in A-weighted decibels (dB(A)).
class NoiseSample {
  final DateTime timestamp;
  final double decibelsDba;
  final double speedKmph;

  const NoiseSample({
    required this.timestamp,
    required this.decibelsDba,
    required this.speedKmph,
  });
}

/// Consolidated audit of occupational noise exposure and cabin acoustic ergonomics.
class NoiseExposureAudit {
  final double averageDecibelsDba;
  final double peakDecibelsDba;
  final double twa8HourDba; // 8-hour Time-Weighted Average equivalent
  final double oshaDosePercentage; // 100% = maximum statutory 85 dBA TWA limit
  final bool isExceedingSafetyThreshold;
  final String acousticRating; // QUIET, NOMINAL, ELEVATED, HAZARDOUS
  final String advisory;

  const NoiseExposureAudit({
    required this.averageDecibelsDba,
    required this.peakDecibelsDba,
    required this.twa8HourDba,
    required this.oshaDosePercentage,
    required this.isExceedingSafetyThreshold,
    required this.acousticRating,
    required this.advisory,
  });
}

/// Enterprise Cabin Noise & Driver Auditory Ergonomics Engine.
class NoiseErgonomicsService {
  const NoiseErgonomicsService();

  /// Evaluates decibel samples and derives OSHA/EU occupational noise dosimetry.
  NoiseExposureAudit evaluateNoiseTelemetry(List<NoiseSample> samples) {
    if (samples.isEmpty) {
      return const NoiseExposureAudit(
        averageDecibelsDba: 0.0,
        peakDecibelsDba: 0.0,
        twa8HourDba: 0.0,
        oshaDosePercentage: 0.0,
        isExceedingSafetyThreshold: false,
        acousticRating: 'QUIET',
        advisory: 'NOMINAL: No acoustic telemetry recorded.',
      );
    }

    double peak = 0.0;
    double energySum = 0.0;

    for (final s in samples) {
      if (s.decibelsDba > peak) peak = s.decibelsDba;
      // Convert dB(A) to acoustic power for correct logarithmic averaging: 10^(dB/10)
      energySum += pow(10.0, s.decibelsDba / 10.0);
    }

    // Leq (Equivalent Continuous Sound Level)
    final meanEnergy = energySum / samples.length;
    final leqDba = 10.0 * (log(meanEnergy) / ln10);

    // OSHA 5-dB exchange rate dosimetry relative to 85 dBA 8-hour action level:
    // Dose = (Time / ReferenceTime) * 2^((Leq - 85) / 5) * 100%
    // Assuming sample window represents ~2 hours of driving:
    final doseFraction = (samples.length / 100.0) * pow(2.0, (leqDba - 85.0) / 5.0);
    final dosePercent = (doseFraction * 100.0).clamp(0.0, 300.0);

    // TWA calculation: 85 + 16.61 * log10(Dose / 100)
    double twa = (dosePercent > 0.0)
        ? (85.0 + 16.61 * (log(dosePercent / 100.0) / ln10))
        : leqDba;
    twa = twa.clamp(40.0, 115.0);

    final isBreach = leqDba >= 85.0 || dosePercent >= 100.0;

    String rating;
    String advisory;

    if (leqDba >= 88.0 || dosePercent >= 120.0) {
      rating = 'HAZARDOUS';
      advisory = 'AUDITORY RISK: Sustained noise exceeds 85 dB(A). Hearing protection mandated.';
    } else if (leqDba >= 80.0) {
      rating = 'ELEVATED';
      advisory = 'ELEVATED CABIN NOISE: Inspect exhaust system and door weatherstrips for rattles.';
    } else if (leqDba >= 68.0) {
      rating = 'NOMINAL';
      advisory = 'STANDARD CABIN: Normal highway road and wind noise within comfortable limits.';
    } else {
      rating = 'QUIET';
      advisory = 'OPTIMAL ACOUSTICS: EV or premium soundproof cabin operating whisper-quiet.';
    }

    return NoiseExposureAudit(
      averageDecibelsDba: double.parse(leqDba.toStringAsFixed(1)),
      peakDecibelsDba: double.parse(peak.toStringAsFixed(1)),
      twa8HourDba: double.parse(twa.toStringAsFixed(1)),
      oshaDosePercentage: double.parse(dosePercent.toStringAsFixed(1)),
      isExceedingSafetyThreshold: isBreach,
      acousticRating: rating,
      advisory: advisory,
    );
  }
}
