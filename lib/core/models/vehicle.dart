import 'vehicle_document.dart';

enum VehicleStatus {
  active('ACTIVE', 'Active', 0xFF16A34A),
  inactive('INACTIVE', 'Inactive', 0xFF64748B),
  underRepair('UNDER_REPAIR', 'Under Repair', 0xFFEA580C),
  sold('SOLD', 'Sold', 0xFF94A3B8),
  retired('RETIRED', 'Retired', 0xFFDC2626);

  final String code;
  final String label;
  final int colorValue;
  const VehicleStatus(this.code, this.label, this.colorValue);

  static VehicleStatus fromCode(String? code) {
    return VehicleStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => VehicleStatus.active,
    );
  }
}

class Vehicle {
  final String id;
  final String registrationNumber;
  final String make;
  final String model;
  final String vehicleType; // SUV, Sedan, EV, Truck, Jeep
  final String fuelType; // Electric, Diesel, Petrol, CNG
  final int manufacturingYear;
  final double currentOdometer;
  final String assignedOffice;
  final String assignedDriverId;
  final String assignedDriverName;
  final VehicleStatus status;
  final List<VehicleDocument> documents;
  final double monthlyTargetKm;
  final double nextServiceKm;
  final DateTime nextServiceDate;
  final double fuelEfficiencyAvg; // KM/L or KM/kWh

  const Vehicle({
    required this.id,
    required this.registrationNumber,
    required this.make,
    required this.model,
    required this.vehicleType,
    required this.fuelType,
    required this.manufacturingYear,
    required this.currentOdometer,
    required this.assignedOffice,
    required this.assignedDriverId,
    required this.assignedDriverName,
    this.status = VehicleStatus.active,
    this.documents = const [],
    this.monthlyTargetKm = 2500.0,
    this.nextServiceKm = 55000.0,
    required this.nextServiceDate,
    this.fuelEfficiencyAvg = 14.8,
  });

  String get displayName => '$make $model ($registrationNumber)';

  bool get isElectric =>
      fuelType.toLowerCase().contains('electric') ||
      fuelType.toLowerCase().contains('ev') ||
      vehicleType.toLowerCase().contains('ev');

  bool get isServiceDue =>
      currentOdometer >= nextServiceKm ||
      DateTime.now().isAfter(nextServiceDate);

  double get remainingKmToService => nextServiceKm - currentOdometer;

  int get remainingDaysToService => nextServiceDate.difference(DateTime.now()).inDays;

  bool get isServiceDueSoon =>
      !isServiceDue && (remainingKmToService <= 500 || remainingDaysToService <= 14);

  String get serviceUrgencyLabel {
    if (isServiceDue) return 'OVERDUE';
    if (isServiceDueSoon) return 'DUE SOON';
    return 'HEALTHY';
  }

  int get serviceUrgencyColorValue {
    if (isServiceDue) return 0xFFDC2626;
    if (isServiceDueSoon) return 0xFFEA580C;
    return 0xFF16A34A;
  }

  int get expiredDocumentsCount =>
      documents.where((d) => d.isExpired).length;

  int get expiringSoonDocumentsCount =>
      documents.where((d) => d.isExpiringSoon).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'registration_number': registrationNumber,
        'make': make,
        'model': model,
        'vehicle_type': vehicleType,
        'fuel_type': fuelType,
        'manufacturing_year': manufacturingYear,
        'current_odometer': currentOdometer,
        'assigned_office': assignedOffice,
        'assigned_driver_id': assignedDriverId,
        'assigned_driver_name': assignedDriverName,
        'status': status.code,
        'documents': documents.map((d) => d.toJson()).toList(),
        'monthly_target_km': monthlyTargetKm,
        'next_service_km': nextServiceKm,
        'next_service_date': nextServiceDate.toIso8601String(),
        'fuel_efficiency_avg': fuelEfficiencyAvg,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        registrationNumber: json['registration_number'] as String,
        make: json['make'] as String,
        model: json['model'] as String,
        vehicleType: json['vehicle_type'] as String? ?? 'SUV',
        fuelType: json['fuel_type'] as String? ?? 'Diesel',
        manufacturingYear: json['manufacturing_year'] as int? ?? 2023,
        currentOdometer: (json['current_odometer'] as num).toDouble(),
        assignedOffice: json['assigned_office'] as String? ?? 'Headquarters',
        assignedDriverId: json['assigned_driver_id'] as String? ?? 'DRV-001',
        assignedDriverName: json['assigned_driver_name'] as String? ?? 'Rajesh Kumar',
        status: VehicleStatus.fromCode(json['status'] as String?),
        documents: (json['documents'] as List<dynamic>?)
                ?.map((d) => VehicleDocument.fromJson(d as Map<String, dynamic>))
                .toList() ??
            const [],
        monthlyTargetKm: (json['monthly_target_km'] as num?)?.toDouble() ?? 2500.0,
        nextServiceKm: (json['next_service_km'] as num?)?.toDouble() ?? 55000.0,
        nextServiceDate: json['next_service_date'] != null
            ? DateTime.parse(json['next_service_date'] as String)
            : DateTime.now().add(const Duration(days: 45)),
        fuelEfficiencyAvg: (json['fuel_efficiency_avg'] as num?)?.toDouble() ?? 14.8,
      );

  Vehicle copyWith({
    String? registrationNumber,
    String? make,
    String? model,
    String? vehicleType,
    String? fuelType,
    int? manufacturingYear,
    String? assignedOffice,
    double? currentOdometer,
    VehicleStatus? status,
    String? assignedDriverId,
    String? assignedDriverName,
    List<VehicleDocument>? documents,
    double? monthlyTargetKm,
    double? nextServiceKm,
    DateTime? nextServiceDate,
    double? fuelEfficiencyAvg,
    bool clearAssignedDriver = false,
  }) {
    return Vehicle(
      id: id,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      make: make ?? this.make,
      model: model ?? this.model,
      vehicleType: vehicleType ?? this.vehicleType,
      fuelType: fuelType ?? this.fuelType,
      manufacturingYear: manufacturingYear ?? this.manufacturingYear,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      assignedOffice: assignedOffice ?? this.assignedOffice,
      assignedDriverId: clearAssignedDriver ? '' : (assignedDriverId ?? this.assignedDriverId),
      assignedDriverName: clearAssignedDriver ? 'Unassigned' : (assignedDriverName ?? this.assignedDriverName),
      status: status ?? this.status,
      documents: documents ?? this.documents,
      monthlyTargetKm: monthlyTargetKm ?? this.monthlyTargetKm,
      nextServiceKm: nextServiceKm ?? this.nextServiceKm,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      fuelEfficiencyAvg: fuelEfficiencyAvg ?? this.fuelEfficiencyAvg,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehicle && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
