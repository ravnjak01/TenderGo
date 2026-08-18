import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/auth/auth_token_store.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/requests/tender_insert_request.dart';
import 'package:tendergo/shared/models/requests/tender_search_request.dart';
import 'package:tendergo/shared/models/ui/location_filter_selection.dart';
import 'package:tendergo/shared/providers/base_provider.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/recommendation_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';

class TenderProvider extends BaseProvider {
  final TenderService _service;
  final CategoryService _categoryService;
  final RecommendationService _recommendationService;
  static const AuthTokenStore _tokenStore = AuthTokenStore();

  TenderProvider(
    this._service,
    this._categoryService, {
    RecommendationService? recommendationService,
  }) : _recommendationService =
            recommendationService ?? RecommendationService(DioClient.getDio());

  List<TenderDto> _tenders = [];
  List<CategoryDto> _categories = [];
  final Set<String> _selectedCategories = {'All'};
  String _searchQuery = '';
  LocationFilterSelection? _locationFilter;
  String? _lastLoggedSearchQuery;

  List<TenderDto> get tenders => _tenders;
  List<CategoryDto> get categories => _categories;
  Set<String> get selectedCategories => _selectedCategories;
  bool get isSearchActive => _searchQuery.isNotEmpty;
  LocationFilterSelection? get locationFilter => _locationFilter;

  // --- Paginacijska polja ---
  int _currentPage = 1;
  final int _pageSize = 3;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  TenderService get tenderService => _service;

  Set<int> _savedIds = {};
  Set<int> get savedIds => _savedIds;

  // --- Kreiranje Request objekta sa backend filterima ---
TenderSearchRequest _buildSearchRequest({int page = 1}) {
  List<int>? categoryIds;

  // Ako 'All' nije selektovan i postoje izabrane kategorije
  if (!_selectedCategories.contains('All') && _selectedCategories.isNotEmpty) {
    categoryIds = _categories
        .where((c) => _selectedCategories.any(
            (selectedName) => selectedName.toLowerCase() == c.name.toLowerCase()))
        .map((c) => c.id)
        .toList();

    // Ako iz nekog razloga nijedna nije mapirana (prazna lista), postavi na null
    if (categoryIds.isEmpty) {
      categoryIds = null;
    }
  }

  return TenderSearchRequest(
    page: page,
    pageSize: _pageSize,
    searchTerm: _searchQuery.isNotEmpty ? _searchQuery : null,
    categoryIds: categoryIds,
    locationId: _locationFilter?.locationId,
    country: _locationFilter?.country,
    region: _locationFilter?.region,
  );
}

  Future<void> loadBookmarks(TenderService service) async {
    if (!await _tokenStore.hasValidAccessToken()) return;

    try {
      final bookmarkedPaged = await service.getBookmarked();
      _savedIds = bookmarkedPaged.result.map((t) => t.id).toSet();
      safeNotify();
    } catch (e) {
      // Handle error
    }
  }

  void updateBookmarkLocal(int id, bool isBookmarked) {
    if (isBookmarked) {
      _savedIds.add(id);
    } else {
      _savedIds.remove(id);
    }
    safeNotify();
  }

  // GETTER za kompatibilnost sa UI-em
  List<TenderDto> get filteredTenders => _tenders;

  void setLocationFilter(LocationFilterSelection? filter) {
    _locationFilter = filter;
    fetchActiveTenders();
  }

  void clearLocationFilter() {
    if (_locationFilter == null) return;
    _locationFilter = null;
    fetchActiveTenders();
  }

  void toggleCategory(String category) {
    if (category == 'All') {
      _selectedCategories
        ..clear()
        ..add('All');
    } else {
      _selectedCategories.remove('All');
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
      if (_selectedCategories.isEmpty) _selectedCategories.add('All');
    }
    fetchActiveTenders();
  }

  void setSelectedCategories(Set<String> categories) {
    _selectedCategories
      ..clear()
      ..addAll(categories);
    fetchActiveTenders();
  }

  // --- 1. Inicijalno dohvatanje / Prva stranica ---
  Future<void> fetchActiveTenders({bool silent = false}) async {
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;

    if (!await _tokenStore.hasValidAccessToken()) return;

    await handleAsync(
      () async {
        final request = _buildSearchRequest(page: _currentPage);
        final activePaged = await _service.get(request: request);

        _tenders = activePaged.result;
        _hasMore = activePaged.result.length >= _pageSize;
      },
      silent: silent,
    );
  }

  // --- 2. Beskonačno skrolovanje / Sljedeća stranica ---
  Future<void> fetchNextPage() async {
    if (_isLoadingMore || !_hasMore || isLoading) return;

    _isLoadingMore = true;
    safeNotify();

    try {
      final nextPage = _currentPage + 1;
      final request = _buildSearchRequest(page: nextPage);
      final activePaged = await _service.get(request:request);

      if (activePaged.result.isNotEmpty) {
        _tenders.addAll(activePaged.result);
        _currentPage = nextPage;
      }

      _hasMore = activePaged.result.length >= _pageSize;
    } catch (e) {
      // Handle error
    } finally {
      _isLoadingMore = false;
      safeNotify();
    }
  }

  Future<TenderDto?> createTender(
    TenderInsertRequest request, {
    List<PlatformFile>? imageFiles,
  }) =>
      handleAsync(() async {
        final created = await _service.create(request, imageFiles: imageFiles);
        _tenders.removeWhere((t) => t.id == created.id);
        _tenders.insert(0, created);
        return created;
      }, silent: true);

  // --- 3. Pretraga ---
  Future<void> searchTenders(String query) async {
    _searchQuery = query.trim();
    await fetchActiveTenders();
  }

  Future<void> logSearchActivity(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty || normalized == _lastLoggedSearchQuery) return;

    _lastLoggedSearchQuery = normalized;
    try {
      await _recommendationService.logSearchActivity(
        query: normalized,
      );
    } catch (e) {
      // Handle error
    }
  }

  void clearSearch() {
    _searchQuery = '';
    fetchActiveTenders();
  }

  Future<bool> cancelTender(int id) async {
    final result = await handleAsync(() async {
      await _service.cancel(id);
      _tenders.removeWhere((t) => t.id == id);
      return true;
    });
    return result ?? false;
  }

  bool _isCategoryLoading = false;
  String? _categoryLoadError;

  bool get isCategoryLoading => _isCategoryLoading;
  String? get categoryLoadError => _categoryLoadError;

  Future<void> fetchCategories() async {
    if (!await _tokenStore.hasValidAccessToken()) return;

    _isCategoryLoading = true;
    _categoryLoadError = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isDisposed) safeNotify();
    });
    try {
      _categories = await _categoryService.getAllForDropdown();
      final activeCategoryNames = _categories.map((c) => c.name).toSet();
      if (!_selectedCategories.contains('All')) {
        _selectedCategories.removeWhere(
          (category) => !activeCategoryNames.contains(category),
        );
        if (_selectedCategories.isEmpty) {
          _selectedCategories.add('All');
        }
      }
    } catch (e) {
      _categoryLoadError = e.toString().replaceFirst('Exception: ', '').trim();
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        safeNotify();
      });
    }
  }

  Future<Map<String, dynamic>?> prepareRatingArguments(BidDto bid) async {
    final bidderId = bid.submittedByUserId.trim();

    try {
      final tender = await _service.getById(bid.tenderId);

      final ratedUserId = tender.createdByUserId.trim();
      final ratedUserName = tender.createdByUserFullName.trim();

      if (ratedUserId.isEmpty || ratedUserId == bidderId) {
        return null;
      }

      return {
        'tenderId': bid.tenderId.toString(),
        'ratedUserId': ratedUserId,
        'ratedUserName': ratedUserName.isEmpty ? null : ratedUserName,
        'tenderTitle': bid.tenderTitle
      };
    } catch (_) {
      return null;
    }
  }

  void resetSessionState() {
    _tenders = [];
    _categories = [];
    _selectedCategories
      ..clear()
      ..add('All');
    _searchQuery = '';
    _locationFilter = null;
    _lastLoggedSearchQuery = null;
    _savedIds = {};
    _categoryLoadError = null;
    _isCategoryLoading = false;
    safeNotify();
  }
}