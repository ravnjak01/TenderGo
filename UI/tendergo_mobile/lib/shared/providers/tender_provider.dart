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
  List<TenderDto>? _searchResults;
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

  List<TenderDto> get filteredTenders {
    var list = List<TenderDto>.from(_searchResults ?? _tenders);

    if (!_selectedCategories.contains('All') &&
        _selectedCategories.isNotEmpty) {
      list = list
          .where((t) => _selectedCategories.contains(t.categoryName))
          .toList();
    }

    final filter = _locationFilter;
    if (filter != null) {
      if (filter.locationId != null) {
        list = list.where((t) => t.location.id == filter.locationId).toList();
      } else if (filter.region != null) {
        list = list
            .where(
              (t) =>
                  t.location.country.toLowerCase() ==
                      filter.country.toLowerCase() &&
                  (t.location.region ?? '').toLowerCase() ==
                      filter.region!.toLowerCase(),
            )
            .toList();
      } else {
        list = list
            .where(
              (t) =>
                  t.location.country.toLowerCase() ==
                  filter.country.toLowerCase(),
            )
            .toList();
      }
    }

    return list;
  }

  void setLocationFilter(LocationFilterSelection? filter) {
    _locationFilter = filter;
    safeNotify();
  }

  void clearLocationFilter() {
    if (_locationFilter == null) return;
    _locationFilter = null;
    safeNotify();
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
    safeNotify();
  }

  // --- 1. Inicijalno dohvatanje (Prva stranica) ---
  Future<void> fetchActiveTenders({bool silent = false}) async {
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    
    if (!await _tokenStore.hasValidAccessToken()) return;

    await handleAsync(
      () async {
        final activePaged = await _service.getActive(
          page: _currentPage,
          pageSize: _pageSize,
        );
        _tenders = activePaged.result;
        
        // Ako je vraćeno manje od _pageSize stavki, nema više stranica za učitavanje
        _hasMore = activePaged.result.length >= _pageSize;
      },
      silent: silent,
    );
  }

  // --- 2. Beskonačno skrolovanje (Sljedeća stranica) ---
  Future<void> fetchNextPage() async {
    // Ne učitavaj ako se već učitava nova stranica, ako nema više podataka ili ako je u toku primarno učitavanje
    if (_isLoadingMore || !_hasMore || isLoading) return;

    _isLoadingMore = true;
    safeNotify();

    try {
      final nextPage = _currentPage + 1;
      final activePaged = await _service.getActive(
        page: nextPage,
        pageSize: _pageSize,
      );

      if (activePaged.result.isNotEmpty) {
        _tenders.addAll(activePaged.result); // Dodajemo nove na postojeću listu
        _currentPage = nextPage;
      }

      // Ako je vraćeno manje elemenata od veličine stranice, došli smo do kraja
      _hasMore = activePaged.result.length >= _pageSize;
    } catch (e) {
      // Ovdje po potrebi zabilježite grešku
    } finally {
      _isLoadingMore = false;
      safeNotify();
    }
  }

  Future<void> fetchAllTenders() => handleAsync(() async {
        // 3. Dodato .result
        final allPaged = await _service.getAll();
        _tenders = allPaged.result;
      });

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

  Future<void> searchTenders(String query) async {
    _searchQuery = query.trim();
    if (_searchQuery.isEmpty) {
      _searchResults = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isDisposed) safeNotify();
      });
      return;
    }
    await handleAsync(() async {
      // 4. Dodato .result za search poziv
      final searchPaged = await _service.search(
        TenderSearchRequest(searchTerm: _searchQuery),
      );
      _searchResults = searchPaged.result;
    });
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
    _searchResults = null;
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      safeNotify();
    });
  }

  Future<bool> cancelTender(int id) async {
    final result = await handleAsync(() async {
      await _service.cancel(id);
      _tenders.removeWhere((t) => t.id == id);
      _searchResults?.removeWhere((t) => t.id == id);
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
      _categories = await _categoryService.getAll();
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
      final ratedUserName = tender.createdByFullname.trim();

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

  void setSelectedCategories(Set<String> categories) {
    _selectedCategories
      ..clear()
      ..addAll(categories);
    safeNotify();
  }

  void resetSessionState() {
    _tenders = [];
    _categories = [];
    _selectedCategories
      ..clear()
      ..add('All');
    _searchResults = null;
    _searchQuery = '';
    _locationFilter = null;
    _lastLoggedSearchQuery = null;
    _savedIds = {};
    _categoryLoadError = null;
    _isCategoryLoading = false;
    safeNotify();
  }
}