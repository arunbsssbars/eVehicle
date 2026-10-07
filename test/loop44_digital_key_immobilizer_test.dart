import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/digital_key_service.dart';
import 'package:evehicle_logbook/core/widgets/digital_key_immobilizer_card.dart';

void main() {
  group('Loop 44 - Digital Key & Immobilizer Tests', () {
    const service = DigitalKeyService();
    const testVin = '1HGCR2F83HA001234';
    const testDriver = 'DRV-8821';

    test('issueEphemeralKey generates valid signed token that authorizes start', () {
      final token = service.issueEphemeralKey(
        driverId: testDriver,
        vehicleVin: testVin,
        validityMinutes: 15,
      );

      final audit = service.verifyTokenAndImmobilizer(
        token: token,
        targetVehicleVin: testVin,
      );

      expect(audit.state, ImmobilizerState.disarmedActive);
      expect(audit.ignitionAllowed, isTrue);
      expect(audit.requiresReauthorization, isFalse);
      expect(audit.remainingSecondsValid, greaterThan(0));
    });

    test('verifyToken rejects mismatched vehicle VIN', () {
      final token = service.issueEphemeralKey(
        driverId: testDriver,
        vehicleVin: testVin,
      );

      final audit = service.verifyTokenAndImmobilizer(
        token: token,
        targetVehicleVin: 'OTHER_VIN_99999999',
      );

      expect(audit.state, ImmobilizerState.armedStandby);
      expect(audit.ignitionAllowed, isFalse);
      expect(audit.requiresReauthorization, isTrue);
    });

    test('verifyToken rejects expired digital key token', () {
      final issuedAt = DateTime.now().subtract(const Duration(minutes: 30));
      final token = service.issueEphemeralKey(
        driverId: testDriver,
        vehicleVin: testVin,
        validityMinutes: 15,
        issuanceTime: issuedAt,
      );

      final audit = service.verifyTokenAndImmobilizer(
        token: token,
        targetVehicleVin: testVin,
      );

      expect(audit.state, ImmobilizerState.tokenExpired);
      expect(audit.ignitionAllowed, isFalse);
      expect(audit.requiresReauthorization, isTrue);
    });

    testWidgets('DigitalKeyImmobilizerCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = DigitalKeyAccessAudit(
        state: ImmobilizerState.disarmedActive,
        ignitionAllowed: true,
        remainingSecondsValid: 720,
        statusDescription: 'KEY VERIFIED: Digital immobilizer disarmed. Ignition start authorized.',
        requiresReauthorization: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DigitalKeyImmobilizerCard(
              audit: audit,
              tokenId: 'KEY-189A2BF3',
              onToggleImmobilizer: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Digital Key & Immobilizer'), findsOneWidget);
      expect(find.text('DISARMED'), findsOneWidget);
      expect(find.text('Arm Immobilizer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DigitalKeyImmobilizerCard scales cleanly under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = DigitalKeyAccessAudit(
        state: ImmobilizerState.tokenExpired,
        ignitionAllowed: false,
        remainingSecondsValid: 0,
        statusDescription: 'TOKEN EXPIRED: Ephemeral digital key window expired.',
        requiresReauthorization: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: DigitalKeyImmobilizerCard(
                audit: audit,
                tokenId: 'KEY-EXPIRED',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EXPIRED'), findsOneWidget);
      expect(find.text('Re-authenticate'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
