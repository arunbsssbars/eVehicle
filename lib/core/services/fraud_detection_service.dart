import '../models/journey.dart';

enum FraudAnomalyType {
  odometerRollback('ROLLBACK', 'Odometer Rollback Detected', 0xFFDC2626),
  gpsVariance('GPS_VARIANCE', 'GPS vs Odometer Variance (>25%)', 0xFFEA580C),
  implausibleSpeed('SPEED_ANOMALY', 'Implausible Speed / Duration', 0xFFD97706),
  overlappingJourney('OVERLAP', 'Concurrent Overlapping Journey', 0xFF7C3AED);

  final String code;
  final String label;
  final int colorValue;
  const FraudAnomalyType(this.code, this.label, this.colorValue);
}

enum AnomalySeverity {
  critical('CRITICAL', 'Critical', 0xFFDC2626),
  warning('WARNING', 'Warning', 0xFFEA580C),
  info('INFO', 'Notice', 0xFF0284C7);

  final String code;
  final String label;
  final int colorValue;
  const AnomalySeverity(this.code, this.label, this.colorValue);
}

class FraudAlert {
  final String id;
  final String journeyId;
  final String vehicleId;
  final String vehicleRegistration;
  final String driverName;
  final FraudAnomalyType type;
  final AnomalySeverity severity;
  final String title;
  final String description;
  final double? discrepancyValue;
  final DateTime detectedAt;
  final bool isResolved;

  const FraudAlert({
    required this.id,
    required this.journeyId,
    required this.vehicleId,
    required this.vehicleRegistration,
    required this.driverName,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    this.discrepancyValue,
    required this.detectedAt,
    this.isResolved = false,
  });

  FraudAlert copyWith({
    bool? isResolved,
  }) {
    return FraudAlert(
      id: id,
      journeyId: journeyId,
      vehicleId: vehicleId,
      vehicleRegistration: vehicleRegistration,
      driverName: driverName,
      type: type,
      severity: severity,
      title: title,
      description: description,
      discrepancyValue: discrepancyValue,
      detectedAt: detectedAt,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}

class FraudDetectionService {
  FraudDetectionService._();
  static final FraudDetectionService instance = FraudDetectionService._();

  /// Scans a collection of journeys and returns all detected fraud and anomaly alerts.
  List<FraudAlert> scanJourneys(List<Journey> journeys) {
    final alerts = <FraudAlert>[];

    // Group journeys by vehicle
    final vehicleMap = <String, List<Journey>>{};
    for (final j in journeys) {
      vehicleMap.putIfAbsent(j.vehicleId, () => []).add(j);
    }

    // 1. Scan each vehicle's chronological journey chain for odometer rollbacks
    vehicleMap.forEach((vehicleId, vJourneys) {
      // Sort chronologically
      vJourneys.sort((a, b) => a.journeyDate.compareTo(b.journeyDate));

      for (int i = 1; i < vJourneys.length; i++) {
        final prev = vJourneys[i - 1];
        final curr = vJourneys[i];

        if (prev.closingOdometer != null && curr.openingOdometer < prev.closingOdometer!) {
          final rollbackKm = prev.closingOdometer! - curr.openingOdometer;
          alerts.add(
            FraudAlert(
              id: 'FA-RB-${curr.id}',
              journeyId: curr.id,
              vehicleId: vehicleId,
              vehicleRegistration: curr.vehicleRegistration,
              driverName: curr.driverName,
              type: FraudAnomalyType.odometerRollback,
              severity: AnomalySeverity.critical,
              title: 'Odometer Rollback (${rollbackKm.toStringAsFixed(1)} km)',
              description:
                  'Journey started at odometer ${curr.openingOdometer.toStringAsFixed(1)} km, but previous journey closed at ${prev.closingOdometer!.toStringAsFixed(1)} km.',
              discrepancyValue: rollbackKm,
              detectedAt: curr.journeyDate,
            ),
          );
        }
      }
    });

    // 2. Scan individual journeys for GPS variance and implausible speed
    for (final j in journeys) {
      // GPS vs Odometer variance check
      if (j.officialDistance != null &&
          j.gpsDistance != null &&
          j.officialDistance! > 5.0 &&
          j.gpsDistance! > 0.5) {
        final diff = (j.officialDistance! - j.gpsDistance!).abs();
        final varianceRatio = diff / j.officialDistance!;

        if (varianceRatio >= 0.25) {
          final percent = (varianceRatio * 100).toStringAsFixed(0);
          alerts.add(
            FraudAlert(
              id: 'FA-GPS-${j.id}',
              journeyId: j.id,
              vehicleId: j.vehicleId,
              vehicleRegistration: j.vehicleRegistration,
              driverName: j.driverName,
              type: FraudAnomalyType.gpsVariance,
              severity: varianceRatio >= 0.40 ? AnomalySeverity.critical : AnomalySeverity.warning,
              title: 'GPS Variance ($percent% difference)',
              description:
                  'Logged odometer distance is ${j.officialDistance!.toStringAsFixed(1)} km, but recorded GPS distance is only ${j.gpsDistance!.toStringAsFixed(1)} km.',
              discrepancyValue: diff,
              detectedAt: j.journeyDate,
            ),
          );
        }
      }

      // Implausible speed check (e.g. > 140 km/h or < 2 min for > 15 km)
      if (j.endTime != null && j.officialDistance != null && j.officialDistance! > 10.0) {
        final durationMinutes = j.endTime!.difference(j.startTime).inMinutes;
        if (durationMinutes > 0) {
          final avgSpeedKmh = (j.officialDistance! / durationMinutes) * 60;
          if (avgSpeedKmh > 140.0) {
            alerts.add(
              FraudAlert(
                id: 'FA-SPD-${j.id}',
                journeyId: j.id,
                vehicleId: j.vehicleId,
                vehicleRegistration: j.vehicleRegistration,
                driverName: j.driverName,
                type: FraudAnomalyType.implausibleSpeed,
                severity: AnomalySeverity.warning,
                title: 'Unrealistic Speed (${avgSpeedKmh.toStringAsFixed(0)} km/h)',
                description:
                    'Trip of ${j.officialDistance!.toStringAsFixed(1)} km logged in only $durationMinutes minutes (average speed: ${avgSpeedKmh.toStringAsFixed(0)} km/h).',
                discrepancyValue: avgSpeedKmh,
                detectedAt: j.journeyDate,
              ),
            );
          }
        }
      }
    }

    // Sort by severity (critical first) then newest detected
    alerts.sort((a, b) {
      if (a.severity == AnomalySeverity.critical && b.severity != AnomalySeverity.critical) {
        return -1;
      }
      if (b.severity == AnomalySeverity.critical && a.severity != AnomalySeverity.critical) {
        return 1;
      }
      return b.detectedAt.compareTo(a.detectedAt);
    });

    return alerts;
  }
}
