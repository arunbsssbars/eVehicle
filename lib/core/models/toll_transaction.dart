/// Known Toll Plaza on national highway or expressway
class TollPlaza {
  final String id;
  final String name;
  final String highwayName;
  final double latitude;
  final double longitude;
  final double standardFee;
  final double radiusMeters;

  const TollPlaza({
    required this.id,
    required this.name,
    required this.highwayName,
    required this.latitude,
    required this.longitude,
    required this.standardFee,
    this.radiusMeters = 250.0,
  });
}

/// Electronic FASTag toll deduction statement record
class FastagTransaction {
  final String id;
  final String plazaId;
  final String plazaName;
  final String vehicleRegistration;
  final double deductedAmount;
  final DateTime timestamp;
  final String bankReferenceId;
  final bool isReconciled;

  const FastagTransaction({
    required this.id,
    required this.plazaId,
    required this.plazaName,
    required this.vehicleRegistration,
    required this.deductedAmount,
    required this.timestamp,
    required this.bankReferenceId,
    this.isReconciled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plazaId': plazaId,
      'plazaName': plazaName,
      'vehicleRegistration': vehicleRegistration,
      'deductedAmount': deductedAmount,
      'timestamp': timestamp.toIso8601String(),
      'bankReferenceId': bankReferenceId,
      'isReconciled': isReconciled,
    };
  }

  factory FastagTransaction.fromJson(Map<String, dynamic> json) {
    return FastagTransaction(
      id: json['id'] as String,
      plazaId: json['plazaId'] as String,
      plazaName: json['plazaName'] as String,
      vehicleRegistration: json['vehicleRegistration'] as String,
      deductedAmount: (json['deductedAmount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      bankReferenceId: json['bankReferenceId'] as String,
      isReconciled: json['isReconciled'] as bool? ?? false,
    );
  }
}

/// Result of automated toll crossing reconciliation
class TollReconciliationResult {
  final bool isMatched;
  final double varianceAmount;
  final String? matchedPlazaName;
  final DateTime? crossingTime;
  final List<String> flaggedAnomalies;

  const TollReconciliationResult({
    required this.isMatched,
    required this.varianceAmount,
    this.matchedPlazaName,
    this.crossingTime,
    required this.flaggedAnomalies,
  });
}
