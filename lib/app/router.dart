import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/models/journey.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/otp_verification_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/change_password_screen.dart';
import '../features/dashboard/main_layout_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/journeys/start_journey_screen.dart';
import '../features/journeys/active_journey_screen.dart';
import '../features/journeys/end_journey_screen.dart';
import '../features/journeys/journey_success_screen.dart';
import '../features/journeys/journey_history_screen.dart';
import '../features/journeys/journey_details_screen.dart';
import '../features/journeys/calendar_view_screen.dart';
import '../features/journeys/batch_journey_create_screen.dart';
import '../features/vehicles/vehicle_list_screen.dart';
import '../features/vehicles/vehicle_details_screen.dart';
import '../features/approvals/pending_approvals_screen.dart';
import '../features/reports/reports_hub_screen.dart';
import '../features/reports/monthly_log_book_screen.dart';
import '../features/fleet/fleet_intelligence_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/admin/super_admin_screen.dart';
import '../features/admin/company_admin_screen.dart';
import '../features/admin/tenant_settings_screen.dart';
import '../features/subscription/subscription_plans_screen.dart';
import '../features/subscription/tenant_billing_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // Auth Routes
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) {
        final mobile = state.extra as String? ?? '+91 98765 43210';
        return OtpVerificationScreen(mobileNumber: mobile);
      },
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/change-password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),

    // Stateful Navigation Shell (Bottom Navigation Tabs)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainLayoutScreen(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Dashboard (Home)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        // Tab 1: Journeys
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/journeys',
              builder: (context, state) => const JourneyHistoryScreen(),
            ),
          ],
        ),
        // Tab 2: Vehicles
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/vehicles',
              builder: (context, state) => const VehicleListScreen(),
            ),
          ],
        ),
        // Tab 3: Reports
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsHubScreen(),
            ),
          ],
        ),
        // Tab 4: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // Journey Workflow Sub-screens
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/journeys/start',
      builder: (context, state) => const StartJourneyScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/journeys/active',
      builder: (context, state) => const ActiveJourneyScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/journeys/end',
      builder: (context, state) {
        final journey = state.extra as Journey?;
        return EndJourneyScreen(journey: journey);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/journeys/success',
      builder: (context, state) {
        final journey = state.extra as Journey?;
        return JourneySuccessScreen(journey: journey);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/journeys/details',
      builder: (context, state) {
        final id = state.extra as String? ?? 'JRN-2026-0824-01';
        return JourneyDetailsScreen(journeyId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/journeys/calendar',
      builder: (context, state) => const CalendarViewScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/journeys/batch-create',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final month = extra?['month'] as DateTime?;
        final vehicleId = extra?['vehicleId'] as String?;
        return BatchJourneyCreateScreen(
          initialMonth: month,
          initialVehicleId: vehicleId,
        );
      },
    ),

    // Vehicle Sub-screens
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/vehicles/details',
      builder: (context, state) => const VehicleDetailsScreen(),
    ),

    // Approvals Sub-screens
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/approvals',
      builder: (context, state) => const PendingApprovalsScreen(),
    ),

    // Reports & Analytics Sub-screens
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/reports/monthly-log-book',
      builder: (context, state) => const MonthlyLogBookScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/fleet-intelligence',
      builder: (context, state) => const FleetIntelligenceScreen(),
    ),

    // Profile & Settings Sub-screens
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/super-admin',
      builder: (context, state) => const SuperAdminScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/company-admin',
      builder: (context, state) => const CompanyAdminScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/plans',
      builder: (context, state) => const SubscriptionPlansScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tenant/billing',
      builder: (context, state) => const TenantBillingScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tenant/settings',
      builder: (context, state) => const TenantSettingsScreen(),
    ),
  ],
);
