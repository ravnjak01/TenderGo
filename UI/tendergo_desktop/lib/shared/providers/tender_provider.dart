import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  static const _storage = FlutterSecureStorage();

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

  TenderService get tenderService => _service;

  Set<int> _savedIds = {};
Set<int> get savedIds => _savedIds;

Future<void> loadBookmarks(TenderService service) async {
  try {
    final bookmarkedTenders = await service.getBookmarked();
    _savedIds = bookmarkedTenders.map((t) => t.id).toSet();
    notifyListeners(); 
  } catch (e) {
    debugPrint('Greška pri učitavanju bookmarka u provideru: $e');
  }
}

void updateBookmarkLocal(int id, bool isBookmarked) {
  if (isBookmarked) {
    _savedIds.add(id);
  } else {
    _savedIds.remove(id);
  }
  notifyListeners();
}

  List<TenderDto> get filteredTenders {
    var list = List<TenderDto>.from(_searchResults ?? _tenders);

    if (!_selectedCategories.contains('All') && _selectedCategories.isNotEmpty) {
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
                  t.location.country.toLowerCase() == filter.country.toLowerCase() &&
                  (t.location.region ?? '').toLowerCase() ==
                      filter.region!.toLowerCase(),
            )
            .toList();
      } else {
        list = list
            .where(
              (t) => t.location.country.toLowerCase() == filter.country.toLowerCase(),
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

  Future<void> fetchActiveTenders({bool silent = false}) =>
      handleAsync(() async {
        _tenders = await _service.getActive();
      }, silent: silent);

  Future<void> fetchAllTenders() =>
      handleAsync(() async {
        _tenders = await _service.getAll();
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
      _searchResults = await _service.search(
        TenderSearchRequest(searchTerm: _searchQuery),
      );
    });
  }

  Future<void> logSearchActivity(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty || normalized == _lastLoggedSearchQuery) return;

    _lastLoggedSearchQuery = normalized;
    try {
      final token = await _storage.read(key: 'jwt_token') ?? '';
      await _recommendationService.logSearchActivity(
        query: normalized,
        authToken: token,
      );
    } catch (e) {
      debugPrint('Failed to log search activity: $e');
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
}
