import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
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

  static const int pageSize = 10;
  static const double _scrollThreshold = 200;

  bool _isFetching = false;

  void initialize() {
    scrollController.addListener(_onScroll);
    fetchInitial();
  }

  Future<void> fetchInitial() => _fetchTenders(refresh: true);

  Future<void> refresh() => _fetchTenders(refresh: true);

  Future<void> loadMore() => _fetchTenders();

  Future<TenderDto> cancelTender(TenderDto tender) async {
    final updated = await _tenderService.cancel(tender.id);
    await refresh();
    return updated;
  }

  Future<void> _fetchTenders({bool refresh = false}) async {
    if (_isFetching || isLoading) return;
    if (!refresh && !hasMore) return;

    if (refresh) {
      currentPage = 1;
      items.clear();
      hasMore = true;
      hasError = false;
      errorMessage = '';
    }

    _isFetching = true;
    isLoading = true;
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

      final fetchedRaw = await _tenderService.getByUser(currentUserId);
      final fetchedDtos = fetchedRaw
          .whereType<Map<String, dynamic>>()
          .map(TenderDto.fromJson)
          .toList();

      items
        ..clear()
        ..addAll(fetchedDtos);
      hasMore = false;
      currentPage = 2;
    } catch (e) {
      hasError = true;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
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
