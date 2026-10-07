import 'user.dart';

enum MembershipRequestStatus {
  pending('PENDING', 'Pending Approval', 0xFFEA580C),
  approved('APPROVED', 'Approved', 0xFF16A34A),
  rejected('REJECTED', 'Rejected', 0xFFDC2626);

  final String code;
  final String label;
  final int colorValue;
  const MembershipRequestStatus(this.code, this.label, this.colorValue);

  static MembershipRequestStatus fromCode(String? code) {
    return MembershipRequestStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => MembershipRequestStatus.pending,
    );
  }
}

class MembershipRequest {
  final String id;
  final String organizationId;
  final String organizationName;
  final String organizationCode;
  final String userId;
  final String userName;
  final String userEmail;
  final String userMobile;
  final UserRole requestedRole;
  final MembershipRequestStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewRemarks;

  const MembershipRequest({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.organizationCode,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userMobile,
    this.requestedRole = UserRole.driver,
    this.status = MembershipRequestStatus.pending,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewRemarks,
  });

  bool get isPending => status == MembershipRequestStatus.pending;
  bool get isApproved => status == MembershipRequestStatus.approved;
  bool get isRejected => status == MembershipRequestStatus.rejected;

  MembershipRequest copyWith({
    String? id,
    String? organizationId,
    String? organizationName,
    String? organizationCode,
    String? userId,
    String? userName,
    String? userEmail,
    String? userMobile,
    UserRole? requestedRole,
    MembershipRequestStatus? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewRemarks,
  }) {
    return MembershipRequest(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      organizationCode: organizationCode ?? this.organizationCode,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userMobile: userMobile ?? this.userMobile,
      requestedRole: requestedRole ?? this.requestedRole,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewRemarks: reviewRemarks ?? this.reviewRemarks,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'organization_id': organizationId,
        'organization_name': organizationName,
        'organization_code': organizationCode,
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'user_mobile': userMobile,
        'requested_role': requestedRole.code,
        'status': status.code,
        'created_at': createdAt.toIso8601String(),
        'reviewed_at': reviewedAt?.toIso8601String(),
        'reviewed_by': reviewedBy,
        'review_remarks': reviewRemarks,
      };

  factory MembershipRequest.fromJson(Map<String, dynamic> json) =>
      MembershipRequest(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        organizationName: json['organization_name'] as String? ?? 'Organization',
        organizationCode: json['organization_code'] as String? ?? '',
        userId: json['user_id'] as String,
        userName: json['user_name'] as String? ?? 'Driver',
        userEmail: json['user_email'] as String? ?? '',
        userMobile: json['user_mobile'] as String? ?? '',
        requestedRole: UserRole.fromCode(json['requested_role'] as String?),
        status: MembershipRequestStatus.fromCode(json['status'] as String?),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        reviewedAt: json['reviewed_at'] != null
            ? DateTime.tryParse(json['reviewed_at'] as String)
            : null,
        reviewedBy: json['reviewed_by'] as String?,
        reviewRemarks: json['review_remarks'] as String?,
      );
}
