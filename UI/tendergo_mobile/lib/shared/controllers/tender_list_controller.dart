import 'dart:async';
import 'package:flutter/material.dart';

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

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

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

  void clearSearch(VoidCallback onClear) {
    _debounce?.cancel();
    searchController.clear();
    onClear();
  }


  void dispose() {
    _pollingTimer?.cancel();
    _debounce?.cancel();
    searchController.dispose();
  }
}
