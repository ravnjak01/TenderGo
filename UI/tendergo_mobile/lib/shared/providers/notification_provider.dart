import 'dart:async';
import 'package:tendergo/shared/core/auth/auth_token_store.dart';
import 'package:tendergo/shared/models/dto/notification_dto.dart';
import 'package:tendergo/shared/providers/base_provider.dart';
import 'package:tendergo/shared/services/notification_service.dart';

enum NotificationLoadState { idle, loading, loaded, error }

class NotificationProvider extends BaseProvider {
  final NotificationService _service;
  static const AuthTokenStore _tokenStore = AuthTokenStore();

  NotificationProvider(this._service);

  NotificationLoadState _state = NotificationLoadState.idle;
  List<NotificationDto> _notifications = [];
  Timer? _pollingTimer;
  bool _isFetching = false;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  static const _pollingInterval = Duration(seconds: 30);
  static const int _pageSize = 10;

  NotificationLoadState get state => _state;
  List<NotificationDto> get notifications => _notifications;

  @override
  bool get isLoading => _state == NotificationLoadState.loading;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> startPolling() async {
    if (_pollingTimer?.isActive ?? false) return;
    if (!await _tokenStore.hasValidAccessToken()) return;

    _pollingTimer?.cancel();
    await loadNotifications();
    if (!await _tokenStore.hasValidAccessToken()) return;

    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      loadNotifications(silent: true);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void reset() {
    stopPolling();
    _state = NotificationLoadState.idle;
    _notifications = [];
    _isFetching = false;
    safeNotify();
  }

  Future<void> loadNotifications({bool silent = false, int page = 1}) async {
    if (_isFetching) return;
    if (!await _tokenStore.hasValidAccessToken()) return;

    _isFetching = true;

    if (!silent) {
      _state = NotificationLoadState.loading;
    } else if (page > 1) {
      _isLoadingMore = true;
    }

    try {
      await handleAsync(
        () async {
          final pagedResult = await _service.getMyNotifications(
            page: page,
            pageSize: _pageSize,
          );

          if (page == 1) {
            _notifications = pagedResult.result;
            _currentPage = 1;
          } else {
            _notifications.addAll(pagedResult.result);
          }

          _currentPage = page;
          _hasMore = pagedResult.hasNextPage;
          _state = NotificationLoadState.loaded;
        },
        silent: silent,
        onError: (_) => _state = NotificationLoadState.error,
      );
    } finally {
      _isFetching = false;
      _isLoadingMore = false;
      safeNotify();
    }
  }

  Future<void> loadNextPage() async {
    if (_isFetching || !_hasMore || _isLoadingMore) return;
    await loadNotifications(page: _currentPage + 1, silent: true);
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
