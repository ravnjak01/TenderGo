import 'package:flutter/material.dart';

/// Generic base controller for paginated list screens.
/// Handles common pagination logic: page management, loading states, scroll detection.
/// 
/// Usage:
/// ```dart
/// class MyItemsListController extends BasePaginatedListController<ItemDto> {
///   final ItemService _service;
///   
///   MyItemsListController(this._service);
///   
///   @override
///   Future<List<ItemDto>> fetchPageData(int page) => _service.getItems(page: page);
/// }
/// ```
abstract class BasePaginatedListController<T>  with ChangeNotifier {
  /// Items fetched so far
  List<T> items = [];

  /// Current page number (starts at 1)
  int currentPage = 1;

  /// Page size for each fetch
  int pageSize = 10;

  /// Whether there are more pages to fetch
  bool hasMore = true;

  /// Loading state during fetch
  bool isLoading = false;

  /// Error occurred during fetch
  bool hasError = false;

  /// Error message from last failed fetch
  String errorMessage = '';

  /// Scroll controller for pagination trigger
  final ScrollController scrollController = ScrollController();

  /// Internal flag to prevent multiple concurrent fetches
  bool _isFetching = false;

  /// Distance from bottom (in pixels) to trigger loading next page
  static const double _scrollThreshold = 200.0;

  /// Initialize controller and setup scroll listener
  void initialize() {
    scrollController.addListener(_onScroll);
  }

  /// Fetch a page of data. Must be implemented by subclass.
  Future<List<T>> fetchPageData(int page, {int pageSize = 10});

  /// Called when data is successfully fetched (for subclass overrides if needed)
  void onDataFetched(List<T> newItems) {}

  /// Called when fetch fails (for subclass overrides if needed)
  void onFetchError(String error) {}

  /// Fetch initial data (resets pagination)
  Future<void> fetchInitial() => _performFetch(refresh: true);

  /// Load next page of data
  Future<void> loadMore() => _performFetch(refresh: false);

  /// Manual refresh (clears current data and fetches from page 1)
  Future<void> refresh() => _performFetch(refresh: true);

  /// Internal pagination fetch logic
  Future<void> _performFetch({bool refresh = false}) async {
    if (_isFetching || isLoading) return;

    if (refresh) {
      _resetPagination();
    } else if (!hasMore) {
      return; // No more pages available
    }

    _isFetching = true;
    isLoading = true;
    hasError = false;
    errorMessage = '';

    notifyListeners();

    try {
      final newItems = await fetchPageData(currentPage, pageSize: pageSize);

      // Check if we got fewer items than page size (last page indicator)
      hasMore = newItems.length == pageSize;

      if (refresh) {
        items = newItems;
      } else {
        items.addAll(newItems);
      }

      currentPage++;
      onDataFetched(newItems);
    } catch (e) {
      hasError = true;
      errorMessage = e.toString();
      onFetchError(errorMessage);
    } finally {
      isLoading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  /// Scroll listener: trigger load more when near bottom
  void _onScroll() {
    if (!scrollController.hasClients) return;

    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.offset;

    // If user scrolled near bottom and there are more pages, load next page
    if (maxScroll - currentScroll <= _scrollThreshold && hasMore && !isLoading) {
      loadMore();
    }
  }

  /// Reset pagination to initial state
  void _resetPagination() {
    items.clear();
    currentPage = 1;
    hasMore = true;
    hasError = false;
    errorMessage = '';
  }


  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();

    super.dispose();
  }
}
