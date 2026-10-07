import '../models/dvir_inspection.dart';

/// Service managing Daily Vehicle Inspection Reports (DVIR) and defect safety enforcement
class DvirService {
  /// Evaluates vehicle roadworthiness: if any critical defect exists, vehicle MUST be grounded
  static bool evaluateRoadworthiness(List<DvirDefect> defects) {
    if (defects.any((d) => d.severity == DefectSeverity.critical)) {
      return false; // Grounded immediately
    }
    return true;
  }

  /// Create and validate a new DVIR report
  static DvirInspection createInspection({
    required String id,
    required String vehicleId,
    required String vehicleRegistration,
    required String driverId,
    required String driverName,
    required double odometer,
    required DvirType type,
    List<DvirDefect> defects = const [],
    String? notes,
    DateTime? timestamp,
  }) {
    final isSafe = evaluateRoadworthiness(defects);

    return DvirInspection(
      id: id,
      vehicleId: vehicleId,
      vehicleRegistration: vehicleRegistration,
      driverId: driverId,
      driverName: driverName,
      timestamp: timestamp ?? DateTime.now(),
      odometer: odometer,
      type: type,
      defects: defects,
      isSafeToOperate: isSafe,
      notes: notes,
    );
  }

  /// Get list of vehicles grounded due to unrectified critical inspection defects
  static List<String> getGroundedVehicleIds(List<DvirInspection> inspections) {
    final grounded = <String>{};
    for (final insp in inspections) {
      if (!insp.isSafeToOperate) {
        grounded.add(insp.vehicleId);
      }
    }
    return grounded.toList();
  }
}
