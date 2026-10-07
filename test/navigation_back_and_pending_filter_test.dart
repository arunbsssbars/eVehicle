import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/storage/local_database.dart';
import 'package:evehicle_logbook/core/models/journey.dart';
import 'package:evehicle_logbook/core/providers/journey_provider.dart';
import 'package:evehicle_logbook/features/dashboard/dashboard_screen.dart';
import 'package:evehicle_logbook/features/journeys/journey_history_screen.dart';
import 'package:evehicle_logbook/features/vehicles/vehicle_list_screen.dart';
import 'package:evehicle_logbook/features/reports/reports_hub_screen.dart';
import 'package:evehicle_logbook/features/profile/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalDatabase.instance.init();
  });

  group('Back button presence tests', () {
    testWidgets('DashboardScreen has NO leading back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('JourneyHistoryScreen has leading back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: JourneyHistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('VehicleListScreen has leading back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VehicleListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('ReportsHubScreen has leading back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ReportsHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('ProfileScreen has leading back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });

  group('Pending Approvals tap filter test', () {
    testWidgets('Tapping Pending Approvals sets status filter to pendingApproval', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/journeys',
            builder: (context, state) => const JourneyHistoryScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Pending Approvals card if needed
      final pendingTile = find.text('Pending Approvals');
      expect(pendingTile, findsOneWidget);
      await tester.ensureVisible(pendingTile);
      await tester.pumpAndSettle();

      await tester.tap(pendingTile);
      await tester.pumpAndSettle();

      // Verify journeyProvider state updated to pendingApproval
      final journeyState = container.read(journeyProvider);
      expect(journeyState.statusFilter, JourneyStatus.pendingApproval);

      // Verify navigated to Journeys screen
      expect(find.text('Journey Log Book'), findsOneWidget);
      // And back button is present
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('DashboardScreen renders Start Journey and Multi-Journey buttons and foldable vehicle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify both journey buttons exist
      expect(find.text('Start Journey'), findsOneWidget);
      expect(find.text('Multi-Journey'), findsOneWidget);

      // Verify vehicle card is present in an ExpansionTile
      expect(find.byKey(const PageStorageKey('dashboard_active_vehicle_tile')), findsOneWidget);
    });

    testWidgets('JourneyHistoryScreen renders + Add Journey button inside current date container', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: JourneyHistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify + Add Journey button is rendered
      expect(find.text('+ Add Journey'), findsOneWidget);
    });
  });
}
