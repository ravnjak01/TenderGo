import 'dart:math' as Math;

import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/requests/category_search_request.dart';
import 'package:tendergo/shared/models/requests/tender_cancel_request.dart';
import 'package:tendergo/shared/models/requests/tender_search_request.dart';
import 'package:tendergo/shared/models/ui/location_filter_selection.dart';
import 'package:tendergo/shared/providers/base_provider.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';

class TenderProvider extends BaseProvider {
  final TenderService _tenderService;
  final CategoryService _categoryService;

  TenderProvider(this._tenderService, this._categoryService);

  List<TenderDto> _tenders = [];
  List<CategoryDto> _categories = [];
  
  int _currentPage = 1;
  int _totalCount = 0;
  bool _hasMore = true;

  int? _selectedCategoryId;
  String _searchQuery = '';
  LocationFilterSelection? _locationFilter;

  List<TenderDto> get tenders => _tenders;
  List<CategoryDto> get categories => _categories;
  bool get isSearchActive => _searchQuery.isNotEmpty;
  LocationFilterSelection? get locationFilter => _locationFilter;
  int? get selectedCategoryId => _selectedCategoryId;
  int get totalCount => _totalCount;
  bool get hasMore => _hasMore;

  TenderService get tenderService => _tenderService;

  Future<void> fetchTenders({bool refresh = true}) async {
    if (refresh) {
      _currentPage = 1;
      _tenders.clear();
    }

    await handleAsync(() async {
      final request = TenderSearchRequest(
        page: _currentPage,
        pageSize: 10,
        searchTerm: _searchQuery.isEmpty ? null : _searchQuery,
        categoryId: _selectedCategoryId,
        locationId: _locationFilter?.locationId,
        country: _locationFilter?.country,
        region: _locationFilter?.region,
      );

      final pagedResult = await _tenderService.getTendersPaged(request);

      if (refresh) {
        _tenders = pagedResult.result;
      } else {
        _tenders.addAll(pagedResult.result);
      }

      _totalCount = pagedResult.totalCount;
      _hasMore = _tenders.length < _totalCount;
    });
  }

  Future<void> loadNextPage() async {
    if (isLoading || !_hasMore) return;
    _currentPage++;
    await fetchTenders(refresh: false);
  }

  Future<void> fetchCategories() async {
    await handleAsync(() async {
      final pagedResult = await _categoryService.get(
        page: 1,
        pageSize: 100,
      );

      _categories = pagedResult.result;
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    fetchTenders(refresh: true);
  }

  void setSelectedCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    fetchTenders(refresh: true);
  }
  void setLocationFilter(LocationFilterSelection? filter) {
    _locationFilter = filter;
    fetchTenders(refresh: true);
  }

  void clearLocationFilter() {
    if (_locationFilter == null) return;
    _locationFilter = null;
    fetchTenders(refresh: true);
  }

  Future<bool> cancelTender(int id, String reason) async {
    final result = await handleAsync(() async {
      final request = TenderCancelRequest(reason: reason);
      await _tenderService.cancel(id, request);

      _tenders.removeWhere((t) => t.id == id);
      _totalCount = Math.max(0, _totalCount - 1);
      return true;
    });

    return result ?? false;
  }

  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    fetchTenders(refresh: true);
  }
}