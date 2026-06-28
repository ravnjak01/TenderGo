import 'package:flutter/foundation.dart';

abstract class BaseProvider extends ChangeNotifier {
  int _loadingCount = 0;
  String? _error;
  bool _disposed = false;

  bool get isLoading => _loadingCount > 0;
  String? get error => _error;
  bool get isDisposed => _disposed;

  void safeNotify() {
    if (!_disposed) notifyListeners();
  }

  void clearError() {
    if (_error == null) return;

    _error = null;
    safeNotify();
  }

  Future<T?> handleAsync<T>(
    Future<T> Function() action, {
    bool silent = false,
    bool clearOnStart = true,
    void Function(String error)? onError,
  }) async {
    if (!silent) {
      if (clearOnStart) _error = null;
      _loadingCount++;
      safeNotify();
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
      if (!silent && _loadingCount > 0) {
        _loadingCount--;
      }

      safeNotify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}