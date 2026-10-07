import 'dart:math';

/// Priority category of queued telematics data.
enum PacketPriority {
  criticalSos,     // Impact, geofence breach, tamper
  highAudit,       // Fuel receipts, DVIR, odometer sign-off
  routineTelemetry // Periodic 1Hz GPS waypoints
}

/// A buffered packet awaiting cellular uplink dispatch.
class BufferedPacket {
  final String id;
  final int rawBytes;
  final int compressedBytes;
  final PacketPriority priority;
  final DateTime timestamp;

  const BufferedPacket({
    required this.id,
    required this.rawBytes,
    required this.compressedBytes,
    required this.priority,
    required this.timestamp,
  });

  double get compressionRatio => ((rawBytes - compressedBytes) / (rawBytes > 0 ? rawBytes : 1)) * 100.0;
}

/// Consolidated audit of local telemetry buffer queue and cellular transmission bandwidth.
class BufferQueueAudit {
  final int totalQueuedPackets;
  final int totalRawBytes;
  final int totalCompressedBytes;
  final double averageCompressionRatioPercent;
  final bool isCellularOnline;
  final bool isInternationalRoaming;
  final int criticalPacketCount;
  final String queueAdvisory;

  const BufferQueueAudit({
    required this.totalQueuedPackets,
    required this.totalRawBytes,
    required this.totalCompressedBytes,
    required this.averageCompressionRatioPercent,
    required this.isCellularOnline,
    required this.isInternationalRoaming,
    required this.criticalPacketCount,
    required this.queueAdvisory,
  });
}

/// Enterprise Cellular Telematics Roaming & Offline Dead-Zone Data Compression Engine.
class DeadZoneBufferService {
  const DeadZoneBufferService();

  /// Simulates delta-compression on telematics payloads (typical dictionary delta yields ~70% compaction).
  BufferedPacket compressPacket({
    required String id,
    required int rawBytes,
    required PacketPriority priority,
    DateTime? timestamp,
  }) {
    // Delta-encoding on GPS telemetry compresses to ~28% of original JSON size
    final compressed = max(16, (rawBytes * 0.28).round());

    return BufferedPacket(
      id: id,
      rawBytes: rawBytes,
      compressedBytes: compressed,
      priority: priority,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Audits the local buffer queue state and transmission policies.
  BufferQueueAudit evaluateBufferQueue({
    required List<BufferedPacket> queue,
    required bool isCellularConnected,
    bool isRoamingActive = false,
  }) {
    if (queue.isEmpty) {
      return BufferQueueAudit(
        totalQueuedPackets: 0,
        totalRawBytes: 0,
        totalCompressedBytes: 0,
        averageCompressionRatioPercent: 0.0,
        isCellularOnline: isCellularConnected,
        isInternationalRoaming: isRoamingActive,
        criticalPacketCount: 0,
        queueAdvisory: 'BUFFER EMPTY: All telemetry dispatched to cloud.',
      );
    }

    int rawSum = 0;
    int compressedSum = 0;
    int criticalCount = 0;

    for (final p in queue) {
      rawSum += p.rawBytes;
      compressedSum += p.compressedBytes;
      if (p.priority == PacketPriority.criticalSos) criticalCount++;
    }

    final ratio = rawSum > 0 ? ((rawSum - compressedSum) / rawSum) * 100.0 : 0.0;

    String advisory;
    if (!isCellularConnected) {
      advisory = 'OFFLINE DEAD-ZONE: ${queue.length} packets (${(compressedSum / 1024).toStringAsFixed(1)} KB) buffered locally. Auto-sync on signal.';
    } else if (isRoamingActive) {
      advisory = 'ROAMING SAFEGUARD: Non-critical telemetry held. Only $criticalCount critical events will transmit over roaming data.';
    } else {
      advisory = 'READY TO FLUSH: High-speed uplink active. Uplink transmitting ${queue.length} delta-compressed packets.';
    }

    return BufferQueueAudit(
      totalQueuedPackets: queue.length,
      totalRawBytes: rawSum,
      totalCompressedBytes: compressedSum,
      averageCompressionRatioPercent: double.parse(ratio.toStringAsFixed(1)),
      isCellularOnline: isCellularConnected,
      isInternationalRoaming: isRoamingActive,
      criticalPacketCount: criticalCount,
      queueAdvisory: advisory,
    );
  }
}
