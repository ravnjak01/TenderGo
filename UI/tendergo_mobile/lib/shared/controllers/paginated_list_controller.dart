import 'package:flutter/material.dart';

abstract class BasePaginatedListController<T>  with ChangeNotifier {
  List<T> items = [];

  int currentPage = 1;

  int pageSize = 10;

  bool hasMore = true;

  bool isLoading = false;

  bool hasError = false;

  String errorMessage = '';

  final ScrollController scrollController = ScrollController();

  bool _isFetching = false;

  static const double _scrollThreshold = 200.0;

  void initialize() {
    scrollController.addListener(_onScroll);
  }

  Future<List<T>> fetchPageData(int page, {int pageSize = 10});

  void onDataFetched(List<T> newItems) {}

  void onFetchError(String error) {}

  Future<void> fetchInitial() => _performFetch(refresh: true);

  Future<void> loadMore() => _performFetch(refresh: false);

  Future<void> refresh() => _performFetch(refresh: true);

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

  void _onScroll() {
    if (!scrollController.hasClients) return;

    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.offset;

    if (maxScroll - currentScroll <= _scrollThreshold && hasMore && !isLoading) {
      loadMore();
    }
  }

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
