import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/emergency_broadcast_message.dart';
import 'package:evehicle_logbook/core/services/emergency_broadcast_service.dart';
import 'package:evehicle_logbook/core/widgets/emergency_broadcast_banner.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Loop 13: Push Notification & In-App Emergency Broadcast Tests', () {
    final now = DateTime.now();

    final criticalBroadcast = EmergencyBroadcastMessage(
      id: 'MSG-01',
      title: 'Flash Flood Warning - Sector 62',
      body: 'All vehicles in Noida sector 62 advised to halt operations immediately due to severe road flooding.',
      priority: BroadcastPriority.critical,
      issuedBy: 'Fleet Central Dispatch',
      issuedAt: now.subtract(const Duration(minutes: 10)),
      expiresAt: now.add(const Duration(hours: 4)),
      targetOffice: 'Noida Hub',
    );

    final expiredBroadcast = EmergencyBroadcastMessage(
      id: 'MSG-02',
      title: 'Scheduled Maintenance Advisory',
      body: 'Server update completed yesterday night.',
      priority: BroadcastPriority.info,
      issuedBy: 'IT Ops',
      issuedAt: now.subtract(const Duration(hours: 24)),
      expiresAt: now.subtract(const Duration(hours: 2)), // Expired
    );

    test('getActiveBroadcastsForDriver filters expired messages and matches office target', () {
      final activeForNoida = EmergencyBroadcastService.getActiveBroadcastsForDriver(
        broadcasts: [criticalBroadcast, expiredBroadcast],
        driverId: 'DRV-10',
        driverOffice: 'Noida Hub',
      );

      expect(activeForNoida.length, equals(1));
      expect(activeForNoida.first.id, equals('MSG-01'));

      final activeForGurgaon = EmergencyBroadcastService.getActiveBroadcastsForDriver(
        broadcasts: [criticalBroadcast, expiredBroadcast],
        driverId: 'DRV-20',
        driverOffice: 'Gurgaon Hub',
      );

      expect(activeForGurgaon.isEmpty, isTrue);
    });

    test('hasUnacknowledgedCriticalBroadcast flags unacknowledged urgent messages', () {
      expect(
        EmergencyBroadcastService.hasUnacknowledgedCriticalBroadcast(
          broadcasts: [criticalBroadcast],
          driverId: 'DRV-10',
        ),
        isTrue,
      );

      final acknowledged = EmergencyBroadcastService.acknowledge(
        broadcast: criticalBroadcast,
        driverId: 'DRV-10',
      );

      expect(
        EmergencyBroadcastService.hasUnacknowledgedCriticalBroadcast(
          broadcasts: [acknowledged],
          driverId: 'DRV-10',
        ),
        isFalse,
      );
    });

    testWidgets('AQIL: EmergencyBroadcastBanner renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: EmergencyBroadcastBanner(
                message: criticalBroadcast,
                isAcknowledged: false,
                onAcknowledge: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(EmergencyBroadcastBanner), findsOneWidget);
      expect(find.text('Flash Flood Warning - Sector 62'), findsOneWidget);
    });

    testWidgets('AQIL: EmergencyBroadcastBanner scales safely under 1.5x dynamic text scaling', (tester) async {
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
                  child: EmergencyBroadcastBanner(
                    message: criticalBroadcast,
                    isAcknowledged: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(EmergencyBroadcastBanner), findsOneWidget);
      expect(find.text('Acknowledged'), findsOneWidget);
    });
  });
}
