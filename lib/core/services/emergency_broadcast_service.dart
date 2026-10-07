import '../models/emergency_broadcast_message.dart';

/// Service managing dispatcher emergency broadcasts, target office routing, and driver acknowledgments
class EmergencyBroadcastService {
  /// Filter active, non-expired broadcast messages for a driver
  static List<EmergencyBroadcastMessage> getActiveBroadcastsForDriver({
    required List<EmergencyBroadcastMessage> broadcasts,
    required String driverId,
    String? driverOffice,
  }) {
    final now = DateTime.now();

    return broadcasts.where((b) {
      if (b.expiresAt.isBefore(now)) return false;

      // Check office targeting
      if (b.targetOffice != null && b.targetOffice!.isNotEmpty) {
        if (driverOffice != null && b.targetOffice != driverOffice) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Check if there are any unacknowledged critical broadcasts requiring urgent driver action
  static bool hasUnacknowledgedCriticalBroadcast({
    required List<EmergencyBroadcastMessage> broadcasts,
    required String driverId,
  }) {
    final now = DateTime.now();

    return broadcasts.any((b) =>
        b.priority == BroadcastPriority.critical &&
        b.expiresAt.isAfter(now) &&
        !b.isAcknowledgedBy(driverId));
  }

  /// Record driver acknowledgment of a broadcast message
  static EmergencyBroadcastMessage acknowledge({
    required EmergencyBroadcastMessage broadcast,
    required String driverId,
  }) {
    if (broadcast.isAcknowledgedBy(driverId)) return broadcast;

    final updated = List<String>.from(broadcast.acknowledgedDriverIds)..add(driverId);

    return EmergencyBroadcastMessage(
      id: broadcast.id,
      title: broadcast.title,
      body: broadcast.body,
      priority: broadcast.priority,
      issuedBy: broadcast.issuedBy,
      issuedAt: broadcast.issuedAt,
      expiresAt: broadcast.expiresAt,
      targetOffice: broadcast.targetOffice,
      acknowledgedDriverIds: updated,
    );
  }
}
