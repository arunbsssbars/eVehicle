import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/storage/local_database.dart';
import 'package:evehicle_logbook/core/theme/app_theme.dart';

import 'package:evehicle_logbook/features/auth/splash_screen.dart';
import 'package:evehicle_logbook/features/auth/onboarding_screen.dart';
import 'package:evehicle_logbook/features/auth/login_screen.dart';
import 'package:evehicle_logbook/features/auth/signup_screen.dart';
import 'package:evehicle_logbook/features/auth/otp_verification_screen.dart';
import 'package:evehicle_logbook/features/auth/forgot_password_screen.dart';
import 'package:evehicle_logbook/features/auth/change_password_screen.dart';
import 'package:evehicle_logbook/features/dashboard/dashboard_screen.dart';
import 'package:evehicle_logbook/features/journeys/start_journey_screen.dart';
import 'package:evehicle_logbook/features/journeys/active_journey_screen.dart';
import 'package:evehicle_logbook/features/journeys/end_journey_screen.dart';
import 'package:evehicle_logbook/features/journeys/journey_success_screen.dart';
import 'package:evehicle_logbook/features/journeys/journey_history_screen.dart';
import 'package:evehicle_logbook/features/journeys/journey_details_screen.dart';
import 'package:evehicle_logbook/features/journeys/calendar_view_screen.dart';
import 'package:evehicle_logbook/features/journeys/batch_journey_create_screen.dart';
import 'package:evehicle_logbook/features/vehicles/vehicle_list_screen.dart';
import 'package:evehicle_logbook/features/vehicles/vehicle_details_screen.dart';
import 'package:evehicle_logbook/features/approvals/pending_approvals_screen.dart';
import 'package:evehicle_logbook/features/reports/reports_hub_screen.dart';
import 'package:evehicle_logbook/features/reports/monthly_log_book_screen.dart';
import 'package:evehicle_logbook/features/fleet/fleet_intelligence_screen.dart';
import 'package:evehicle_logbook/features/profile/profile_screen.dart';
import 'package:evehicle_logbook/features/profile/edit_profile_screen.dart';
import 'package:evehicle_logbook/features/settings/settings_screen.dart';
import 'package:evehicle_logbook/features/subscription/subscription_plans_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalDatabase.instance.init();
  });

  Future<void> testScreen(WidgetTester tester, Widget screen, String name) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: screen,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('All screens phone width layout overflow test', () {
    testWidgets('SplashScreen renders without overflow', (tester) async {
      await testScreen(tester, const SplashScreen(), 'SplashScreen');
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('OnboardingScreen renders without overflow', (tester) async {
      await testScreen(tester, const OnboardingScreen(), 'OnboardingScreen');
    });

    testWidgets('LoginScreen renders without overflow', (tester) async {
      await testScreen(tester, const LoginScreen(), 'LoginScreen');
    });

    testWidgets('SignupScreen renders without overflow', (tester) async {
      await testScreen(tester, const SignupScreen(), 'SignupScreen');
    });

    testWidgets('OtpVerificationScreen renders without overflow', (tester) async {
      await testScreen(tester, const OtpVerificationScreen(mobileNumber: '+91 98765 43210'), 'OtpVerificationScreen');
    });

    testWidgets('ForgotPasswordScreen renders without overflow', (tester) async {
      await testScreen(tester, const ForgotPasswordScreen(), 'ForgotPasswordScreen');
    });

    testWidgets('ChangePasswordScreen renders without overflow', (tester) async {
      await testScreen(tester, const ChangePasswordScreen(), 'ChangePasswordScreen');
    });

    testWidgets('DashboardScreen renders without overflow', (tester) async {
      await testScreen(tester, const DashboardScreen(), 'DashboardScreen');
    });

    testWidgets('StartJourneyScreen renders without overflow', (tester) async {
      await testScreen(tester, const StartJourneyScreen(), 'StartJourneyScreen');
    });

    testWidgets('ActiveJourneyScreen renders without overflow', (tester) async {
      await testScreen(tester, const ActiveJourneyScreen(), 'ActiveJourneyScreen');
    });

    testWidgets('EndJourneyScreen renders without overflow', (tester) async {
      await testScreen(tester, const EndJourneyScreen(), 'EndJourneyScreen');
    });

    testWidgets('JourneySuccessScreen renders without overflow', (tester) async {
      await testScreen(tester, const JourneySuccessScreen(), 'JourneySuccessScreen');
    });

    testWidgets('JourneyHistoryScreen renders without overflow', (tester) async {
      await testScreen(tester, const JourneyHistoryScreen(), 'JourneyHistoryScreen');
    });

    testWidgets('JourneyDetailsScreen renders without overflow', (tester) async {
      await testScreen(tester, const JourneyDetailsScreen(journeyId: 'JRN-2026-0824-01'), 'JourneyDetailsScreen');
    });

    testWidgets('CalendarViewScreen renders without overflow', (tester) async {
      await testScreen(tester, const CalendarViewScreen(), 'CalendarViewScreen');
    });

    testWidgets('BatchJourneyCreateScreen renders without overflow', (tester) async {
      await testScreen(tester, const BatchJourneyCreateScreen(), 'BatchJourneyCreateScreen');
    });

    testWidgets('VehicleListScreen renders without overflow', (tester) async {
      await testScreen(tester, const VehicleListScreen(), 'VehicleListScreen');
    });

    testWidgets('VehicleDetailsScreen renders without overflow', (tester) async {
      await testScreen(tester, const VehicleDetailsScreen(), 'VehicleDetailsScreen');
    });

    testWidgets('PendingApprovalsScreen renders without overflow', (tester) async {
      await testScreen(tester, const PendingApprovalsScreen(), 'PendingApprovalsScreen');
    });

    testWidgets('ReportsHubScreen renders without overflow', (tester) async {
      await testScreen(tester, const ReportsHubScreen(), 'ReportsHubScreen');
    });

    testWidgets('MonthlyLogBookScreen renders without overflow', (tester) async {
      await testScreen(tester, const MonthlyLogBookScreen(), 'MonthlyLogBookScreen');
    });

    testWidgets('FleetIntelligenceScreen renders without overflow', (tester) async {
      await testScreen(tester, const FleetIntelligenceScreen(), 'FleetIntelligenceScreen');
    });

    testWidgets('ProfileScreen renders without overflow', (tester) async {
      await testScreen(tester, const ProfileScreen(), 'ProfileScreen');
    });

    testWidgets('EditProfileScreen renders without overflow', (tester) async {
      await testScreen(tester, const EditProfileScreen(), 'EditProfileScreen');
    });

    testWidgets('SettingsScreen renders without overflow', (tester) async {
      await testScreen(tester, const SettingsScreen(), 'SettingsScreen');
    });

    testWidgets('SubscriptionPlansScreen renders without overflow', (tester) async {
      await testScreen(tester, const SubscriptionPlansScreen(), 'SubscriptionPlansScreen');
    });
  });
}
