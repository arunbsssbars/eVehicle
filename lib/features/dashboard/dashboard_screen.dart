import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/models/user.dart';
import '../../core/models/journey.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/odometer_display.dart';
import '../../core/widgets/journey_card.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/journey_provider.dart';
import '../../core/providers/vehicle_provider.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/widgets/usage_quota_card.dart';
import '../../core/storage/seed_data.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showRoleSwitcherModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Material(
            type: MaterialType.transparency,
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Switch Active User / Role',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Switch persona instantly to test multi-tenancy, Super Admin control, or personal logbooks.',
                  style: TextStyle(fontSize: 12, color: AppColors.secondary),
                ),
                const SizedBox(height: 14),

                // 1. Super Admin
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.shield_rounded, color: Colors.white, size: 18),
                  ),
                  title: const Text('Arun Verma (Platform Owner)',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Super Admin • All Organizations & Global Limits'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('SUPER ADMIN',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  onTap: () async {
                    final u = SeedData.demoUsers.firstWhere(
                      (user) => user.id == 'USR-SUPER',
                      orElse: () => SeedData.demoUsers.first,
                    );
                    await ref.read(authProvider.notifier).loginAsUser(u);
                    ref.read(journeyProvider.notifier).refresh();
                    ref.read(vehicleProvider.notifier).refresh();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Switched to Super Administrator mode!'),
                        backgroundColor: Colors.deepPurple,
                      ),
                    );
                  },
                ),
                const Divider(height: 12),

                // 2. Company Admin (Logix Transports)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.business_center_rounded, color: Colors.white, size: 18),
                  ),
                  title: const Text('Vikram Singh (Fleet Manager)',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Company Admin • Logix Transports Fleet (LOG-3195)'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('ORG ADMIN',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  onTap: () async {
                    final u = SeedData.demoUsers.firstWhere(
                      (user) => user.id == 'USR-004',
                      orElse: () => SeedData.demoUsers.first,
                    );
                    await ref.read(authProvider.notifier).loginAsUser(u);
                    ref.read(journeyProvider.notifier).refresh();
                    ref.read(vehicleProvider.notifier).refresh();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Switched to Company Admin mode!'),
                        backgroundColor: Colors.indigo,
                      ),
                    );
                  },
                ),
                const Divider(height: 12),

                // 3. Individual User (Personal Car Owner)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.directions_car_rounded, color: Colors.white, size: 18),
                  ),
                  title: const Text('Vikram Mehta (Personal Car Owner)',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Individual User • Zero Bureaucracy Logbook'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('INDIVIDUAL',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  onTap: () async {
                    final u = SeedData.demoUsers.firstWhere(
                      (user) => user.id == 'USR-INDIV',
                      orElse: () => SeedData.demoUsers.first,
                    );
                    await ref.read(authProvider.notifier).loginAsUser(u);
                    ref.read(journeyProvider.notifier).refresh();
                    ref.read(vehicleProvider.notifier).refresh();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Switched to Individual User mode!'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  },
                ),
                const Divider(height: 12),

                // 4. Approving Officer
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.verified_user, color: Colors.white, size: 18),
                  ),
                  title: const Text('Anjali Sharma, IAS',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Superintending Engineer (Approving Officer)'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('APPROVER',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  onTap: () async {
                    final u = SeedData.demoUsers.firstWhere(
                      (user) => user.id == 'USR-003',
                      orElse: () => SeedData.demoUsers.first,
                    );
                    await ref.read(authProvider.notifier).loginAsUser(u);
                    ref.read(journeyProvider.notifier).refresh();
                    ref.read(vehicleProvider.notifier).refresh();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Switched to Approving Officer mode!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
                const Divider(height: 12),

                // 5. Executive Engineer
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryFixed,
                    child: Icon(Icons.person, color: AppColors.primary, size: 18),
                  ),
                  title: const Text('Dr. S. K. Verma',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Executive Engineer (Officer)'),
                  onTap: () async {
                    final u = SeedData.demoUsers.firstWhere(
                      (user) => user.id == 'USR-001',
                      orElse: () => SeedData.demoUsers.first,
                    );
                    await ref.read(authProvider.notifier).loginAsUser(u);
                    ref.read(journeyProvider.notifier).refresh();
                    ref.read(vehicleProvider.notifier).refresh();
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(height: 12),

                // 6. Senior Fleet Driver
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.secondary,
                    child: Icon(Icons.drive_eta, color: Colors.white, size: 18),
                  ),
                  title: const Text('Rajesh Kumar',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Senior Fleet Driver'),
                  onTap: () async {
                    final u = SeedData.demoUsers.firstWhere(
                      (user) => user.id == 'USR-002',
                      orElse: () => SeedData.demoUsers.first,
                    );
                    await ref.read(authProvider.notifier).loginAsUser(u);
                    ref.read(journeyProvider.notifier).refresh();
                    ref.read(vehicleProvider.notifier).refresh();
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final journeyState = ref.watch(journeyProvider);
    final vehicleState = ref.watch(vehicleProvider);
    final appState = ref.watch(appStateProvider);

    final currentUser = authState.currentUser;
    final activeVehicle = vehicleState.selectedVehicle ??
        (vehicleState.vehicles.isNotEmpty ? vehicleState.vehicles.first : null);
    final activeJourney = journeyState.activeJourney;

    final now = DateTime.now();
    final todayJourneys = journeyState.journeys.where((j) {
      return j.journeyDate.year == now.year &&
          j.journeyDate.month == now.month &&
          j.journeyDate.day == now.day;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.marginMobile,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Official Header & Greetings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()},',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondary,
                        ),
                      ),
                      Text(
                        currentUser?.name ?? 'Officer',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.account_balance_outlined,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              currentUser?.department ?? 'Public Works Department',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.outline),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              currentUser?.office ?? 'Division Office',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.outline,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Interactive Role Badge
                    InkWell(
                      onTap: () => _showRoleSwitcherModal(context, ref),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: currentUser?.isSuperAdmin == true
                              ? Colors.deepPurple.withValues(alpha: 0.15)
                              : (currentUser?.isCompanyAdmin == true
                                  ? Colors.indigo.withValues(alpha: 0.15)
                                  : (currentUser?.isIndividual == true
                                      ? Colors.teal.withValues(alpha: 0.15)
                                      : (currentUser?.role == UserRole.approvingOfficer
                                          ? AppColors.success.withValues(alpha: 0.15)
                                          : AppColors.primaryFixed))),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusSm),
                          border: Border.all(
                            color: currentUser?.isSuperAdmin == true
                                ? Colors.deepPurple
                                : (currentUser?.isCompanyAdmin == true
                                    ? Colors.indigo
                                    : (currentUser?.isIndividual == true
                                        ? Colors.teal
                                        : (currentUser?.role == UserRole.approvingOfficer
                                            ? AppColors.success
                                            : AppColors.primary.withValues(alpha: 0.3)))),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentUser?.isSuperAdmin == true
                                  ? 'SUPER'
                                  : (currentUser?.isCompanyAdmin == true
                                      ? 'ADMIN'
                                      : (currentUser?.isIndividual == true
                                          ? 'INDIVIDUAL'
                                          : (currentUser?.role.label.split(' ').first.toUpperCase() ?? 'OFFICER'))),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: currentUser?.isSuperAdmin == true
                                    ? Colors.deepPurple
                                    : (currentUser?.isCompanyAdmin == true
                                        ? Colors.indigo
                                        : (currentUser?.isIndividual == true
                                            ? Colors.teal
                                            : (currentUser?.role == UserRole.approvingOfficer
                                                ? AppColors.success
                                                : AppColors.primary))),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 13,
                              color: currentUser?.isSuperAdmin == true
                                  ? Colors.deepPurple
                                  : (currentUser?.isCompanyAdmin == true
                                      ? Colors.indigo
                                      : (currentUser?.isIndividual == true
                                          ? Colors.teal
                                          : (currentUser?.role == UserRole.approvingOfficer
                                              ? AppColors.success
                                              : AppColors.primary))),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Plan Tier Badge Button
                    InkWell(
                      onTap: () => context.push('/plans'),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: currentUser?.isProTier == true
                              ? Colors.deepPurple.withValues(alpha: 0.12)
                              : (currentUser?.isEnterpriseTier == true
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : Colors.amber.withValues(alpha: 0.15)),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusSm),
                          border: Border.all(
                            color: currentUser?.isProTier == true
                                ? Colors.deepPurple
                                : (currentUser?.isEnterpriseTier == true
                                    ? AppColors.primary
                                    : Colors.amber.shade700),
                          ),
                        ),
                        child: Text(
                          currentUser?.effectiveTier.label
                                  .toUpperCase()
                                  .split(' ')
                                  .first ??
                              'FREE',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: currentUser?.isProTier == true
                                ? Colors.deepPurple
                                : (currentUser?.isEnterpriseTier == true
                                    ? AppColors.primary
                                    : Colors.amber.shade900),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    // Notification Icon with Badge
                    Stack(
                      children: [
                        IconButton(
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.notifications_none_rounded,
                              size: 22),
                          color: AppColors.onSurface,
                          onPressed: () => _showNotificationsModal(context, ref),
                        ),
                        if (appState.unreadNotificationsCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${appState.unreadNotificationsCount}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Role / Tenant Control Banner
            if (currentUser?.isSuperAdmin == true) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E1065), Color(0xFF581C87)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'SUPER ADMIN MODE',
                                style: TextStyle(
                                  color: Color(0xFFE9D5FF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'GLOBAL',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Platform Control Center',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Manage organizations, subscription tiers & global telemetry.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => context.push('/super-admin'),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: const Text(
                          'Open Hub',
                          style: TextStyle(
                            color: Color(0xFF581C87),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (currentUser?.isCompanyAdmin == true) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.business_center_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ORGANIZATION ADMIN',
                            style: TextStyle(
                              color: Color(0xFFBFDBFE),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentUser?.organizationName ?? 'Company Fleet',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Invite team drivers & configure fleet vehicles.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => context.push('/company-admin'),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: const Text(
                          'Manage',
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (currentUser?.isIndividual == true) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.directions_car_rounded, color: Colors.teal, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Personal Logbook Mode: Self-managed vehicle logs with zero approval bottlenecks.',
                        style: TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Free Tier Usage Quota Meter (Hidden for Pro & Enterprise)
            const UsageQuotaCard(),

            // 2. Active Journey Alert Banner (if in progress)
            if (activeJourney != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Material(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.18),
                  child: InkWell(
                    onTap: () => context.push('/journeys/active'),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusLg),
                    splashColor: AppColors.primary.withValues(alpha: 0.12),
                    highlightColor: AppColors.primary.withValues(alpha: 0.06),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusLg),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.navigation_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      'JOURNEY IN PROGRESS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.circle,
                                        size: 6, color: AppColors.success),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'From: ${activeJourney.startLocation}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => context.push('/journeys/active'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              minimumSize: const Size(60, 36),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Resume',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                                SizedBox(width: 2),
                                Icon(Icons.chevron_right_rounded,
                                    size: 16, color: Colors.white),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // 3. Primary CTA: Start Journey & Multi-Journey (Shifted to Top with Matching Colors)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0040A8), Color(0xFF0052CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0052CC).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          if (activeJourney != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'A journey is already active. Please complete it first.'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            context.push('/journeys/active');
                          } else {
                            context.push('/journeys/start');
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.navigation_rounded,
                                    size: 18, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Start Journey',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(Icons.chevron_right_rounded,
                                    size: 18, color: Colors.white70),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0040A8), Color(0xFF0052CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0052CC).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => context.push('/journeys/batch-create'),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.playlist_add_rounded,
                                    size: 19, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Multi-Journey',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(Icons.chevron_right_rounded,
                                    size: 18, color: Colors.white70),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4. Current Vehicle Card (Folded by default, placed after buttons)
            if (activeVehicle != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: ExpansionTile(
                      key: const PageStorageKey('dashboard_active_vehicle_tile'),
                      initiallyExpanded: false,
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd),
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      activeVehicle.registrationNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${activeVehicle.make} ${activeVehicle.model}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        StatusBadge.fromVehicleStatus(
                            activeVehicle.status),
                      ],
                    ),
                    children: [
                      const Divider(
                        height: 16,
                        thickness: 1,
                        color: AppColors.surfaceContainerLow,
                      ),
                      // Digital Odometer Display
                      OdometerDisplay(
                        reading: activeVehicle.currentOdometer,
                        label: 'Current Vehicle Odometer',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.person_pin,
                                    size: 14, color: AppColors.outline),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Driver: ${activeVehicle.assignedDriverName}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              ref
                                  .read(vehicleProvider.notifier)
                                  .selectVehicle(activeVehicle);
                              context.push('/vehicles/details');
                            },
                            child: const Text(
                              'Vehicle Details >',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 20),

            // 5. Dashboard KPI Cards (2x2 Grid)
            const Text(
              'Performance Overview',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: "Today's Distance",
                    value: journeyState.todayDistance.toStringAsFixed(0),
                    unit: 'KM',
                    subtitle: "${journeyState.todayJourneysCount} trips today",
                    icon: Icons.speed_rounded,
                    iconColor: AppColors.primary,
                    onTap: () => context.go('/journeys'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Monthly Distance',
                    value: NumberFormat('#,##0')
                        .format(journeyState.monthlyDistance),
                    unit: 'KM',
                    subtitle: 'August 2026',
                    icon: Icons.calendar_month_rounded,
                    iconColor: AppColors.primaryContainer,
                    onTap: () => context.go('/reports'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Pending Approvals',
                    value: '${journeyState.pendingApprovalsCount}',
                    subtitle: currentUser?.isApprover ?? false
                        ? 'Requires your review'
                        : 'Under verification',
                    icon: Icons.pending_actions_rounded,
                    iconColor: AppColors.warning,
                    iconBgColor: AppColors.warningContainer,
                    onTap: () {
                      ref.read(journeyProvider.notifier).setSearchQuery('');
                      ref.read(journeyProvider.notifier).setDateFilter(null);
                      ref.read(journeyProvider.notifier).setVehicleFilter(null);
                      ref
                          .read(journeyProvider.notifier)
                          .setStatusFilter(JourneyStatus.pendingApproval);
                      context.go('/journeys');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Active Vehicles',
                    value: '${vehicleState.vehicles.length}',
                    subtitle: vehicleState.serviceDueCount > 0
                        ? '${vehicleState.serviceDueCount} service due'
                        : 'Fleet fully operational',
                    icon: Icons.local_shipping_outlined,
                    iconColor: AppColors.success,
                    iconBgColor: AppColors.successContainer,
                    onTap: () => context.go('/vehicles'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 6. Section "Today's Journeys"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Today's Journeys",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/journeys'),
                  child: const Text('View All History >'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (todayJourneys.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.commute_rounded,
                        size: 36, color: AppColors.outline),
                    SizedBox(height: 8),
                    Text(
                      'No journeys recorded today',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap "+ Start New Journey" to record official travel.',
                      style: TextStyle(fontSize: 12, color: AppColors.outline),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todayJourneys.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final j = todayJourneys[index];
                  return _buildJourneyCard(context, j);
                },
              ),

            const SizedBox(height: 24),

            // 7. Quick Navigation to Special Modules
            if (currentUser?.isApprover ?? false) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Approving Officer Portal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            '${journeyState.pendingApprovalsCount} journeys waiting for verification & approval.',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => context.push('/approvals'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: const Size(60, 32),
                      ),
                      child: const Text('Review',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Fleet Intelligence Quick Card
            InkWell(
              onTap: () => context.push('/fleet-intelligence'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.analytics_outlined,
                        color: AppColors.primaryContainer, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fleet Intelligence & Anomaly Detection',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            'Odometer audit, GPS discrepancy alerts, service tracking.',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: AppColors.secondary, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyCard(BuildContext context, dynamic j) {
    return JourneyCard(journey: j);
  }

  void _showNotificationsModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final notifs = ref.watch(appStateProvider).notifications;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(appStateProvider.notifier)
                              .markAllNotificationsRead();
                        },
                        child: const Text('Mark all read'),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: notifs.isEmpty
                        ? const Center(
                            child: Text('No notifications'),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: notifs.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, i) {
                              final n = notifs[i];
                              return Material(
                                type: MaterialType.transparency,
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Color(n.category.colorValue)
                                          .withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.notifications,
                                      size: 18,
                                      color: Color(n.category.colorValue),
                                    ),
                                  ),
                                  title: Text(
                                    n.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: n.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    n.message,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Text(
                                    DateFormat('dd MMM, hh:mm a')
                                        .format(n.timestamp),
                                    style: const TextStyle(
                                        fontSize: 10, color: AppColors.outline),
                                  ),
                                  onTap: () {
                                    ref
                                        .read(appStateProvider.notifier)
                                        .markNotificationRead(n.id);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
