import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

abstract class BaseProvider extends ChangeNotifier {
  int _loadingCount = 0;
  String? _error;
  bool _disposed = false;

  bool get isLoading => _loadingCount > 0;
  String? get error => _error;

  bool get isDisposed => _disposed;

  void _incrementLoading() {
    _loadingCount++;
    safeNotify();
  }

  void _decrementLoading() {
    if (_loadingCount > 0) _loadingCount--;
    _notifyDeferred();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    safeNotify();
  }

  void safeNotify() {
    if (!_disposed) notifyListeners();
  }

  void _notifyDeferred() {
    if (_disposed) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) notifyListeners();
    });
  }

  Future<T?> handleAsync<T>(
    Future<T> Function() action, {
    bool silent = false,
    bool clearOnStart = true,
    void Function(String error)? onError,
  }) async {
    if (!silent) {
      if (clearOnStart) _error = null;
      _incrementLoading();
    }

    try {
      final result = await action();
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      onError?.call(_error!);
      return null;
    } finally {
      if (!silent) {
        _decrementLoading();
      } else {
        _notifyDeferred();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
