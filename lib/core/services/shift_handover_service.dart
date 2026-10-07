import '../models/shift_handover_record.dart';

/// Service managing shift handovers, sanitization checks, and odometer discrepancies between drivers
class ShiftHandoverService {
  /// Validate odometer continuity: handover reading must match or exceed the previous logged closing odometer
  static bool validateOdometerContinuity({
    required double lastClosingOdometer,
    required double handoverOdometer,
    double allowableToleranceKm = 1.0,
  }) {
    if (handoverOdometer < (lastClosingOdometer - allowableToleranceKm)) {
      return false; // Rollback or fraudulent regression detected
    }
    return true;
  }

  /// Accept an incoming handover
  static ShiftHandoverRecord acceptHandover(ShiftHandoverRecord record) {
    return ShiftHandoverRecord(
      id: record.id,
      vehicleId: record.vehicleId,
      vehicleRegistration: record.vehicleRegistration,
      outgoingDriverId: record.outgoingDriverId,
      outgoingDriverName: record.outgoingDriverName,
      incomingDriverId: record.incomingDriverId,
      incomingDriverName: record.incomingDriverName,
      timestamp: record.timestamp,
      odometerReading: record.odometerReading,
      fuelLevelPercent: record.fuelLevelPercent,
      cleanlinessRating: record.cleanlinessRating,
      tirePressureChecked: record.tirePressureChecked,
      sanitizationCompleted: record.sanitizationCompleted,
      status: HandoverStatus.accepted,
      handoverNotes: record.handoverNotes,
    );
  }

  /// Dispute a handover (e.g. cleanliness issue, low fuel without notice, odometer mismatch)
  static ShiftHandoverRecord disputeHandover({
    required ShiftHandoverRecord record,
    required String reason,
  }) {
    return ShiftHandoverRecord(
      id: record.id,
      vehicleId: record.vehicleId,
      vehicleRegistration: record.vehicleRegistration,
      outgoingDriverId: record.outgoingDriverId,
      outgoingDriverName: record.outgoingDriverName,
      incomingDriverId: record.incomingDriverId,
      incomingDriverName: record.incomingDriverName,
      timestamp: record.timestamp,
      odometerReading: record.odometerReading,
      fuelLevelPercent: record.fuelLevelPercent,
      cleanlinessRating: record.cleanlinessRating,
      tirePressureChecked: record.tirePressureChecked,
      sanitizationCompleted: record.sanitizationCompleted,
      status: HandoverStatus.disputed,
      handoverNotes: record.handoverNotes,
      disputeReason: reason,
    );
  }
}
