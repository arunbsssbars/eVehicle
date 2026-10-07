import 'organization.dart';

enum UserRole {
  superAdmin('SUPER_ADMIN', 'Super Administrator'),
  companyAdmin('COMPANY_ADMIN', 'Company / Fleet Admin'),
  departmentAdmin('DEPARTMENT_ADMIN', 'Department Administrator'),
  approvingOfficer('APPROVING_OFFICER', 'Approving Officer'),
  driver('DRIVER', 'Driver'),
  individualUser('INDIVIDUAL_USER', 'Individual User'),
  user('USER', 'Officer / User');

  final String code;
  final String label;
  const UserRole(this.code, this.label);

  static UserRole fromCode(String? code) {
    return UserRole.values.firstWhere(
      (r) => r.code == code,
      orElse: () => UserRole.user,
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String employeeId;
  final String designation;
  final String organizationId;
  final String organizationName;
  final String department;
  final String office;
  final UserRole role;
  final String? assignedVehicleId;
  final String? profilePhotoUrl;
  final bool requiresApproval;
  final String? approvingOfficerId;
  final String? approvingOfficerName;
  final bool isIndividual;
  final String? joinCodeUsed;
  final SubscriptionTier? personalSubscriptionTier;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.employeeId,
    required this.designation,
    this.organizationId = 'ORG-PWD-01',
    this.organizationName = 'Government of Uttar Pradesh',
    required this.department,
    required this.office,
    required this.role,
    this.assignedVehicleId,
    this.profilePhotoUrl,
    this.requiresApproval = true,
    this.approvingOfficerId,
    this.approvingOfficerName,
    this.isIndividual = false,
    this.joinCodeUsed,
    this.personalSubscriptionTier,
    required this.createdAt,
  });

  bool get isSuperAdmin => role == UserRole.superAdmin;

  bool get isCompanyAdmin =>
      role == UserRole.companyAdmin ||
      role == UserRole.departmentAdmin ||
      role == UserRole.superAdmin;

  bool get isApprover =>
      role == UserRole.approvingOfficer ||
      role == UserRole.companyAdmin ||
      role == UserRole.departmentAdmin ||
      role == UserRole.superAdmin;

  bool get isAdmin =>
      role == UserRole.companyAdmin ||
      role == UserRole.departmentAdmin ||
      role == UserRole.superAdmin;

  bool get isSelfApprover =>
      isIndividual ||
      !requiresApproval ||
      approvingOfficerId == null ||
      approvingOfficerId!.isEmpty ||
      approvingOfficerName?.toLowerCase().contains('self') == true;

  SubscriptionTier get effectiveTier =>
      personalSubscriptionTier ?? SubscriptionTier.free;

  bool get isFreeTier => effectiveTier == SubscriptionTier.free;
  bool get isProTier => effectiveTier == SubscriptionTier.pro;
  bool get isEnterpriseTier => effectiveTier == SubscriptionTier.enterprise;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'mobile': mobile,
        'employee_id': employeeId,
        'designation': designation,
        'organization_id': organizationId,
        'organization_name': organizationName,
        'department': department,
        'office': office,
        'role': role.code,
        'assigned_vehicle_id': assignedVehicleId,
        'profile_photo_url': profilePhotoUrl,
        'requires_approval': requiresApproval,
        'approving_officer_id': approvingOfficerId,
        'approving_officer_name': approvingOfficerName,
        'is_individual': isIndividual,
        'join_code_used': joinCodeUsed,
        'personal_subscription_tier': personalSubscriptionTier?.code,
        'created_at': createdAt.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        mobile: json['mobile'] as String,
        employeeId: json['employee_id'] as String? ?? 'EMP-001',
        designation: json['designation'] as String? ?? 'Executive Engineer',
        organizationId: json['organization_id'] as String? ?? 'ORG-PWD-01',
        organizationName: json['organization_name'] as String? ??
            json['department'] as String? ??
            'Government of Uttar Pradesh',
        department: json['department'] as String? ?? 'Public Works Department',
        office: json['office'] as String? ?? 'District Division Office',
        role: UserRole.fromCode(json['role'] as String?),
        assignedVehicleId: json['assigned_vehicle_id'] as String?,
        profilePhotoUrl: json['profile_photo_url'] as String?,
        requiresApproval: json['requires_approval'] as bool? ?? true,
        approvingOfficerId: json['approving_officer_id'] as String?,
        approvingOfficerName: json['approving_officer_name'] as String?,
        isIndividual: json['is_individual'] as bool? ?? false,
        joinCodeUsed: json['join_code_used'] as String?,
        personalSubscriptionTier: json['personal_subscription_tier'] != null
            ? SubscriptionTier.fromCode(
                json['personal_subscription_tier'] as String?)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  User copyWith({
    String? name,
    String? email,
    String? mobile,
    String? employeeId,
    String? designation,
    String? organizationId,
    String? organizationName,
    String? department,
    String? office,
    UserRole? role,
    String? assignedVehicleId,
    String? profilePhotoUrl,
    bool? requiresApproval,
    String? approvingOfficerId,
    String? approvingOfficerName,
    bool? isIndividual,
    String? joinCodeUsed,
    SubscriptionTier? personalSubscriptionTier,
    bool clearOrganization = false,
    bool clearAssignedVehicle = false,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      employeeId: employeeId ?? this.employeeId,
      designation: designation ?? this.designation,
      organizationId: clearOrganization ? 'INDIVIDUAL' : (organizationId ?? this.organizationId),
      organizationName: clearOrganization ? 'Personal / Individual' : (organizationName ?? this.organizationName),
      department: department ?? this.department,
      office: office ?? this.office,
      role: role ?? this.role,
      assignedVehicleId: clearAssignedVehicle ? null : (assignedVehicleId ?? this.assignedVehicleId),
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      approvingOfficerId: approvingOfficerId ?? this.approvingOfficerId,
      approvingOfficerName: approvingOfficerName ?? this.approvingOfficerName,
      isIndividual: isIndividual ?? this.isIndividual,
      joinCodeUsed: joinCodeUsed ?? this.joinCodeUsed,
      personalSubscriptionTier:
          personalSubscriptionTier ?? this.personalSubscriptionTier,
      createdAt: createdAt,
    );
  }
}
