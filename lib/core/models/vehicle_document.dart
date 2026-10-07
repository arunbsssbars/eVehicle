/// Type of statutory or compliance document for a vehicle
enum DocumentType {
  rc('Registration Certificate (RC)', 0xFF004AC6),
  insurance('Insurance Policy', 0xFF16A34A),
  puc('PUC Certificate', 0xFF0284C7),
  fitness('Fitness Certificate', 0xFFEA580C),
  tax('Road Tax Receipt', 0xFF7C3AED),
  permit('Commercial Permit', 0xFF0D9488),
  other('Other Document', 0xFF64748B);

  final String label;
  final int colorValue;
  const DocumentType(this.label, this.colorValue);

  // Backward compatibility aliases
  static DocumentType get registrationCertificate => rc;
  static DocumentType get insurancePolicy => insurance;
  static DocumentType get pollutionCertificate => puc;
  static DocumentType get fitnessCertificate => fitness;
  static DocumentType get roadTaxReceipt => tax;
  static DocumentType get commercialPermit => permit;
}

/// Backward compatibility typedef
typedef VehicleDocumentType = DocumentType;

/// Verification lifecycle state of a statutory document
enum DocumentVerificationStatus {
  verified('Verified', 0xFF16A34A),
  pending('Pending Verification', 0xFFEA580C),
  expired('Expired', 0xFFDC2626),
  rejected('Rejected', 0xFF64748B);

  final String label;
  final int colorValue;
  const DocumentVerificationStatus(this.label, this.colorValue);
}

/// Statutory document entity stored in the offline vault
class VehicleDocument {
  final String id;
  final String vehicleId;
  final DocumentType type;
  final String documentNumber;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String? fileUri;
  final String sha256Checksum;
  final DocumentVerificationStatus status;
  final bool isVerified;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? notes;

  VehicleDocument({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.documentNumber,
    DateTime? issueDate,
    DateTime? issuedDate,
    required this.expiryDate,
    this.fileUri,
    this.sha256Checksum = '',
    this.status = DocumentVerificationStatus.verified,
    this.isVerified = true,
    this.verifiedBy,
    this.verifiedAt,
    this.notes,
  }) : issueDate = issueDate ?? issuedDate ?? DateTime.now();

  DateTime get issuedDate => issueDate;

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  int get daysUntilExpiry {
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }

  int get daysRemaining => daysUntilExpiry;

  bool get isExpiringSoon => !isExpired && daysUntilExpiry <= 30;

  String get expiryStatusLabel {
    if (isExpired) return 'Expired (${(-daysUntilExpiry)} days ago)';
    if (daysUntilExpiry <= 7) return 'Expires in $daysUntilExpiry day(s)';
    if (daysUntilExpiry <= 30) return 'Expires in $daysUntilExpiry days';
    return 'Valid ($daysUntilExpiry days remaining)';
  }

  int get urgencyColorValue {
    if (isExpired) return 0xFFDC2626; // Red
    if (daysUntilExpiry <= 14) return 0xFFEA580C; // Orange
    if (daysUntilExpiry <= 30) return 0xFFF59E0B; // Yellow
    return 0xFF16A34A; // Green
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicle_id': vehicleId,
        'type': type.name,
        'document_number': documentNumber,
        'issue_date': issueDate.toIso8601String(),
        'expiry_date': expiryDate.toIso8601String(),
        'file_uri': fileUri,
        'sha256_checksum': sha256Checksum,
        'status': status.name,
        'verified_by': verifiedBy,
        'verified_at': verifiedAt?.toIso8601String(),
        'notes': notes,
      };

  factory VehicleDocument.fromJson(Map<String, dynamic> json) => VehicleDocument(
        id: json['id'] as String,
        vehicleId: json['vehicle_id'] as String,
        type: DocumentType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => DocumentType.rc,
        ),
        documentNumber: json['document_number'] as String,
        issueDate: DateTime.parse((json['issue_date'] ?? json['issued_date']) as String),
        expiryDate: DateTime.parse(json['expiry_date'] as String),
        fileUri: json['file_uri'] as String?,
        sha256Checksum: json['sha256_checksum'] as String? ?? '',
        status: DocumentVerificationStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => DocumentVerificationStatus.verified,
        ),
        verifiedBy: json['verified_by'] as String?,
        verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at'] as String) : null,
        notes: json['notes'] as String?,
      );
}
