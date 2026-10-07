import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/theme/accessible_theme_engine.dart';
import 'package:evehicle_logbook/core/widgets/theme_mode_selector_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Loop 7: Real-Time Dark Mode & Accessible Theme Engine Tests', () {
    test('calculateContrastRatio computes mathematically sound WCAG ratios', () {
      // Pure black and pure white have maximum 21.0:1 contrast
      final maxContrast = AccessibleThemeEngine.calculateContrastRatio(
        const Color(0xFF000000),
        const Color(0xFFFFFFFF),
      );
      expect(maxContrast, closeTo(21.0, 0.1));

      // Same color has 1.0:1 contrast
      final minContrast = AccessibleThemeEngine.calculateContrastRatio(
        const Color(0xFFFFFFFF),
        const Color(0xFFFFFFFF),
      );
      expect(minContrast, closeTo(1.0, 0.05));
    });

    test('High Contrast Dark theme satisfies WCAG AAA requirement (>= 7.0:1)', () {
      // White text on pure black background
      final ratio = AccessibleThemeEngine.calculateContrastRatio(
        const Color(0xFFFFFFFF),
        const Color(0xFF000000),
      );
      expect(AccessibleThemeEngine.satisfiesWcagAAA(const Color(0xFFFFFFFF), const Color(0xFF000000)), isTrue);
      expect(ratio, greaterThanOrEqualTo(7.0));
    });

    test('ThemeData builders create correct brightness and color schemes', () {
      final lightTheme = AccessibleThemeEngine.buildLightTheme();
      expect(lightTheme.brightness, equals(Brightness.light));

      final darkTheme = AccessibleThemeEngine.buildDarkTheme();
      expect(darkTheme.brightness, equals(Brightness.dark));

      final hcTheme = AccessibleThemeEngine.buildHighContrastDarkTheme();
      expect(hcTheme.brightness, equals(Brightness.dark));
      expect(hcTheme.scaffoldBackgroundColor, equals(const Color(0xFF000000)));
    });

    testWidgets('AQIL: ThemeModeSelectorCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: ThemeModeSelectorCard(
                currentMode: AccessibleThemeMode.light,
                onModeChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ThemeModeSelectorCard), findsOneWidget);
      expect(find.text('Display Theme & Contrast'), findsOneWidget);
    });

    testWidgets('AQIL: ThemeModeSelectorCard scales safely under 1.5x dynamic text scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ThemeModeSelectorCard(
                    currentMode: AccessibleThemeMode.highContrastDark,
                    onModeChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ThemeModeSelectorCard), findsOneWidget);
    });
  });
}
