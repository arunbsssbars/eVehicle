/// Type of daily vehicle inspection
enum DvirType {
  preTrip('Pre-Trip Inspection'),
  postTrip('Post-Trip Inspection');

  final String label;
  const DvirType(this.label);
}

/// Severity level of an identified defect
enum DefectSeverity {
  minor('Minor (Monitor)', 0xFFF59E0B),
  major('Major (Schedule Repair)', 0xFFEA580C),
  critical('Critical (Ground Vehicle)', 0xFFDC2626);

  final String label;
  final int colorValue;
  const DefectSeverity(this.label, this.colorValue);
}

/// Individual item defect recorded during inspection
class DvirDefect {
  final String component;
  final DefectSeverity severity;
  final String description;
  final String? photoUri;

  const DvirDefect({
    required this.component,
    required this.severity,
    required this.description,
    this.photoUri,
  });

  Map<String, dynamic> toJson() => {
        'component': component,
        'severity': severity.name,
        'description': description,
        'photo_uri': photoUri,
      };

  factory DvirDefect.fromJson(Map<String, dynamic> json) => DvirDefect(
        component: json['component'] as String,
        severity: DefectSeverity.values.firstWhere(
          (s) => s.name == json['severity'],
          orElse: () => DefectSeverity.minor,
        ),
        description: json['description'] as String,
        photoUri: json['photo_uri'] as String?,
      );
}

/// Complete Daily Vehicle Inspection Report (DVIR)
class DvirInspection {
  final String id;
  final String vehicleId;
  final String vehicleRegistration;
  final String driverId;
  final String driverName;
  final DateTime timestamp;
  final double odometer;
  final DvirType type;
  final List<DvirDefect> defects;
  final bool isSafeToOperate;
  final String? notes;

  const DvirInspection({
    required this.id,
    required this.vehicleId,
    required this.vehicleRegistration,
    required this.driverId,
    required this.driverName,
    required this.timestamp,
    required this.odometer,
    required this.type,
    this.defects = const [],
    required this.isSafeToOperate,
    this.notes,
  });

  bool get hasDefects => defects.isNotEmpty;
  bool get hasCriticalDefects =>
      defects.any((d) => d.severity == DefectSeverity.critical);

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicle_id': vehicleId,
        'vehicle_registration': vehicleRegistration,
        'driver_id': driverId,
        'driver_name': driverName,
        'timestamp': timestamp.toIso8601String(),
        'odometer': odometer,
        'type': type.name,
        'defects': defects.map((d) => d.toJson()).toList(),
        'is_safe_to_operate': isSafeToOperate,
        'notes': notes,
      };

  factory DvirInspection.fromJson(Map<String, dynamic> json) => DvirInspection(
        id: json['id'] as String,
        vehicleId: json['vehicle_id'] as String,
        vehicleRegistration: json['vehicle_registration'] as String,
        driverId: json['driver_id'] as String,
        driverName: json['driver_name'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        odometer: (json['odometer'] as num).toDouble(),
        type: DvirType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => DvirType.preTrip,
        ),
        defects: (json['defects'] as List<dynamic>?)
                ?.map((e) => DvirDefect.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        isSafeToOperate: json['is_safe_to_operate'] as bool? ?? true,
        notes: json['notes'] as String?,
      );
}
