enum JourneyStatus {
  draft('DRAFT', 'Draft', 0xFF64748B),
  active('ACTIVE', 'Active', 0xFF004AC6),
  completed('COMPLETED', 'Completed', 0xFF2563EB),
  submitted('SUBMITTED', 'Submitted', 0xFF0284C7),
  pendingApproval('PENDING_APPROVAL', 'Pending Approval', 0xFFEA580C),
  approved('APPROVED', 'Approved', 0xFF16A34A),
  rejected('REJECTED', 'Rejected', 0xFFDC2626),
  cancelled('CANCELLED', 'Cancelled', 0xFF94A3B8),
  pendingDeletion('PENDING_DELETION', 'Pending Deletion', 0xFFE11D48),
  locked('LOCKED', 'Locked', 0xFF475569);

  final String code;
  final String label;
  final int colorValue;
  const JourneyStatus(this.code, this.label, this.colorValue);

  static JourneyStatus fromCode(String? code) {
    return JourneyStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => JourneyStatus.pendingApproval,
    );
  }
}

enum SyncStatus {
  synced('SYNCED', 'Synced'),
  pending('PENDING', 'Sync Pending'),
  syncing('SYNCING', 'Syncing'),
  conflict('CONFLICT', 'Conflict'),
  failed('FAILED', 'Sync Failed');

  final String code;
  final String label;
  const SyncStatus(this.code, this.label);

  static SyncStatus fromCode(String? code) {
    return SyncStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => SyncStatus.synced,
    );
  }
}

enum TripCategory {
  business('BUSINESS', 'Business / Duty', 0xFF0052CC),
  personal('PERSONAL', 'Personal', 0xFF16A34A),
  commute('COMMUTE', 'Commute', 0xFF64748B);

  final String code;
  final String label;
  final int colorValue;
  const TripCategory(this.code, this.label, this.colorValue);

  static TripCategory fromCode(String? code) {
    return TripCategory.values.firstWhere(
      (c) => c.code == code,
      orElse: () => TripCategory.business,
    );
  }
}

class JourneyLocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed;
  final double? accuracy;

  const JourneyLocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.accuracy,
  });

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
        't': timestamp.toIso8601String(),
        's': speed,
        'a': accuracy,
      };

  factory JourneyLocationPoint.fromJson(Map<String, dynamic> json) =>
      JourneyLocationPoint(
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lng'] as num).toDouble(),
        timestamp: DateTime.parse(json['t'] as String),
        speed: (json['s'] as num?)?.toDouble(),
        accuracy: (json['a'] as num?)?.toDouble(),
      );
}

class Journey {
  final String id;
  final String localId;
  final String clientOperationId;
  final String vehicleId;
  final String vehicleRegistration;
  final String vehicleModel;
  final String driverId;
  final String driverName;
  final String officerId;
  final String officerName;
  final String userOfficerName;
  final String userOfficerDesignation;
  final bool isSubordinateJourney;
  final String? officerSignatureText;
  final bool requiresApproval;
  final String department;
  final String office;
  final DateTime journeyDate;
  final DateTime startTime;
  final DateTime? endTime;
  final String startLocation;
  final String destination;
  final String purpose;
  final double openingOdometer;
  final double? closingOdometer;
  final double? officialDistance;
  final double? gpsDistance;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final List<JourneyLocationPoint> routePoints;
  final String? accompanyingOfficers;
  final String? remarks;
  final TripCategory category;
  final double? expenseAmount;
  final String? expenseReceiptUrl;
  final JourneyStatus status;
  final SyncStatus syncStatus;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedBy;
  final String? rejectionReason;
  final DateTime? rejectedAt;
  final String? lockedBy;
  final DateTime? lockedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Journey({
    required this.id,
    required this.localId,
    required this.clientOperationId,
    required this.vehicleId,
    required this.vehicleRegistration,
    required this.vehicleModel,
    required this.driverId,
    required this.driverName,
    required this.officerId,
    required this.officerName,
    String? userOfficerName,
    String? userOfficerDesignation,
    this.isSubordinateJourney = false,
    this.officerSignatureText,
    this.requiresApproval = true,
    required this.department,
    required this.office,
    required this.journeyDate,
    required this.startTime,
    this.endTime,
    required this.startLocation,
    this.destination = '',
    required this.purpose,
    required this.openingOdometer,
    this.closingOdometer,
    this.officialDistance,
    this.gpsDistance,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.routePoints = const [],
    this.accompanyingOfficers,
    this.remarks,
    TripCategory? category,
    TripCategory? tripCategory,
    this.expenseAmount,
    this.expenseReceiptUrl,
    this.status = JourneyStatus.active,
    this.syncStatus = SyncStatus.synced,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectionReason,
    this.rejectedAt,
    this.lockedBy,
    this.lockedAt,
    required this.createdAt,
    required this.updatedAt,
  })  : category = tripCategory ?? category ?? TripCategory.business,
        userOfficerName = userOfficerName ?? officerName,
        userOfficerDesignation = userOfficerDesignation ?? 'Officer / User';

  TripCategory get tripCategory => category;

  bool get isBusiness => category == TripCategory.business;
  bool get isPersonal => category == TripCategory.personal;
  bool get isCommute => category == TripCategory.commute;

  /// Official Distance calculation: Closing KM - Opening KM
  double get calculatedDistance {
    if (closingOdometer != null && closingOdometer! >= openingOdometer) {
      return closingOdometer! - openingOdometer;
    }
    return officialDistance ?? 0.0;
  }

  /// Check whether GPS distance differs significantly from Odometer distance
  bool get hasDistanceDiscrepancy {
    if (gpsDistance == null || calculatedDistance <= 0) return false;
    final diff = (calculatedDistance - gpsDistance!).abs();
    return diff > 15.0 && (diff / calculatedDistance) > 0.20;
  }

  /// Duration of the journey
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  String get formattedDuration {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'local_id': localId,
        'client_operation_id': clientOperationId,
        'vehicle_id': vehicleId,
        'vehicle_registration': vehicleRegistration,
        'vehicle_model': vehicleModel,
        'driver_id': driverId,
        'driver_name': driverName,
        'officer_id': officerId,
        'officer_name': officerName,
        'user_officer_name': userOfficerName,
        'user_officer_designation': userOfficerDesignation,
        'is_subordinate_journey': isSubordinateJourney,
        'officer_signature_text': officerSignatureText,
        'requires_approval': requiresApproval,
        'department': department,
        'office': office,
        'journey_date': journeyDate.toIso8601String(),
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'start_location': startLocation,
        'destination': destination,
        'purpose': purpose,
        'opening_odometer': openingOdometer,
        'closing_odometer': closingOdometer,
        'official_distance': officialDistance ?? calculatedDistance,
        'gps_distance': gpsDistance,
        'start_latitude': startLatitude,
        'start_longitude': startLongitude,
        'end_latitude': endLatitude,
        'end_longitude': endLongitude,
        'route_points': routePoints.map((p) => p.toJson()).toList(),
        'accompanying_officers': accompanyingOfficers,
        'remarks': remarks,
        'category': category.code,
        'expense_amount': expenseAmount,
        'expense_receipt_url': expenseReceiptUrl,
        'status': status.code,
        'sync_status': syncStatus.code,
        'approved_by': approvedBy,
        'approved_at': approvedAt?.toIso8601String(),
        'rejected_by': rejectedBy,
        'rejection_reason': rejectionReason,
        'rejected_at': rejectedAt?.toIso8601String(),
        'locked_by': lockedBy,
        'locked_at': lockedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Journey.fromJson(Map<String, dynamic> json) => Journey(
        id: json['id'] as String,
        localId: json['local_id'] as String? ?? json['id'] as String,
        clientOperationId: json['client_operation_id'] as String? ?? '',
        vehicleId: json['vehicle_id'] as String,
        vehicleRegistration: json['vehicle_registration'] as String? ?? 'UP16 AB 1234',
        vehicleModel: json['vehicle_model'] as String? ?? 'Innova Crysta',
        driverId: json['driver_id'] as String,
        driverName: json['driver_name'] as String? ?? 'Rajesh Kumar',
        officerId: json['officer_id'] as String? ?? 'EMP-001',
        officerName: json['officer_name'] as String? ?? 'Dr. S. K. Verma',
        userOfficerName: json['user_officer_name'] as String?,
        userOfficerDesignation: json['user_officer_designation'] as String?,
        isSubordinateJourney: json['is_subordinate_journey'] as bool? ?? false,
        officerSignatureText: json['officer_signature_text'] as String?,
        requiresApproval: json['requires_approval'] as bool? ?? true,
        department: json['department'] as String? ?? 'Public Works Department',
        office: json['office'] as String? ?? 'District Division',
        journeyDate: DateTime.parse(json['journey_date'] as String),
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: json['end_time'] != null
            ? DateTime.parse(json['end_time'] as String)
            : null,
        startLocation: json['start_location'] as String,
        destination: json['destination'] as String? ?? '',
        purpose: json['purpose'] as String,
        openingOdometer: (json['opening_odometer'] as num).toDouble(),
        closingOdometer: (json['closing_odometer'] as num?)?.toDouble(),
        officialDistance: (json['official_distance'] as num?)?.toDouble(),
        gpsDistance: (json['gps_distance'] as num?)?.toDouble(),
        startLatitude: (json['start_latitude'] as num?)?.toDouble(),
        startLongitude: (json['start_longitude'] as num?)?.toDouble(),
        endLatitude: (json['end_latitude'] as num?)?.toDouble(),
        endLongitude: (json['end_longitude'] as num?)?.toDouble(),
        routePoints: (json['route_points'] as List<dynamic>?)
                ?.map((p) => JourneyLocationPoint.fromJson(p as Map<String, dynamic>))
                .toList() ??
            const [],
        accompanyingOfficers: json['accompanying_officers'] as String?,
        remarks: json['remarks'] as String?,
        category: TripCategory.fromCode(json['category'] as String?),
        expenseAmount: (json['expense_amount'] as num?)?.toDouble(),
        expenseReceiptUrl: json['expense_receipt_url'] as String?,
        status: JourneyStatus.fromCode(json['status'] as String?),
        syncStatus: SyncStatus.fromCode(json['sync_status'] as String?),
        approvedBy: json['approved_by'] as String?,
        approvedAt: json['approved_at'] != null
            ? DateTime.parse(json['approved_at'] as String)
            : null,
        rejectedBy: json['rejected_by'] as String?,
        rejectionReason: json['rejection_reason'] as String?,
        rejectedAt: json['rejected_at'] != null
            ? DateTime.parse(json['rejected_at'] as String)
            : null,
        lockedBy: json['locked_by'] as String?,
        lockedAt: json['locked_at'] != null
            ? DateTime.parse(json['locked_at'] as String)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
      );

  Journey copyWith({
    String? id,
    String? localId,
    String? clientOperationId,
    String? vehicleId,
    String? vehicleRegistration,
    String? vehicleModel,
    String? driverId,
    String? officerId,
    String? driverName,
    String? officerName,
    String? startLocation,
    String? destination,
    String? purpose,
    double? openingOdometer,
    DateTime? startTime,
    DateTime? endTime,
    double? closingOdometer,
    double? officialDistance,
    double? gpsDistance,
    double? endLatitude,
    double? endLongitude,
    List<JourneyLocationPoint>? routePoints,
    String? accompanyingOfficers,
    String? remarks,
    JourneyStatus? status,
    SyncStatus? syncStatus,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectedBy,
    String? rejectionReason,
    DateTime? rejectedAt,
    String? lockedBy,
    DateTime? lockedAt,
    DateTime? updatedAt,
    String? userOfficerName,
    String? userOfficerDesignation,
    bool? isSubordinateJourney,
    String? officerSignatureText,
    bool? requiresApproval,
    String? department,
    String? office,
    DateTime? journeyDate,
    TripCategory? category,
    TripCategory? tripCategory,
    double? expenseAmount,
    String? expenseReceiptUrl,
    bool clearAccompanyingOfficers = false,
    bool clearRemarks = false,
  }) {
    return Journey(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      clientOperationId: clientOperationId ?? this.clientOperationId,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleRegistration: vehicleRegistration ?? this.vehicleRegistration,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      officerId: officerId ?? this.officerId,
      officerName: officerName ?? this.officerName,
      userOfficerName: userOfficerName ?? this.userOfficerName,
      userOfficerDesignation:
          userOfficerDesignation ?? this.userOfficerDesignation,
      isSubordinateJourney: isSubordinateJourney ?? this.isSubordinateJourney,
      officerSignatureText: officerSignatureText ?? this.officerSignatureText,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      department: department ?? this.department,
      office: office ?? this.office,
      journeyDate: journeyDate ?? this.journeyDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startLocation: startLocation ?? this.startLocation,
      destination: destination ?? this.destination,
      purpose: purpose ?? this.purpose,
      openingOdometer: openingOdometer ?? this.openingOdometer,
      closingOdometer: closingOdometer ?? this.closingOdometer,
      officialDistance: officialDistance ?? this.officialDistance,
      gpsDistance: gpsDistance ?? this.gpsDistance,
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      endLatitude: endLatitude ?? this.endLatitude,
      endLongitude: endLongitude ?? this.endLongitude,
      routePoints: routePoints ?? this.routePoints,
      accompanyingOfficers: clearAccompanyingOfficers
          ? null
          : (accompanyingOfficers ?? this.accompanyingOfficers),
      remarks: clearRemarks ? null : (remarks ?? this.remarks),
      category: tripCategory ?? category ?? this.category,
      expenseAmount: expenseAmount ?? this.expenseAmount,
      expenseReceiptUrl: expenseReceiptUrl ?? this.expenseReceiptUrl,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      lockedBy: lockedBy ?? this.lockedBy,
      lockedAt: lockedAt ?? this.lockedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
