import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/dead_zone_buffer_service.dart';
import 'package:evehicle_logbook/core/widgets/dead_zone_buffer_card.dart';

void main() {
  group('Loop 38 - Dead-Zone Telemetry Buffer & Compression Service', () {
    const service = DeadZoneBufferService();

    test('Telemetry packet compression achieves ~72% data footprint reduction', () {
      final packet = service.compressPacket(
        id: 'pkt-001',
        rawBytes: 1024,
        priority: PacketPriority.routineTelemetry,
      );

      expect(packet.compressedBytes, equals(287));
      expect(packet.compressionRatio, closeTo(72.0, 0.5));
    });

    test('Offline buffer audit aggregates queued packets and flags critical SOS events', () {
      final queue = [
        service.compressPacket(id: 'p1', rawBytes: 2000, priority: PacketPriority.routineTelemetry),
        service.compressPacket(id: 'p2', rawBytes: 500, priority: PacketPriority.criticalSos),
        service.compressPacket(id: 'p3', rawBytes: 1500, priority: PacketPriority.highAudit),
      ];

      final audit = service.evaluateBufferQueue(
        queue: queue,
        isCellularConnected: false,
      );

      expect(audit.totalQueuedPackets, equals(3));
      expect(audit.totalRawBytes, equals(4000));
      expect(audit.criticalPacketCount, equals(1));
      expect(audit.isCellularOnline, isFalse);
      expect(audit.queueAdvisory, contains('OFFLINE DEAD-ZONE'));
    });

    test('Empty queue returns clean buffer status', () {
      final audit = service.evaluateBufferQueue(
        queue: [],
        isCellularConnected: true,
      );

      expect(audit.totalQueuedPackets, equals(0));
      expect(audit.queueAdvisory, contains('BUFFER EMPTY'));
    });
  });

  group('Loop 38 - Dead-Zone Buffer AQIL Responsive UI Tests', () {
    testWidgets('DeadZoneBufferCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = BufferQueueAudit(
        totalQueuedPackets: 24,
        totalRawBytes: 32000,
        totalCompressedBytes: 8960,
        averageCompressionRatioPercent: 72.0,
        isCellularOnline: false,
        isInternationalRoaming: false,
        criticalPacketCount: 2,
        queueAdvisory: 'OFFLINE DEAD-ZONE: 24 packets (8.8 KB) buffered locally.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadZoneBufferCard(
              audit: audit,
              onForceFlush: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dead-Zone Telemetry Buffer'), findsOneWidget);
      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DeadZoneBufferCard preserves layout stability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = BufferQueueAudit(
        totalQueuedPackets: 5,
        totalRawBytes: 6000,
        totalCompressedBytes: 1680,
        averageCompressionRatioPercent: 72.0,
        isCellularOnline: true,
        isInternationalRoaming: true,
        criticalPacketCount: 1,
        queueAdvisory: 'ROAMING SAFEGUARD: Non-critical telemetry held.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Scaffold(
              body: DeadZoneBufferCard(
                audit: audit,
                onForceFlush: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ROAMING'), findsOneWidget);
      expect(find.text('Force Cellular / Wi-Fi Buffer Flush'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
