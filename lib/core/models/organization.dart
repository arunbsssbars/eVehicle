import 'tenant_settings.dart';

enum SubscriptionTier {
  free('FREE', 'Free Starter', 2, 50),
  pro('PRO', 'Pro Individual', 5, 250),
  enterprise('ENTERPRISE', 'Enterprise Fleet', 100, 10000);

  final String code;
  final String label;
  final int maxVehicles;
  final int maxMonthlyJourneys;

  const SubscriptionTier(
    this.code,
    this.label,
    this.maxVehicles,
    this.maxMonthlyJourneys,
  );

  static SubscriptionTier fromCode(String? code) {
    return SubscriptionTier.values.firstWhere(
      (t) => t.code == code,
      orElse: () => SubscriptionTier.free,
    );
  }
}

enum OrganizationStatus {
  active('ACTIVE', 'Active', 0xFF16A34A),
  pendingVerification('PENDING_VERIFICATION', 'Pending Verification', 0xFFEA580C),
  suspended('SUSPENDED', 'Suspended', 0xFFDC2626),
  archived('ARCHIVED', 'Archived', 0xFF64748B);

  final String code;
  final String label;
  final int colorValue;
  const OrganizationStatus(this.code, this.label, this.colorValue);

  static OrganizationStatus fromCode(String? code) {
    return OrganizationStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => OrganizationStatus.active,
    );
  }
}

class Organization {
  final String id;
  final String name;
  final String code; // 6-digit Join Code e.g. PWD-842 or FLEET-10
  final String adminId;
  final String adminName;
  final String contactEmail;
  final String contactMobile;
  final SubscriptionTier subscriptionTier;
  final int activeVehiclesCount;
  final int activeMembersCount;
  final DateTime createdAt;
  final bool isVerified;
  final OrganizationStatus status;
  final String? statusReason;
  final String? taxId;
  final TenantSettings settings;

  const Organization({
    required this.id,
    required this.name,
    required this.code,
    required this.adminId,
    required this.adminName,
    required this.contactEmail,
    required this.contactMobile,
    this.subscriptionTier = SubscriptionTier.free,
    this.activeVehiclesCount = 1,
    this.activeMembersCount = 1,
    required this.createdAt,
    this.isVerified = true,
    this.status = OrganizationStatus.active,
    this.statusReason,
    this.taxId,
    this.settings = const TenantSettings(),
  });

  bool get isFreeTier => subscriptionTier == SubscriptionTier.free;
  bool get isProTier => subscriptionTier == SubscriptionTier.pro;
  bool get isEnterpriseTier => subscriptionTier == SubscriptionTier.enterprise;

  bool get isActive => status == OrganizationStatus.active;
  bool get isSuspended => status == OrganizationStatus.suspended;
  bool get isPendingVerification => status == OrganizationStatus.pendingVerification;

  Organization copyWith({
    String? id,
    String? name,
    String? code,
    String? adminId,
    String? adminName,
    String? contactEmail,
    String? contactMobile,
    SubscriptionTier? subscriptionTier,
    int? activeVehiclesCount,
    int? activeMembersCount,
    DateTime? createdAt,
    bool? isVerified,
    OrganizationStatus? status,
    String? statusReason,
    String? taxId,
    TenantSettings? settings,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactMobile: contactMobile ?? this.contactMobile,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      activeVehiclesCount: activeVehiclesCount ?? this.activeVehiclesCount,
      activeMembersCount: activeMembersCount ?? this.activeMembersCount,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      statusReason: statusReason ?? this.statusReason,
      taxId: taxId ?? this.taxId,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'admin_id': adminId,
        'admin_name': adminName,
        'contact_email': contactEmail,
        'contact_mobile': contactMobile,
        'subscription_tier': subscriptionTier.code,
        'active_vehicles_count': activeVehiclesCount,
        'active_members_count': activeMembersCount,
        'created_at': createdAt.toIso8601String(),
        'is_verified': isVerified,
        'status': status.code,
        'status_reason': statusReason,
        'tax_id': taxId,
        'settings': settings.toJson(),
      };

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        adminId: json['admin_id'] as String? ?? '',
        adminName: json['admin_name'] as String? ?? '',
        contactEmail: json['contact_email'] as String? ?? '',
        contactMobile: json['contact_mobile'] as String? ?? '',
        subscriptionTier: SubscriptionTier.fromCode(json['subscription_tier'] as String?),
        activeVehiclesCount: json['active_vehicles_count'] as int? ?? 1,
        activeMembersCount: json['active_members_count'] as int? ?? 1,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        isVerified: json['is_verified'] as bool? ?? true,
        status: OrganizationStatus.fromCode(json['status'] as String?),
        statusReason: json['status_reason'] as String?,
        taxId: json['tax_id'] as String?,
        settings: TenantSettings.fromJson(json['settings'] as Map<String, dynamic>?),
      );
}
