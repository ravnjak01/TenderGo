import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';

class TenderBidsController with ChangeNotifier {
  TenderBidsController({
    required int tenderId,
    required this.tender,
    required TenderService tenderService,
    required BidService bidService,
  })  : _tenderId = tenderId,
        _tenderService = tenderService,
        _bidService = bidService;

  static const int pageSize = 10;
  static const double _scrollThreshold = 200;

  final int _tenderId;
  final TenderService _tenderService;
  final BidService _bidService;
  TenderDto tender;

  final ScrollController scrollController = ScrollController();
  List<BidDto> bids = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasError = false;
  String errorMessage = '';
  bool hasMore = true;
  int currentPage = 1;
  bool _isFetching = false;

  void initialize() {
    scrollController.addListener(_onScroll);
    load();
  }

  Future<void> load() => _fetch(refresh: true);

  Future<void> refresh() => _fetch(refresh: true);

  Future<void> loadMore() => _fetch();

  Future<void> award(BidDto bid) async {
    tender = await _tenderService.award(tender, bid.id);
    await refresh();
  }

  Future<void> _fetch({bool refresh = false}) async {
    if (_isFetching || isLoading || (isLoadingMore && !refresh)) return;
    if (!refresh && !hasMore) return;

    if (refresh) {
      currentPage = 1;
      bids.clear();
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
      final pagedResult = await _bidService.getByTender(
        _tenderId,
        page: currentPage,
        pageSize: pageSize,
      );

      if (refresh) {
        bids.clear();
      }

      bids.addAll(pagedResult.result);

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
    if (remaining <= _scrollThreshold && hasMore && !isLoading && !isLoadingMore) {
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
