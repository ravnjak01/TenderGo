import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/requests/tender_cancel_request.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';

class MyTendersController with ChangeNotifier {
  MyTendersController(this._tenderService);

  final TenderService _tenderService;

  final ScrollController scrollController = ScrollController();
  final List<TenderDto> items = [];

  bool isLoading = false;
  bool hasError = false;
  String errorMessage = '';
  bool hasMore = true;
  int currentPage = 1;
  bool isLoadingMore = false;

  static const int pageSize = 3;
  static const double _scrollThreshold = 200;

  bool _isFetching = false;

  void initialize() {
    scrollController.addListener(_onScroll);
    fetchInitial();
  }

  Future<void> fetchInitial() => _fetchTenders(refresh: true);

  Future<void> refresh() => _fetchTenders(refresh: true);

  Future<void> loadMore() => _fetchTenders();

  Future<TenderDto> cancelTender(int id, TenderCancelRequest request) async {
    final updated = await _tenderService.cancel(id, request);
   final index = items.indexWhere((item) => item.id == id);
  if (index != -1) {
    items[index] = updated;
    notifyListeners();
  }
    return updated;
  }

  Future<void> _fetchTenders({bool refresh = false}) async {
    if (_isFetching || isLoading || (isLoadingMore && !refresh)) return;
    if (!refresh && !hasMore) return;

    if (refresh) {
      currentPage = 1;
      items.clear();
      hasMore = true;
      hasError = false;
      errorMessage = '';
    }

    _isFetching = true;
    if (refresh) {
      isLoading = true;
    } else {
      isLoadingMore = true;
    }
    hasError = false;
    errorMessage = '';
    notifyListeners();

    try {
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null || currentUserId.isEmpty) {
        throw Exception(
          'Session expired. Please log in again to view your tenders.',
        );
      }

      final pagedResult = await _tenderService.getByUser(
        currentUserId,
        page: currentPage,
        pageSize: pageSize,
      );

      final fetchedDtos = pagedResult.result;

      if (refresh) {
        items.clear();
      }

      items.addAll(fetchedDtos);

      final serverPage = pagedResult.page > 0 ? pagedResult.page : currentPage;
      currentPage = serverPage;
      hasMore = pagedResult.hasNextPage;

      if (hasMore) {
        currentPage = serverPage + 1;
      }
    } catch (e) {
      hasError = true;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      isLoadingMore = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;

    final remaining =
        scrollController.position.maxScrollExtent - scrollController.offset;
    if (remaining <= _scrollThreshold && hasMore && !isLoading) {
      loadMore();
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }
}