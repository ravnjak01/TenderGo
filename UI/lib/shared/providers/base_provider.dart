// lib/shared/providers/base_provider.dart

import 'package:flutter/foundation.dart';

/// Base class for all providers in TenderGo.
///
/// Centralises the three patterns that every provider repeats:
///   1. Loading flag + [_setLoading] helper
///   2. Error string + [clearError] helper
///   3. [handleAsync] – wraps any async call in try/catch/finally and
///      updates loading / error state automatically.
///   4. [safeNotify] – guards against calling [notifyListeners] after
///      [dispose] (needed by long-lived providers like NotificationProvider).
abstract class BaseProvider extends ChangeNotifier {
  // ── State ────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  // ── Getters ──────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// True after [dispose] has been called.
  /// Subclasses with timers / polling should check this before acting.
  bool get isDisposed => _disposed;

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Updates [_isLoading] and calls [safeNotify].
  void _setLoading(bool value) {
    _isLoading = value;
    safeNotify();
  }

  /// Clears the current error message and notifies listeners.
  void clearError() {
    if (_error == null) return;
    _error = null;
    safeNotify();
  }

  /// Calls [notifyListeners] only when the provider has not been disposed.
  ///
  /// Use this everywhere instead of calling [notifyListeners] directly so that
  /// providers with async operations (timers, polling, futures) never crash
  /// after the widget tree removes them.
  void safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ── handleAsync ──────────────────────────────────────────────────────────

  /// Executes [action] with automatic loading / error management.
  ///
  /// ```dart
  /// Future<void> fetchActiveTenders() =>
  ///     handleAsync(() async {
  ///       _tenders = await _service.getActive();
  ///     });
  /// ```
  ///
  /// Parameters:
  /// - [action]        – the async work to perform.
  /// - [silent]        – when `true`, the loading flag is NOT toggled
  ///                     (useful for background refreshes like polling).
  /// - [clearOnStart]  – when `true` (default), any existing [error] is
  ///                     cleared before [action] starts.
  /// - [onError]       – optional callback invoked with the raw exception
  ///                     string; called *before* [safeNotify].
  ///
  /// Returns the value produced by [action], or `null` on error.
  Future<T?> handleAsync<T>(
    Future<T> Function() action, {
    bool silent = false,
    bool clearOnStart = true,
    void Function(String error)? onError,
  }) async {
    if (!silent) {
      if (clearOnStart) _error = null;
      _setLoading(true);
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
        _isLoading = false;
      }
      safeNotify();
    }
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}