import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/models/user.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _organizationController =
      TextEditingController(text: 'Government of Uttar Pradesh');
  final _departmentController =
      TextEditingController(text: 'Public Works Department');
  final _officeController =
      TextEditingController(text: 'District Division 1');
  final _designationController =
      TextEditingController(text: 'Assistant Engineer');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _customApproverNameController = TextEditingController();
  final _customApproverDesigController = TextEditingController();
  final _customApproverIdController = TextEditingController();
  final _joinCodeController = TextEditingController();

  int _signupModeIndex = 0; // 0: Individual, 1: Register Company, 2: Join with Code, 3: Official / Govt
  UserRole _selectedRole = UserRole.user;
  final bool _obscurePassword = true;
  bool _requiresApproval = true;
  String _selectedApproverId = 'USR-003';
  String _selectedApproverName = 'Anjali Sharma, IAS (Superintending Engineer)';

  final List<Map<String, String>> _availableApprovers = [
    {
      'id': 'NONE',
      'name': 'No Approver (Self-Approver for Department Journeys)',
    },
    {
      'id': 'USR-003',
      'name': 'Anjali Sharma, IAS (Superintending Engineer)',
    },
    {
      'id': 'USR-004',
      'name': 'Vikram Singh (State Fleet Administrator)',
    },
    {
      'id': 'USR-001',
      'name': 'Dr. S. K. Verma (Executive Engineer)',
    },
    {
      'id': 'CUSTOM',
      'name': '➕ Enter Custom Approving Officer Details',
    },
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _employeeIdController.dispose();
    _organizationController.dispose();
    _departmentController.dispose();
    _officeController.dispose();
    _designationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _customApproverNameController.dispose();
    _customApproverDesigController.dispose();
    _customApproverIdController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final isSelf = !_requiresApproval || _selectedApproverId == 'NONE';
      final String finalApproverName;
      final String? finalApproverId;

      if (isSelf) {
        finalApproverName = 'Self-Approver';
        finalApproverId = null;
      } else if (_selectedApproverId == 'CUSTOM') {
        final name = _customApproverNameController.text.trim();
        final desig = _customApproverDesigController.text.trim();
        finalApproverName = desig.isNotEmpty ? '$name ($desig)' : name;
        finalApproverId = _customApproverIdController.text.trim().isNotEmpty
            ? _customApproverIdController.text.trim()
            : 'APPR-CUSTOM';
      } else {
        finalApproverName = _selectedApproverName;
        finalApproverId = _selectedApproverId;
      }

      bool success = false;
      if (_signupModeIndex == 0) {
        // 1. Individual User (Personal Logbook)
        success = await ref.read(authProvider.notifier).signupIndividual(
              fullName: _fullNameController.text.trim(),
              mobile: _mobileController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      } else if (_signupModeIndex == 1) {
        // 2. Register Company Admin
        success = await ref.read(authProvider.notifier).signupCompanyAdmin(
              fullName: _fullNameController.text.trim(),
              companyName: _organizationController.text.trim().isNotEmpty
                  ? _organizationController.text.trim()
                  : 'Company Fleet',
              mobile: _mobileController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      } else if (_signupModeIndex == 2) {
        // 3. Join with Code
        success = await ref.read(authProvider.notifier).signupJoinWithCode(
              fullName: _fullNameController.text.trim(),
              joinCode: _joinCodeController.text.trim(),
              mobile: _mobileController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              role: _selectedRole == UserRole.driver
                  ? UserRole.driver
                  : UserRole.user,
            );
      } else {
        // 4. Department / Official Account
        success = await ref.read(authProvider.notifier).signup(
              fullName: _fullNameController.text.trim(),
              mobile: _mobileController.text.trim(),
              email: _emailController.text.trim(),
              employeeId: _employeeIdController.text.trim(),
              organizationName: _organizationController.text.trim(),
              department: _departmentController.text.trim(),
              office: _officeController.text.trim(),
              designation: _designationController.text.trim(),
              password: _passwordController.text,
              role: _selectedRole,
              requiresApproval: !isSelf,
              approvingOfficerId: finalApproverId,
              approvingOfficerName: finalApproverName,
            );
      }

      if (success && mounted) {
        context.go('/dashboard');
      } else if (!success && mounted) {
        final err = ref.read(authProvider).errorMessage;
        if (err != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final String appBarTitle;
    final String headingText;
    final String subtitleText;

    switch (_signupModeIndex) {
      case 0:
        appBarTitle = 'Create Personal Account';
        headingText = 'Individual Registration';
        subtitleText =
            'Track journeys, mileage, fuel & expenses for your personal vehicle.';
        break;
      case 1:
        appBarTitle = 'Register Company Fleet';
        headingText = 'Company Admin Registration';
        subtitleText =
            'Set up an organization fleet workspace and generate invite codes for your team.';
        break;
      case 2:
        appBarTitle = 'Join Organization';
        headingText = 'Join Fleet Workspace';
        subtitleText =
            'Enter the 6-digit code provided by your organization or fleet manager.';
        break;
      default:
        appBarTitle = 'Create Official Account';
        headingText = 'Government / Department Portal';
        subtitleText =
            'Official departmental logbook access with hierarchical approval routing.';
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        title: Text(appBarTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.marginMobile,
            vertical: 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mode Selection Tabs
                const Text(
                  'Choose Registration Type',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildModeChip(0, '👤 Individual', 'Personal'),
                      const SizedBox(width: 8),
                      _buildModeChip(1, '🏢 Register Company', 'Fleet Admin'),
                      const SizedBox(width: 8),
                      _buildModeChip(2, '🔑 Join with Code', 'Team Member'),
                      const SizedBox(width: 8),
                      _buildModeChip(3, '🏛️ Official / Govt', 'Departmental'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Heading & Subtitle
                Text(
                  headingText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Highlight Banner for Selected Mode
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _signupModeIndex == 0
                        ? AppColors.primary.withValues(alpha: 0.06)
                        : (_signupModeIndex == 1
                            ? Colors.indigo.withValues(alpha: 0.06)
                            : (_signupModeIndex == 2
                                ? Colors.teal.withValues(alpha: 0.06)
                                : AppColors.surfaceContainerLow)),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: _signupModeIndex == 0
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : (_signupModeIndex == 1
                              ? Colors.indigo.withValues(alpha: 0.2)
                              : (_signupModeIndex == 2
                                  ? Colors.teal.withValues(alpha: 0.2)
                                  : AppColors.borderSubtle)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _signupModeIndex == 0
                            ? Icons.stars_rounded
                            : (_signupModeIndex == 1
                                ? Icons.business_center_rounded
                                : (_signupModeIndex == 2
                                    ? Icons.vpn_key_rounded
                                    : Icons.account_balance_rounded)),
                        size: 20,
                        color: _signupModeIndex == 0
                            ? AppColors.primary
                            : (_signupModeIndex == 1
                                ? Colors.indigo
                                : (_signupModeIndex == 2
                                    ? Colors.teal
                                    : AppColors.secondary)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _signupModeIndex == 0
                              ? '⚡ Self-Managed: No approvals needed. Immediate digital log book access.'
                              : (_signupModeIndex == 1
                                  ? '🚀 Multi-Tenant: Receive an instant 6-digit Join Code for onboarding drivers and tracking team fleets.'
                                  : (_signupModeIndex == 2
                                      ? '🔗 Direct Link: Enter your company invite code to automatically sync with your team fleet.'
                                      : '📋 Departmental Compliance: Supports official divisions, designated approvers & state audit rules.')),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _signupModeIndex == 0
                                ? AppColors.primary
                                : (_signupModeIndex == 1
                                    ? Colors.indigo
                                    : (_signupModeIndex == 2
                                        ? Colors.teal.shade800
                                        : AppColors.onSurface)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // MODE 2 SPECIFIC: Join Code Field
                if (_signupModeIndex == 2) ...[
                  CustomTextField(
                    label: 'Organization Join Code *',
                    hint: 'e.g. PWD-8042 or LOG-3195',
                    controller: _joinCodeController,
                    isRequired: true,
                    prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter 6-digit join code'
                        : null,
                  ),
                  const SizedBox(height: 14),
                ],

                // MODE 1 SPECIFIC: Company Name Field
                if (_signupModeIndex == 1) ...[
                  CustomTextField(
                    label: 'Company / Organization Name *',
                    hint: 'e.g. Acme Logistics, Apex Transport Ltd.',
                    controller: _organizationController,
                    isRequired: true,
                    prefixIcon:
                        const Icon(Icons.corporate_fare_outlined, size: 20),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Company name required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                ],

                // Full Name (Common)
                CustomTextField(
                  label: _signupModeIndex == 1
                      ? 'Admin Full Name *'
                      : 'Full Name *',
                  hint: _signupModeIndex == 0
                      ? 'e.g. Rahul Verma'
                      : 'e.g. Dr. Rajesh Sharma',
                  controller: _fullNameController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // Contact Details: Mobile & (Employee ID for Official)
                if (_signupModeIndex == 3) ...[
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Mobile Number *',
                          hint: '9876543210',
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          isRequired: true,
                          prefixIcon:
                              const Icon(Icons.phone_outlined, size: 20),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Employee ID *',
                          hint: 'GOV-4412',
                          controller: _employeeIdController,
                          isRequired: true,
                          prefixIcon:
                              const Icon(Icons.badge_outlined, size: 20),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  CustomTextField(
                    label: 'Mobile Number *',
                    hint: '9876543210',
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    isRequired: true,
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ],
                const SizedBox(height: 14),

                // Email Address
                CustomTextField(
                  label: _signupModeIndex == 1
                      ? 'Work / Business Email *'
                      : (_signupModeIndex == 3
                          ? 'Official Email *'
                          : 'Email Address *'),
                  hint: _signupModeIndex == 1
                      ? 'admin@company.com'
                      : (_signupModeIndex == 3
                          ? 'name@gov.in'
                          : 'name@example.com'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // MODE 2 (Join with Code): Role Dropdown (Driver vs Officer)
                if (_signupModeIndex == 2) ...[
                  const Text(
                    'Your Role in Organization *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<UserRole>(
                    initialValue: _selectedRole == UserRole.driver
                        ? UserRole.driver
                        : UserRole.user,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        borderSide:
                            const BorderSide(color: AppColors.borderSubtle),
                      ),
                      prefixIcon:
                          const Icon(Icons.assignment_ind_outlined, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.driver,
                        child: Text('Driver (Logs journeys & vehicle runs)'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.user,
                        child:
                            Text('Field Officer / Staff (Logs official travel)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // MODE 3 (Official): Department, Office, Role & Approval
                if (_signupModeIndex == 3) ...[
                  CustomTextField(
                    label: 'Government / Organization Name *',
                    hint: 'e.g. Government of Uttar Pradesh',
                    controller: _organizationController,
                    isRequired: true,
                    prefixIcon:
                        const Icon(Icons.corporate_fare_outlined, size: 20),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Department / Unit *',
                    controller: _departmentController,
                    isRequired: true,
                    prefixIcon:
                        const Icon(Icons.account_balance_outlined, size: 20),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Office / Division *',
                    controller: _officeController,
                    isRequired: true,
                    prefixIcon:
                        const Icon(Icons.location_city_outlined, size: 20),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Account Role *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<UserRole>(
                    initialValue: _selectedRole,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        borderSide:
                            const BorderSide(color: AppColors.borderSubtle),
                      ),
                      prefixIcon:
                          const Icon(Icons.assignment_ind_outlined, size: 20),
                    ),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(
                          role.label,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Approval Workflow Configuration Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.verified_user_outlined,
                                      size: 18, color: AppColors.primary),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Journey Approval Required',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _requiresApproval,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  _requiresApproval = val;
                                  if (!val) {
                                    _selectedApproverId = 'NONE';
                                    _selectedApproverName =
                                        'No Approver (Self-Approver for Department Journeys)';
                                  } else {
                                    _selectedApproverId = 'USR-003';
                                    _selectedApproverName =
                                        'Anjali Sharma, IAS (Superintending Engineer)';
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _requiresApproval
                              ? 'Logged journeys will be routed to the designated Approving Officer for verification.'
                              : '⚡ Self-Approver Mode: Department exempts this role from secondary approval. Completed journeys are automatically certified.',
                          style: TextStyle(
                            fontSize: 11,
                            color: _requiresApproval
                                ? AppColors.secondary
                                : AppColors.primary,
                            fontWeight: _requiresApproval
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                        if (_requiresApproval) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Designated Approving Officer *',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedApproverId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSm),
                              ),
                              prefixIcon: const Icon(
                                  Icons.person_pin_outlined,
                                  size: 18,
                                  color: AppColors.primary),
                            ),
                            items: _availableApprovers.map((appr) {
                              final isNone = appr['id'] == 'NONE';
                              return DropdownMenuItem<String>(
                                value: appr['id'],
                                child: Text(
                                  appr['name']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isNone
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isNone
                                        ? AppColors.primary
                                        : AppColors.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedApproverId = val;
                                  if (val != 'CUSTOM') {
                                    _selectedApproverName =
                                        _availableApprovers.firstWhere(
                                            (a) => a['id'] == val)['name']!;
                                  }
                                  if (val == 'NONE') {
                                    _requiresApproval = false;
                                  }
                                });
                              }
                            },
                          ),
                          if (_selectedApproverId == 'CUSTOM') ...[
                            const SizedBox(height: 12),
                            CustomTextField(
                              label: 'Approving Officer Name',
                              hint: 'e.g. S. P. Sharma',
                              controller: _customApproverNameController,
                              isRequired: true,
                              prefixIcon: const Icon(Icons.person_outline,
                                  size: 20),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    label: 'Designation',
                                    hint: 'e.g. Chief Engineer',
                                    controller:
                                        _customApproverDesigController,
                                    isRequired: true,
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Required'
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: CustomTextField(
                                    label: 'Officer / Employee ID',
                                    hint: 'e.g. EMP-998',
                                    controller:
                                        _customApproverIdController,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Password Fields (Common to all modes)
                CustomTextField(
                  label: 'Password *',
                  hint: 'Minimum 6 characters',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  validator: (v) => v == null || v.length < 6
                      ? 'At least 6 characters'
                      : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Confirm Password *',
                  hint: 'Re-enter password',
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _signupModeIndex == 0
                      ? 'Create Personal Account'
                      : (_signupModeIndex == 1
                          ? 'Register Company & Get Code'
                          : (_signupModeIndex == 2
                              ? 'Join Organization'
                              : 'Create Official Account')),
                  isLoading: authState.isLoading,
                  onPressed: _handleSignup,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip(int index, String title, String subtitle) {
    final isSelected = _signupModeIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _signupModeIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
