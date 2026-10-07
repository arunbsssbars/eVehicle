import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/winterization_health_service.dart';
import 'package:evehicle_logbook/core/widgets/winterization_health_card.dart';

void main() {
  group('Loop 37 - Sub-Zero Fleet Winterization & Antifreeze Service', () {
    const service = WinterizationHealthService();

    test('50% ethylene glycol mix protects against -20°C ambient with wide safety margin', () {
      final audit = service.evaluateWinterization(
        glycolConcentrationPercent: 50.0,
        forecastMinAmbientTempCelsius: -20.0,
      );

      expect(audit.isFreezeProtected, isTrue);
      expect(audit.freezeProtectionTempCelsius, equals(-37.0));
      expect(audit.safetyMarginCelsius, equals(17.0));
      expect(audit.isFuelAntiGelRequired, isTrue);
      expect(audit.readinessRating, equals('ARCTIC-READY'));
    });

    test('Diluted coolant (15% mix) against -12°C forecast triggers CRITICAL-FREEZE-RISK', () {
      final audit = service.evaluateWinterization(
        glycolConcentrationPercent: 15.0,
        forecastMinAmbientTempCelsius: -12.0,
      );

      expect(audit.isFreezeProtected, isFalse);
      expect(audit.freezeProtectionTempCelsius, greaterThan(-12.0));
      expect(audit.readinessRating, equals('CRITICAL-FREEZE-RISK'));
      expect(audit.advisory, contains('ENGINE BLOCK AT RISK'));
    });

    test('Moderate cold weather (-2°C) with standard mix needs no anti-gel', () {
      final audit = service.evaluateWinterization(
        glycolConcentrationPercent: 40.0,
        forecastMinAmbientTempCelsius: -2.0,
      );

      expect(audit.isFreezeProtected, isTrue);
      expect(audit.isFuelAntiGelRequired, isFalse);
      expect(audit.readinessRating, equals('SUFFICIENT'));
    });
  });

  group('Loop 37 - Winterization AQIL Responsive UI Tests', () {
    testWidgets('WinterizationHealthCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = WinterizationAudit(
        glycolConcentrationPercent: 50.0,
        freezeProtectionTempCelsius: -37.0,
        forecastMinAmbientTempCelsius: -18.0,
        safetyMarginCelsius: 19.0,
        isFreezeProtected: true,
        areGlowPlugsOperational: true,
        isFuelAntiGelRequired: true,
        isBlockHeaterRecommended: true,
        readinessRating: 'ARCTIC-READY',
        advisory: 'EXTREME COLD: Plug in block heater 2 hours before departure.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WinterizationHealthCard(
              audit: audit,
              onScheduleCoolantFlush: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Winterization & Antifreeze'), findsOneWidget);
      expect(find.text('PROTECTED'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('WinterizationHealthCard preserves layout stability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = WinterizationAudit(
        glycolConcentrationPercent: 12.0,
        freezeProtectionTempCelsius: -8.9,
        forecastMinAmbientTempCelsius: -15.0,
        safetyMarginCelsius: 0.0,
        isFreezeProtected: false,
        areGlowPlugsOperational: false,
        isFuelAntiGelRequired: true,
        isBlockHeaterRecommended: true,
        readinessRating: 'CRITICAL-FREEZE-RISK',
        advisory: 'ENGINE BLOCK AT RISK: Coolant freeze point above forecast low.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Scaffold(
              body: WinterizationHealthCard(
                audit: audit,
                onScheduleCoolantFlush: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FREEZE RISK'), findsOneWidget);
      expect(find.text('Book Emergency Coolant Antifreeze Flush'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
