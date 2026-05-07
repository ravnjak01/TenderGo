import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tendergo/shared/models/dto/notification_dto.dart';
import 'package:tendergo/shared/services/notification_service.dart';

enum NotificationLoadState { idle, loading, loaded, error }

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;

  NotificationProvider(this._service);

  // ── State ────────────────────────────────────────────────────────────────

  NotificationLoadState _state = NotificationLoadState.idle;
  List<NotificationDto> _notifications = [];
  String? _error;
  Timer? _pollingTimer;

  static const _pollingInterval = Duration(seconds: 30);

  NotificationLoadState get state => _state;
  List<NotificationDto> get notifications => _notifications;
  String? get error => _error;
  bool get isLoading => _state == NotificationLoadState.loading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // ── Polling ──────────────────────────────────────────────────────────────

  /// Call from the shell screen's initState.
  void startPolling() {
    _pollingTimer?.cancel();
    loadNotifications();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      loadNotifications(silent: true);
    });
  }

  /// Call from the shell screen's dispose.
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Fetches all notifications. When [silent] is true the loading indicator
  /// is not shown (used for background polls).
  Future<void> loadNotifications({bool silent = false}) async {
    if (!silent) {
      _state = NotificationLoadState.loading;
      _error = null;
      notifyListeners();
    }

    try {
      _notifications = await _service.getMyNotifications();
      _state = NotificationLoadState.loaded;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _state = NotificationLoadState.error;
    }

    notifyListeners();
  }

  /// Marks one notification as read both optimistically and on the server.
  Future<void> markAsRead(int id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1 || _notifications[idx].isRead) return;

    // Optimistic update
    _notifications = List.of(_notifications)
      ..[idx] = _notifications[idx].copyWith(isRead: true);
    notifyListeners();

    try {
      await _service.markAsRead(id);
    } catch (_) {
      // Revert on failure
      _notifications = List.of(_notifications)
        ..[idx] = _notifications[idx].copyWith(isRead: false);
      notifyListeners();
    }
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    final previous = List<NotificationDto>.from(_notifications);

    // Optimistic update
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    try {
      await _service.markAllAsRead();
    } catch (_) {
      _notifications = previous;
      notifyListeners();
    }
  }

  /// Deletes a notification.
  Future<void> deleteNotification(int id) async {
    final previous = List<NotificationDto>.from(_notifications);

    // Optimistic removal
    _notifications = _notifications.where((n) => n.id != id).toList();
    notifyListeners();

    try {
      await _service.delete(id);
    } catch (_) {
      _notifications = previous;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
