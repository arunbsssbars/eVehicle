class AuditLog {
  final String id;
  final String userId;
  final String userName;
  final String action; // CREATE, UPDATE, APPROVE, REJECT, LOCK, ODOMETER_OVERRIDE
  final String entity; // JOURNEY, VEHICLE, USER
  final String entityId;
  final String? field;
  final String? previousValue;
  final String? newValue;
  final String? reason;
  final DateTime timestamp;

  const AuditLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entity,
    required this.entityId,
    this.field,
    this.previousValue,
    this.newValue,
    this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'user_name': userName,
        'action': action,
        'entity': entity,
        'entity_id': entityId,
        'field': field,
        'previous_value': previousValue,
        'new_value': newValue,
        'reason': reason,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        userName: json['user_name'] as String? ?? 'Officer',
        action: json['action'] as String,
        entity: json['entity'] as String,
        entityId: json['entity_id'] as String,
        field: json['field'] as String?,
        previousValue: json['previous_value'] as String?,
        newValue: json['new_value'] as String?,
        reason: json['reason'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

enum NotificationCategory {
  journey('Journey', 0xFF004AC6),
  approval('Approval', 0xFFEA580C),
  vehicle('Vehicle', 0xFF16A34A),
  maintenance('Maintenance', 0xFF656D84),
  document('Document', 0xFFDC2626),
  system('System', 0xFF505F76);

  final String label;
  final int colorValue;
  const NotificationCategory(this.label, this.colorValue);
}

class NotificationItem {
  final String id;
  /// Null = broadcast to all users; non-null = scoped to this user only
  final String? userId;
  final NotificationCategory category;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? targetRoute;

  const NotificationItem({
    required this.id,
    this.userId,
    required this.category,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.targetRoute,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category': category.name,
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'is_read': isRead,
        'target_route': targetRoute,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'] as String,
        userId: json['user_id'] as String?,
        category: NotificationCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => NotificationCategory.system,
        ),
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
        isRead: json['is_read'] as bool? ?? false,
        targetRoute: json['target_route'] as String?,
      );

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      userId: userId,
      category: category,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      targetRoute: targetRoute,
    );
  }
}
