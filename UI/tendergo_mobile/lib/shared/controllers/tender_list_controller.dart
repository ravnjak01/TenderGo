import 'dart:async';
import 'package:flutter/material.dart';

/// Manages the debounce timer, optional polling timer, and the search
/// [TextEditingController] for any tender-list screen.
///
/// The caller owns all mounted/context checks inside callbacks —
/// the controller never touches BuildContext itself.
class TenderListController {
  TenderListController({
    this.pollingInterval = const Duration(minutes: 5),
    this.debounceDuration = const Duration(milliseconds: 400),
  });

  final Duration pollingInterval;
  final Duration debounceDuration;

  final TextEditingController searchController = TextEditingController();

  Timer? _pollingTimer;
  Timer? _debounce;

  // ── Polling ────────────────────────────────────────────────────────────────

  /// Starts a repeating background poll every [pollingInterval].
  /// [onPoll] is responsible for its own mounted check.
  // void startPolling(VoidCallback onPoll) {
  //   _pollingTimer?.cancel();
  //   _pollingTimer = Timer.periodic(pollingInterval, (_) => onPoll());
  // }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  /// Debounces search input.
  /// Calls [onClear] when the trimmed query is empty, [onSearch] otherwise.
  /// Both callbacks are responsible for their own mounted checks.
  void onSearchChanged(
    String query, {
    required VoidCallback onClear,
    required void Function(String query) onSearch,
  }) {
    _debounce?.cancel();
    _debounce = Timer(debounceDuration, () {
      if (query.trim().isEmpty) {
        onClear();
      } else {
        onSearch(query.trim());
      }
    });
  }

  /// Clears the search field and triggers [onClear].
  void clearSearch(VoidCallback onClear) {
    _debounce?.cancel();
    searchController.clear();
    onClear();
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  void dispose() {
    _pollingTimer?.cancel();
    _debounce?.cancel();
    searchController.dispose();
  }
}
