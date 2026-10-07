import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/storage/local_database.dart';
import 'package:evehicle_logbook/features/subscription/subscription_plans_screen.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await LocalDatabase.instance.init();
  });

  group('Phase 3: Web & Desktop Responsive Layout Tests', () {
    testWidgets(
      'SubscriptionPlansScreen renders 3-column side-by-side on Desktop viewport without overflow',
      (tester) async {
        // Set to standard desktop display (1280 x 800)
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: SubscriptionPlansScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify headers & badges
        expect(find.text('Subscription & Pricing Plans'), findsOneWidget);
        expect(find.text('Scale from Individual to Fleet'), findsOneWidget);
        expect(find.text('Free Starter'), findsOneWidget);
        expect(find.text('Pro Individual'), findsOneWidget);
        expect(find.text('Enterprise Fleet'), findsOneWidget);

        // Verify that in desktop width (>= 900), the Row layout is active
        final rowFinder = find.byWidgetPredicate(
          (widget) => widget is Row && widget.children.length == 5, // 3 cards + 2 spacers
        );
        expect(rowFinder, findsOneWidget);

        // Zero exceptions / zero overflows
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'SubscriptionPlansScreen renders vertical stack on Mobile viewport without overflow',
      (tester) async {
        // Set to standard mobile display (375 x 812)
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: SubscriptionPlansScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Free Starter'), findsOneWidget);
        expect(find.text('Pro Individual'), findsOneWidget);
        expect(find.text('Enterprise Fleet'), findsOneWidget);

        // Desktop Row shouldn't be present
        final rowFinder = find.byWidgetPredicate(
          (widget) => widget is Row && widget.children.length == 5,
        );
        expect(rowFinder, findsNothing);

        // Zero exceptions
        expect(tester.takeException(), isNull);
      },
    );
  });
}
