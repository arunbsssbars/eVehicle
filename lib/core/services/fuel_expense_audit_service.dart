/// Record representing a logged fuel refill and receipt details
class FuelExpenseRecord {
  final String id;
  final String vehicleId;
  final String vehicleRegistration;
  final DateTime timestamp;
  final double odometerAtRefuel;
  final double fuelVolumeLiters;
  final double totalCost;
  final String fuelType;
  final String? receiptNumber;
  final double tankCapacityLiters;
  final bool isFlagged;
  final String? flagReason;

  const FuelExpenseRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleRegistration,
    required this.timestamp,
    required this.odometerAtRefuel,
    required this.fuelVolumeLiters,
    required this.totalCost,
    required this.fuelType,
    this.receiptNumber,
    this.tankCapacityLiters = 55.0,
    this.isFlagged = false,
    this.flagReason,
  });

  double get unitPricePerLiter =>
      fuelVolumeLiters > 0 ? (totalCost / fuelVolumeLiters) : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicle_id': vehicleId,
        'vehicle_registration': vehicleRegistration,
        'timestamp': timestamp.toIso8601String(),
        'odometer_at_refuel': odometerAtRefuel,
        'fuel_volume_liters': fuelVolumeLiters,
        'total_cost': totalCost,
        'fuel_type': fuelType,
        'receipt_number': receiptNumber,
        'tank_capacity_liters': tankCapacityLiters,
        'is_flagged': isFlagged,
        'flag_reason': flagReason,
      };

  factory FuelExpenseRecord.fromJson(Map<String, dynamic> json) =>
      FuelExpenseRecord(
        id: json['id'] as String,
        vehicleId: json['vehicle_id'] as String,
        vehicleRegistration: json['vehicle_registration'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        odometerAtRefuel: (json['odometer_at_refuel'] as num).toDouble(),
        fuelVolumeLiters: (json['fuel_volume_liters'] as num).toDouble(),
        totalCost: (json['total_cost'] as num).toDouble(),
        fuelType: json['fuel_type'] as String,
        receiptNumber: json['receipt_number'] as String?,
        tankCapacityLiters:
            (json['tank_capacity_liters'] as num?)?.toDouble() ?? 55.0,
        isFlagged: json['is_flagged'] as bool? ?? false,
        flagReason: json['flag_reason'] as String?,
      );
}

/// Fuel efficiency and cost-per-kilometer analytics summary
class FuelAnalyticsSummary {
  final double totalSpend;
  final double totalFuelLiters;
  final double averageUnitPrice;
  final double? costPerKm;
  final double? avgKmPerLiter;
  final int totalRefuels;
  final int flaggedAnomaliesCount;

  const FuelAnalyticsSummary({
    required this.totalSpend,
    required this.totalFuelLiters,
    required this.averageUnitPrice,
    this.costPerKm,
    this.avgKmPerLiter,
    required this.totalRefuels,
    required this.flaggedAnomaliesCount,
  });
}

/// Service providing automated fuel receipt auditing, Cost-Per-Kilometer (CPK) calculation, and fraud detection.
class FuelExpenseAuditService {
  /// Benchmark fuel prices per liter in INR (or standard currency)
  static const Map<String, double> standardMarketPriceBenchmark = {
    'diesel': 90.0,
    'petrol': 98.0,
    'cng': 75.0,
  };

  /// Audits a fuel refill record against physical vehicle capacity and market prices
  static FuelExpenseRecord auditRecord(
    FuelExpenseRecord record, {
    double priceDeviationThreshold = 0.30,
  }) {
    final reasons = <String>[];

    // 1. Tank Capacity Overflow Check
    if (record.tankCapacityLiters > 0 &&
        record.fuelVolumeLiters > record.tankCapacityLiters * 1.05) {
      reasons.add(
        'Refill volume (${record.fuelVolumeLiters}L) exceeds vehicle physical tank capacity (${record.tankCapacityLiters}L)',
      );
    }

    // 2. Unit Price Deviation Check
    final normFuel = record.fuelType.toLowerCase();
    final benchmark = standardMarketPriceBenchmark[normFuel];
    if (benchmark != null && record.fuelVolumeLiters > 0) {
      final unitPrice = record.unitPricePerLiter;
      final diffPercent = (unitPrice - benchmark).abs() / benchmark;
      if (diffPercent > priceDeviationThreshold) {
        reasons.add(
          'Unit fuel price (${unitPrice.toStringAsFixed(1)}) deviates ${(diffPercent * 100).toStringAsFixed(0)}% from market benchmark ($benchmark)',
        );
      }
    }

    // 3. Zero or negative cost/volume check
    if (record.fuelVolumeLiters <= 0 || record.totalCost <= 0) {
      reasons.add('Invalid non-positive fuel volume or cost logged');
    }

    if (reasons.isNotEmpty) {
      return FuelExpenseRecord(
        id: record.id,
        vehicleId: record.vehicleId,
        vehicleRegistration: record.vehicleRegistration,
        timestamp: record.timestamp,
        odometerAtRefuel: record.odometerAtRefuel,
        fuelVolumeLiters: record.fuelVolumeLiters,
        totalCost: record.totalCost,
        fuelType: record.fuelType,
        receiptNumber: record.receiptNumber,
        tankCapacityLiters: record.tankCapacityLiters,
        isFlagged: true,
        flagReason: reasons.join('; '),
      );
    }

    return record;
  }

  /// Calculates Cost-Per-Kilometer (CPK) and fuel economy between sequential fuel logs
  static FuelAnalyticsSummary calculateFleetSummary(
    List<FuelExpenseRecord> records,
  ) {
    if (records.isEmpty) {
      return const FuelAnalyticsSummary(
        totalSpend: 0.0,
        totalFuelLiters: 0.0,
        averageUnitPrice: 0.0,
        costPerKm: null,
        avgKmPerLiter: null,
        totalRefuels: 0,
        flaggedAnomaliesCount: 0,
      );
    }

    final sorted = List<FuelExpenseRecord>.from(records)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double totalSpend = 0.0;
    double totalLiters = 0.0;
    int flagged = 0;

    for (final r in sorted) {
      totalSpend += r.totalCost;
      totalLiters += r.fuelVolumeLiters;
      if (r.isFlagged) flagged++;
    }

    final avgUnitPrice = totalLiters > 0 ? (totalSpend / totalLiters) : 0.0;

    // Calculate CPK if we have at least 2 refills with odometer delta
    double? costPerKm;
    double? kmPerLiter;

    if (sorted.length >= 2) {
      final startOdometer = sorted.first.odometerAtRefuel;
      final endOdometer = sorted.last.odometerAtRefuel;
      final distanceTraveled = endOdometer - startOdometer;

      if (distanceTraveled > 0) {
        // Exclude first refill volume since it filled the starting state
        final subsequentLiters =
            sorted.skip(1).fold(0.0, (sum, r) => sum + r.fuelVolumeLiters);
        final subsequentSpend =
            sorted.skip(1).fold(0.0, (sum, r) => sum + r.totalCost);

        if (subsequentLiters > 0) {
          costPerKm = subsequentSpend / distanceTraveled;
          kmPerLiter = distanceTraveled / subsequentLiters;
        }
      }
    }

    return FuelAnalyticsSummary(
      totalSpend: totalSpend,
      totalFuelLiters: totalLiters,
      averageUnitPrice: avgUnitPrice,
      costPerKm: costPerKm,
      avgKmPerLiter: kmPerLiter,
      totalRefuels: sorted.length,
      flaggedAnomaliesCount: flagged,
    );
  }
}
