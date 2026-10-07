import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/organization.dart';
import '../storage/local_database.dart';

class AuthState {
  final User? currentUser;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.currentUser,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    User? currentUser,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  void _init() {
    final user = LocalDatabase.instance.currentUser ??
        (LocalDatabase.instance.users.isNotEmpty
            ? LocalDatabase.instance.users.first
            : null);
    if (user != null) {
      state = AuthState(
        currentUser: user,
        isAuthenticated: true,
      );
    }
  }

  Future<void> loginAsUser(User user) async {
    await LocalDatabase.instance.setCurrentUser(user);
    state = AuthState(
      currentUser: user,
      isAuthenticated: true,
      isLoading: false,
    );
  }

  Future<bool> loginWithPassword({
    required String identifier, // Mobile or Email
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 300));

    final users = LocalDatabase.instance.users;
    final cleanId = identifier.trim().toLowerCase();

    final match = users.firstWhere(
      (u) =>
          u.email.toLowerCase() == cleanId ||
          u.mobile.replaceAll(' ', '') == cleanId.replaceAll(' ', '') ||
          u.name.toLowerCase().contains(cleanId) ||
          (cleanId.contains('approv') && u.role == UserRole.approvingOfficer) ||
          (cleanId.contains('anjali') && u.role == UserRole.approvingOfficer) ||
          (cleanId.contains('driver') && u.role == UserRole.driver),
      orElse: () => users.first,
    );

    await LocalDatabase.instance.setCurrentUser(match);
    state = AuthState(
      currentUser: match,
      isAuthenticated: true,
      isLoading: false,
    );
    return true;
  }

  Future<bool> loginWithOtp({required String mobile, required String otp}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 300));

    final users = LocalDatabase.instance.users;
    final match = users.firstWhere(
      (u) => u.mobile.replaceAll(' ', '').contains(mobile.replaceAll(' ', '')),
      orElse: () => users.first,
    );

    await LocalDatabase.instance.setCurrentUser(match);
    state = AuthState(
      currentUser: match,
      isAuthenticated: true,
      isLoading: false,
    );
    return true;
  }

  Future<bool> signup({
    required String fullName,
    required String mobile,
    required String email,
    required String employeeId,
    String organizationName = 'Government of Uttar Pradesh',
    required String department,
    required String office,
    required String designation,
    required String password,
    required UserRole role,
    bool requiresApproval = true,
    String? approvingOfficerId,
    String? approvingOfficerName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 300));

    final newUser = User(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      name: fullName,
      email: email,
      mobile: mobile,
      employeeId: employeeId,
      designation: designation,
      organizationName: organizationName.isNotEmpty ? organizationName : 'Government of Uttar Pradesh',
      department: department,
      office: office,
      role: role,
      requiresApproval: requiresApproval,
      approvingOfficerId: approvingOfficerId,
      approvingOfficerName: approvingOfficerName,
      createdAt: DateTime.now(),
    );

    await LocalDatabase.instance.setCurrentUser(newUser);
    state = AuthState(
      currentUser: newUser,
      isAuthenticated: true,
      isLoading: false,
    );
    return true;
  }

  /// Signup as an Individual User (Personal Logbook)
  Future<bool> signupIndividual({
    required String fullName,
    required String mobile,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 300));

    final newUser = User(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      name: fullName,
      email: email,
      mobile: mobile,
      employeeId: 'IND-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
      designation: 'Personal Vehicle Owner',
      organizationId: '',
      organizationName: 'Personal / Individual',
      department: 'Personal',
      office: 'Self',
      role: UserRole.individualUser,
      isIndividual: true,
      requiresApproval: false,
      createdAt: DateTime.now(),
    );

    await LocalDatabase.instance.setCurrentUser(newUser);
    state = AuthState(
      currentUser: newUser,
      isAuthenticated: true,
      isLoading: false,
    );
    return true;
  }

  /// Register a new Company / Organization and set current user as Company Admin
  Future<bool> signupCompanyAdmin({
    required String fullName,
    required String companyName,
    required String mobile,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 300));

    final userId = 'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // 1. Create Organization & generate unique Join Code
    final org = await LocalDatabase.instance.createOrganization(
      name: companyName,
      adminId: userId,
      adminName: fullName,
      contactEmail: email,
      contactMobile: mobile,
    );

    // 2. Create User as Company Admin
    final adminUser = User(
      id: userId,
      name: fullName,
      email: email,
      mobile: mobile,
      employeeId: 'ADM-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
      designation: 'Company Fleet Administrator',
      organizationId: org.id,
      organizationName: org.name,
      department: 'Fleet Management',
      office: 'Corporate HQ',
      role: UserRole.companyAdmin,
      isIndividual: false,
      requiresApproval: false,
      createdAt: DateTime.now(),
    );

    await LocalDatabase.instance.setCurrentUser(adminUser);
    state = AuthState(
      currentUser: adminUser,
      isAuthenticated: true,
      isLoading: false,
    );
    return true;
  }

  /// Join an existing organization via 6-digit Join Code
  Future<bool> signupJoinWithCode({
    required String fullName,
    required String joinCode,
    required String mobile,
    required String email,
    required String password,
    required UserRole role, // Driver or Officer
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 300));

    final org = LocalDatabase.instance.getOrganizationByCode(joinCode);
    if (org == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid Company Join Code. Please check with your Company Admin.',
      );
      return false;
    }

    final userId = 'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final memberUser = User(
      id: userId,
      name: fullName,
      email: email,
      mobile: mobile,
      employeeId: 'MEM-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
      designation: role == UserRole.driver ? 'Fleet Driver' : 'Field Officer',
      organizationId: org.id,
      organizationName: org.name,
      department: 'Fleet Operations',
      office: 'Regional Operations',
      role: role,
      joinCodeUsed: org.code,
      isIndividual: false,
      requiresApproval: role == UserRole.driver,
      createdAt: DateTime.now(),
    );

    await LocalDatabase.instance.setCurrentUser(memberUser);
    await LocalDatabase.instance.joinOrganizationByCode(userId, joinCode);

    state = AuthState(
      currentUser: memberUser,
      isAuthenticated: true,
      isLoading: false,
    );
    return true;
  }

  Future<void> switchUserRole(UserRole role) async {
    final users = LocalDatabase.instance.users;
    final matchingUser = users.firstWhere(
      (u) => u.role == role,
      orElse: () => (state.currentUser ?? users.first).copyWith(role: role),
    );
    await LocalDatabase.instance.setCurrentUser(matchingUser);
    state = AuthState(
      currentUser: matchingUser,
      isAuthenticated: true,
      isLoading: false,
    );
  }

  Future<void> updateProfile({
    required String name,
    required String designation,
    String? organizationName,
    required String department,
    required String office,
    required String mobile,
    bool? requiresApproval,
    String? approvingOfficerId,
    String? approvingOfficerName,
  }) async {
    if (state.currentUser == null) return;
    final updated = state.currentUser!.copyWith(
      name: name,
      designation: designation,
      organizationName: organizationName ?? state.currentUser!.organizationName,
      department: department,
      office: office,
      mobile: mobile,
      requiresApproval: requiresApproval,
      approvingOfficerId: approvingOfficerId,
      approvingOfficerName: approvingOfficerName,
    );
    await LocalDatabase.instance.setCurrentUser(updated);
    state = state.copyWith(currentUser: updated);
  }

  Future<bool> upgradeSubscriptionTier(SubscriptionTier newTier) async {
    final user = state.currentUser;
    if (user == null) return false;

    if (!user.isIndividual && user.organizationId.isNotEmpty) {
      await LocalDatabase.instance.updateOrganizationTier(user.organizationId, newTier);
    }
    await LocalDatabase.instance.updateUserSubscriptionTier(user.id, newTier);

    final refreshedUser = LocalDatabase.instance.currentUser ??
        user.copyWith(personalSubscriptionTier: newTier);
    state = state.copyWith(currentUser: refreshedUser);
    return true;
  }

  Future<void> logout() async {
    await LocalDatabase.instance.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
