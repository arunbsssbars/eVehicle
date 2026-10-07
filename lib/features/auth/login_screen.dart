import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/models/user.dart';
import '../../core/storage/seed_data.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/journey_provider.dart';
import '../../core/providers/vehicle_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKeyPassword = GlobalKey<FormState>();
  final _formKeyOtp = GlobalKey<FormState>();

  final _identifierController =
      TextEditingController(text: 'sk.verma@gov.in');
  final _passwordController = TextEditingController(text: 'Password@123');
  final _mobileController = TextEditingController(text: '+91 98765 43210');

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _handlePasswordLogin() async {
    if (_formKeyPassword.currentState?.validate() ?? false) {
      final success = await ref.read(authProvider.notifier).loginWithPassword(
            identifier: _identifierController.text.trim(),
            password: _passwordController.text,
          );
      if (success && mounted) {
        ref.read(journeyProvider.notifier).refresh();
        ref.read(vehicleProvider.notifier).refresh();
        context.go('/dashboard');
      }
    }
  }

  void _handleSendOtp() {
    if (_formKeyOtp.currentState?.validate() ?? false) {
      context.push('/otp-verification', extra: _mobileController.text.trim());
    }
  }

  void _quickSwitchDemoUser(User user) async {
    await ref.read(authProvider.notifier).loginAsUser(user);
    ref.read(journeyProvider.notifier).refresh();
    ref.read(vehicleProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged in as ${user.name} (${user.role.label})'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.marginMobile,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Brand Icon & Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLg),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.directions_car_filled_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: const Text(
                      'OFFICIAL GOV PORTAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your official credentials to access digital log books.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 24),
              // Login Mode Tabs (Password vs OTP)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd - 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.secondary,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Password Login'),
                    Tab(text: 'OTP Login'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Tab Views
              SizedBox(
                height: 240,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Password Form
                    Form(
                      key: _formKeyPassword,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            label: 'Mobile Number or Email',
                            hint: 'name@gov.in or 9876543210',
                            controller: _identifierController,
                            prefixIcon: const Icon(Icons.person_outline,
                                size: 20, color: AppColors.secondary),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Password',
                            hint: '••••••••',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            prefixIcon: const Icon(Icons.lock_outline,
                                size: 20, color: AppColors.secondary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: AppColors.secondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tab 2: OTP Form
                    Form(
                      key: _formKeyOtp,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            label: 'Registered Mobile Number',
                            hint: '+91 98765 43210',
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(Icons.phone_outlined,
                                size: 20, color: AppColors.secondary),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'A 6-digit one-time password (OTP) will be sent to your mobile for verification.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Submit Button
              PrimaryButton(
                label: _tabController.index == 0 ? 'Login' : 'Send OTP',
                isLoading: authState.isLoading,
                onPressed: () {
                  if (_tabController.index == 0) {
                    _handlePasswordLogin();
                  } else {
                    _handleSendOtp();
                  }
                },
              ),
              const SizedBox(height: 16),
              // Sign Up Link
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(fontSize: 13, color: AppColors.secondary),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/signup'),
                    child: const Text(
                      'Register Now',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Quick Demo Role Switcher
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.bolt, size: 16, color: AppColors.warning),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'QUICK DEMO LOGIN (1-TAP)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurface,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Select Any Role',
                          style: TextStyle(fontSize: 10, color: AppColors.secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final u in SeedData.demoUsers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => _quickSwitchDemoUser(u),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: u.isSuperAdmin
                                  ? Colors.deepPurple.withValues(alpha: 0.06)
                                  : (u.isCompanyAdmin
                                      ? Colors.indigo.withValues(alpha: 0.06)
                                      : (u.isIndividual
                                          ? Colors.teal.withValues(alpha: 0.06)
                                          : (u.role == UserRole.approvingOfficer
                                              ? AppColors.primary.withValues(alpha: 0.06)
                                              : Colors.white))),
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusMd),
                              border: Border.all(
                                color: u.isSuperAdmin
                                    ? Colors.deepPurple
                                    : (u.isCompanyAdmin
                                        ? Colors.indigo
                                        : (u.isIndividual
                                            ? Colors.teal
                                            : (u.role == UserRole.approvingOfficer
                                                ? AppColors.primary
                                                : AppColors.borderSubtle))),
                                width: (u.isSuperAdmin || u.isCompanyAdmin || u.role == UserRole.approvingOfficer) ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: u.isSuperAdmin
                                      ? Colors.deepPurple
                                      : (u.isCompanyAdmin
                                          ? Colors.indigo
                                          : (u.isIndividual
                                              ? Colors.teal
                                              : (u.role == UserRole.approvingOfficer
                                                  ? AppColors.primary
                                                  : (u.role == UserRole.driver
                                                      ? AppColors.secondary
                                                      : AppColors.primaryFixed)))),
                                  child: Icon(
                                    u.isSuperAdmin
                                        ? Icons.shield_rounded
                                        : (u.isCompanyAdmin
                                            ? Icons.business_center_rounded
                                            : (u.isIndividual
                                                ? Icons.directions_car_rounded
                                                : (u.role == UserRole.approvingOfficer
                                                    ? Icons.verified_user
                                                    : (u.role == UserRole.driver
                                                        ? Icons.drive_eta
                                                        : Icons.person)))),
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              u.name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: u.isSuperAdmin
                                                  ? Colors.deepPurple
                                                  : (u.isCompanyAdmin
                                                      ? Colors.indigo
                                                      : (u.isIndividual
                                                          ? Colors.teal
                                                          : (u.role == UserRole.approvingOfficer
                                                              ? AppColors.success
                                                              : (u.role == UserRole.driver
                                                                  ? AppColors.secondary
                                                                  : AppColors.primary)))),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              u.isSuperAdmin
                                                  ? 'SUPER ADMIN'
                                                  : (u.isCompanyAdmin
                                                      ? 'COMPANY ADMIN'
                                                      : (u.isIndividual
                                                          ? 'INDIVIDUAL'
                                                          : (u.role == UserRole.approvingOfficer
                                                              ? 'APPROVER'
                                                              : (u.role == UserRole.driver
                                                                  ? 'DRIVER'
                                                                  : 'OFFICER')))),
                                              style: const TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${u.designation} • ${u.email}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.secondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 12, color: AppColors.secondary),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
