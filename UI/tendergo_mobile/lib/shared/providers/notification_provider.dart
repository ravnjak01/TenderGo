import 'dart:async';
import 'package:tendergo/shared/models/dto/notification_dto.dart';
import 'package:tendergo/shared/providers/base_provider.dart';
import 'package:tendergo/shared/services/notification_service.dart';

enum NotificationLoadState { idle, loading, loaded, error }

class NotificationProvider extends BaseProvider {
  final NotificationService _service;

  NotificationProvider(this._service);

  NotificationLoadState _state = NotificationLoadState.idle;
  List<NotificationDto> _notifications = [];
  Timer? _pollingTimer;
  bool _isFetching = false;

  static const _pollingInterval = Duration(seconds: 30);

  NotificationLoadState get state => _state;
  List<NotificationDto> get notifications => _notifications;

  @override
  bool get isLoading => _state == NotificationLoadState.loading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void startPolling() {
    if (_pollingTimer?.isActive ?? false) return;
    _pollingTimer?.cancel();
    loadNotifications();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      loadNotifications(silent: true);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> loadNotifications({bool silent = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (!silent) _state = NotificationLoadState.loading;

    await handleAsync(
      () async {
        _notifications = await _service.getMyNotifications();
        _state = NotificationLoadState.loaded;
      },
      silent: silent,
      onError: (_) => _state = NotificationLoadState.error,
    );

    _isFetching = false;
  }

  Future<void> markAsRead(int id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1 || _notifications[idx].isRead) return;

    _notifications = List.of(_notifications)
      ..[idx] = _notifications[idx].copyWith(isRead: true);
    safeNotify();

    try {
      await _service.markAsRead(id);
    } catch (_) {
      _notifications = List.of(_notifications)
        ..[idx] = _notifications[idx].copyWith(isRead: false);
      safeNotify();
    }
  }

  Future<void> markAllAsRead() async {
    final previous = List<NotificationDto>.from(_notifications);
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    safeNotify();

    try {
      await _service.markAllAsRead();
    } catch (_) {
      _notifications = previous;
      safeNotify();
    }
  }

  Future<void> deleteNotification(int id) async {
    final previous = List<NotificationDto>.from(_notifications);
    _notifications = _notifications.where((n) => n.id != id).toList();
    safeNotify();

    try {
      await _service.delete(id);
    } catch (_) {
      _notifications = previous;
      safeNotify();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
