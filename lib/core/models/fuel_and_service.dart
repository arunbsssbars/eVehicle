class FuelEntry {
  final String id;
  final String vehicleId;
  final DateTime date;
  final String fuelStation;
  final String fuelType;
  final double quantityLiters;
  final double ratePerLiter;
  final double totalAmount;
  final double odometerKm;
  final String? receiptNumber;
  final String? remarks;

  const FuelEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.fuelStation,
    required this.fuelType,
    required this.quantityLiters,
    required this.ratePerLiter,
    required this.totalAmount,
    required this.odometerKm,
    this.receiptNumber,
    this.remarks,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicle_id': vehicleId,
        'date': date.toIso8601String(),
        'fuel_station': fuelStation,
        'fuel_type': fuelType,
        'quantity_liters': quantityLiters,
        'rate_per_liter': ratePerLiter,
        'total_amount': totalAmount,
        'odometer_km': odometerKm,
        'receipt_number': receiptNumber,
        'remarks': remarks,
      };

  factory FuelEntry.fromJson(Map<String, dynamic> json) => FuelEntry(
        id: json['id'] as String,
        vehicleId: json['vehicle_id'] as String,
        date: DateTime.parse(json['date'] as String),
        fuelStation: json['fuel_station'] as String,
        fuelType: json['fuel_type'] as String? ?? 'Diesel',
        quantityLiters: (json['quantity_liters'] as num).toDouble(),
        ratePerLiter: (json['rate_per_liter'] as num).toDouble(),
        totalAmount: (json['total_amount'] as num).toDouble(),
        odometerKm: (json['odometer_km'] as num).toDouble(),
        receiptNumber: json['receipt_number'] as String?,
        remarks: json['remarks'] as String?,
      );
}

class MaintenanceRecord {
  final String id;
  final String vehicleId;
  final DateTime serviceDate;
  final double odometerKm;
  final String serviceType; // Scheduled Service, Tyre Replacement, Battery, Repair
  final String workPerformed;
  final double cost;
  final String vendor;
  final double nextServiceKm;
  final DateTime nextServiceDate;
  final String? invoiceNumber;

  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.serviceDate,
    required this.odometerKm,
    required this.serviceType,
    required this.workPerformed,
    required this.cost,
    required this.vendor,
    required this.nextServiceKm,
    required this.nextServiceDate,
    this.invoiceNumber,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicle_id': vehicleId,
        'service_date': serviceDate.toIso8601String(),
        'odometer_km': odometerKm,
        'service_type': serviceType,
        'work_performed': workPerformed,
        'cost': cost,
        'vendor': vendor,
        'next_service_km': nextServiceKm,
        'next_service_date': nextServiceDate.toIso8601String(),
        'invoice_number': invoiceNumber,
      };

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) =>
      MaintenanceRecord(
        id: json['id'] as String,
        vehicleId: json['vehicle_id'] as String,
        serviceDate: DateTime.parse(json['service_date'] as String),
        odometerKm: (json['odometer_km'] as num).toDouble(),
        serviceType: json['service_type'] as String,
        workPerformed: json['work_performed'] as String,
        cost: (json['cost'] as num).toDouble(),
        vendor: json['vendor'] as String,
        nextServiceKm: (json['next_service_km'] as num).toDouble(),
        nextServiceDate: DateTime.parse(json['next_service_date'] as String),
        invoiceNumber: json['invoice_number'] as String?,
      );
}
