/// Status of a shift handover between drivers
enum HandoverStatus {
  pendingAcceptance('Pending Acceptance', 0xFFEA580C),
  accepted('Accepted', 0xFF16A34A),
  disputed('Disputed', 0xFFDC2626);

  final String label;
  final int colorValue;
  const HandoverStatus(this.label, this.colorValue);
}

/// Record capturing vehicle condition and odometer transfer during shift change
class ShiftHandoverRecord {
  final String id;
  final String vehicleId;
  final String vehicleRegistration;
  final String outgoingDriverId;
  final String outgoingDriverName;
  final String incomingDriverId;
  final String incomingDriverName;
  final DateTime timestamp;
  final double odometerReading;
  final int fuelLevelPercent; // 0 - 100
  final int cleanlinessRating; // 1 - 5
  final bool tirePressureChecked;
  final bool sanitizationCompleted;
  final HandoverStatus status;
  final String? handoverNotes;
  final String? disputeReason;

  const ShiftHandoverRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleRegistration,
    required this.outgoingDriverId,
    required this.outgoingDriverName,
    required this.incomingDriverId,
    required this.incomingDriverName,
    required this.timestamp,
    required this.odometerReading,
    required this.fuelLevelPercent,
    this.cleanlinessRating = 5,
    this.tirePressureChecked = true,
    this.sanitizationCompleted = true,
    this.status = HandoverStatus.pendingAcceptance,
    this.handoverNotes,
    this.disputeReason,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicle_id': vehicleId,
        'vehicle_registration': vehicleRegistration,
        'outgoing_driver_id': outgoingDriverId,
        'outgoing_driver_name': outgoingDriverName,
        'incoming_driver_id': incomingDriverId,
        'incoming_driver_name': incomingDriverName,
        'timestamp': timestamp.toIso8601String(),
        'odometer_reading': odometerReading,
        'fuel_level_percent': fuelLevelPercent,
        'cleanliness_rating': cleanlinessRating,
        'tire_pressure_checked': tirePressureChecked,
        'sanitization_completed': sanitizationCompleted,
        'status': status.name,
        'handover_notes': handoverNotes,
        'dispute_reason': disputeReason,
      };

  factory ShiftHandoverRecord.fromJson(Map<String, dynamic> json) =>
      ShiftHandoverRecord(
        id: json['id'] as String,
        vehicleId: json['vehicle_id'] as String,
        vehicleRegistration: json['vehicle_registration'] as String,
        outgoingDriverId: json['outgoing_driver_id'] as String,
        outgoingDriverName: json['outgoing_driver_name'] as String,
        incomingDriverId: json['incoming_driver_id'] as String,
        incomingDriverName: json['incoming_driver_name'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        odometerReading: (json['odometer_reading'] as num).toDouble(),
        fuelLevelPercent: (json['fuel_level_percent'] as num).toInt(),
        cleanlinessRating: (json['cleanliness_rating'] as num?)?.toInt() ?? 5,
        tirePressureChecked: json['tire_pressure_checked'] as bool? ?? true,
        sanitizationCompleted:
            json['sanitization_completed'] as bool? ?? true,
        status: HandoverStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => HandoverStatus.pendingAcceptance,
        ),
        handoverNotes: json['handover_notes'] as String?,
        disputeReason: json['dispute_reason'] as String?,
      );
}
