import 'dart:math';

/// Alert levels for driver alertness and microsleep risk.
enum DrowsinessRiskLevel {
  normal,
  mildFatigue,
  highFatigue,
  criticalMicrosleepRisk,
}

/// Telemetry reading from driver biometric sensors (smartwatch/steering sensors).
class BiometricPulseSample {
  final DateTime timestamp;
  final double heartRateBpm;
  final double rrIntervalMs; // R-to-R peak interval in milliseconds

  const BiometricPulseSample({
    required this.timestamp,
    required this.heartRateBpm,
    required this.rrIntervalMs,
  });
}

/// Comprehensive physiological alertness audit.
class DriverDrowsinessAudit {
  final double averageBpm;
  final double rmssdMs; // Root Mean Square of Successive Differences (HRV)
  final double fatigueIndexPercent; // 0 to 100%
  final DrowsinessRiskLevel riskLevel;
  final String recommendation;
  final bool requiresImmediateRestBreak;

  const DriverDrowsinessAudit({
    required this.averageBpm,
    required this.rmssdMs,
    required this.fatigueIndexPercent,
    required this.riskLevel,
    required this.recommendation,
    required this.requiresImmediateRestBreak,
  });
}

/// Service that analyzes Heart Rate Variability (HRV) to detect autonomic drowsiness.
class DriverDrowsinessService {
  const DriverDrowsinessService();

  /// Evaluates a stream of R-R intervals to compute RMSSD and detect drowsiness.
  DriverDrowsinessAudit evaluateAlertness(List<BiometricPulseSample> samples) {
    if (samples.length < 2) {
      return const DriverDrowsinessAudit(
        averageBpm: 72.0,
        rmssdMs: 42.0,
        fatigueIndexPercent: 10.0,
        riskLevel: DrowsinessRiskLevel.normal,
        recommendation: 'Baseline calibration in progress. Maintain regular rest intervals.',
        requiresImmediateRestBreak: false,
      );
    }

    final totalBpm = samples.fold<double>(0.0, (acc, s) => acc + s.heartRateBpm);
    final avgBpm = totalBpm / samples.length;

    // Calculate RMSSD from consecutive RR intervals
    double sumSquaredDiffs = 0.0;
    for (int i = 1; i < samples.length; i++) {
      final diff = samples[i].rrIntervalMs - samples[i - 1].rrIntervalMs;
      sumSquaredDiffs += diff * diff;
    }
    final rmssd = sqrt(sumSquaredDiffs / (samples.length - 1));

    // High RMSSD during monotonous driving indicates parasympathetic dominance (drowsiness)
    // Low BPM (< 55) coupled with elevated RMSSD (> 65) indicates nodding off / microsleep onset
    double fatigueScore = 0.0;
    if (avgBpm < 58.0) {
      fatigueScore += (58.0 - avgBpm) * 3.5;
    }
    if (rmssd > 55.0) {
      fatigueScore += (rmssd - 55.0) * 1.8;
    } else if (rmssd < 20.0) {
      // Very low HRV also indicates extreme acute stress / exhaustion
      fatigueScore += (20.0 - rmssd) * 2.0;
    }

    final fatiguePercent = fatigueScore.clamp(0.0, 100.0);

    DrowsinessRiskLevel level;
    String recommendation;
    bool immediateBreak;

    if (fatiguePercent >= 75.0) {
      level = DrowsinessRiskLevel.criticalMicrosleepRisk;
      recommendation = 'CRITICAL: Severe microsleep onset detected! Pull over immediately at next safe rest area.';
      immediateBreak = true;
    } else if (fatiguePercent >= 50.0) {
      level = DrowsinessRiskLevel.highFatigue;
      recommendation = 'HIGH FATIGUE: Drowsiness indicators elevated. Plan a 15-minute rest break within 15 km.';
      immediateBreak = true;
    } else if (fatiguePercent >= 25.0) {
      level = DrowsinessRiskLevel.mildFatigue;
      recommendation = 'MILD FATIGUE: Early signs of tiredness. Ensure cabin airflow and hydration.';
      immediateBreak = false;
    } else {
      level = DrowsinessRiskLevel.normal;
      recommendation = 'OPTIMAL ALERTNESS: Heart rate variability within safe operational parameters.';
      immediateBreak = false;
    }

    return DriverDrowsinessAudit(
      averageBpm: double.parse(avgBpm.toStringAsFixed(1)),
      rmssdMs: double.parse(rmssd.toStringAsFixed(1)),
      fatigueIndexPercent: double.parse(fatiguePercent.toStringAsFixed(1)),
      riskLevel: level,
      recommendation: recommendation,
      requiresImmediateRestBreak: immediateBreak,
    );
  }
}
