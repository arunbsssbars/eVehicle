import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_and_notification.dart';
import '../storage/local_database.dart';
import 'auth_provider.dart';
import 'journey_provider.dart';

class AppState {
  final bool isOffline;
  final bool isSyncing;
  final int pendingSyncCount;
  final List<NotificationItem> notifications;
  final List<AuditLog> auditLogs;

  const AppState({
    this.isOffline = false,
    this.isSyncing = false,
    this.pendingSyncCount = 0,
    this.notifications = const [],
    this.auditLogs = const [],
  });

  int get unreadNotificationsCount =>
      notifications.where((n) => !n.isRead).length;

  AppState copyWith({
    bool? isOffline,
    bool? isSyncing,
    int? pendingSyncCount,
    List<NotificationItem>? notifications,
    List<AuditLog>? auditLogs,
  }) {
    return AppState(
      isOffline: isOffline ?? this.isOffline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      notifications: notifications ?? this.notifications,
      auditLogs: auditLogs ?? this.auditLogs,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  final Ref _ref;

  AppStateNotifier(this._ref) : super(const AppState()) {
    refresh();
  }

  void refresh() {
    state = state.copyWith(
      isOffline: LocalDatabase.instance.isOfflineMode,
      pendingSyncCount: LocalDatabase.instance.pendingSyncCount,
      notifications: LocalDatabase.instance.notifications,
      auditLogs: LocalDatabase.instance.auditLogs,
    );
  }

  void toggleOfflineMode() {
    final next = !state.isOffline;
    LocalDatabase.instance.isOfflineMode = next;
    state = state.copyWith(isOffline: next);
  }

  Future<void> triggerSync() async {
    if (state.isSyncing || state.isOffline) return;
    state = state.copyWith(isSyncing: true);
    await Future.delayed(const Duration(seconds: 1));
    await LocalDatabase.instance.syncPendingRecords();
    _ref.read(journeyProvider.notifier).refresh();
    state = state.copyWith(
      isSyncing: false,
      pendingSyncCount: LocalDatabase.instance.pendingSyncCount,
      notifications: LocalDatabase.instance.notifications,
    );
  }

  void markNotificationRead(String id) {
    LocalDatabase.instance.markNotificationAsRead(id);
    refresh();
  }

  void markAllNotificationsRead() {
    LocalDatabase.instance.markAllNotificationsAsRead();
    refresh();
  }
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  final notifier = AppStateNotifier(ref);
  ref.listen<AuthState>(authProvider, (previous, next) {
    notifier.refresh();
  });
  return notifier;
});
