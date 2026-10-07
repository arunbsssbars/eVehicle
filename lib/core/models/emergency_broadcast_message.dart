/// Priority level of an emergency broadcast message
enum BroadcastPriority {
  info('Informational', 'INFO', 0xFF0284C7),
  warning('Advisory / Weather Alert', 'ALERT', 0xFFEA580C),
  critical('Emergency / Safety Grounding', 'URGENT', 0xFFDC2626);

  final String label;
  final String shortLabel;
  final int colorValue;
  const BroadcastPriority(this.label, this.shortLabel, this.colorValue);
}

/// In-app emergency broadcast broadcasted by dispatchers or administrators
class EmergencyBroadcastMessage {
  final String id;
  final String title;
  final String body;
  final BroadcastPriority priority;
  final String issuedBy;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String? targetOffice;
  final List<String> acknowledgedDriverIds;

  const EmergencyBroadcastMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.priority,
    required this.issuedBy,
    required this.issuedAt,
    required this.expiresAt,
    this.targetOffice,
    this.acknowledgedDriverIds = const [],
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool isAcknowledgedBy(String driverId) =>
      acknowledgedDriverIds.contains(driverId);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'priority': priority.name,
        'issued_by': issuedBy,
        'issued_at': issuedAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'target_office': targetOffice,
        'acknowledged_driver_ids': acknowledgedDriverIds,
      };

  factory EmergencyBroadcastMessage.fromJson(Map<String, dynamic> json) =>
      EmergencyBroadcastMessage(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        priority: BroadcastPriority.values.firstWhere(
          (p) => p.name == json['priority'],
          orElse: () => BroadcastPriority.info,
        ),
        issuedBy: json['issued_by'] as String,
        issuedAt: DateTime.parse(json['issued_at'] as String),
        expiresAt: DateTime.parse(json['expires_at'] as String),
        targetOffice: json['target_office'] as String?,
        acknowledgedDriverIds: (json['acknowledged_driver_ids'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}
