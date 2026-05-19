// lib/providers/tender_provider.dart  (refactored)

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/requests/tender_insert_request.dart';
import 'package:tendergo/shared/models/requests/tender_search_request.dart';
import 'package:tendergo/shared/models/ui/location_filter_selection.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';
import 'package:tendergo/shared/providers/base_provider.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';

class TenderProvider extends BaseProvider {
  final TenderService _service;
  final CategoryService _categoryService;

  TenderProvider(this._service, this._categoryService);

  List<TenderDto> _tenders = [];
  List<CategoryDto> _categories = [];
  final Set<String> _selectedCategories = {'All'};
  List<TenderDto>? _searchResults;
  String _searchQuery = '';
  LocationFilterSelection? _locationFilter;

  List<TenderDto> get tenders => _tenders;
  List<CategoryDto> get categories => _categories;
  Set<String> get selectedCategories => _selectedCategories;
  bool get isSearchActive => _searchQuery.isNotEmpty;
  LocationFilterSelection? get locationFilter => _locationFilter;

  TenderService get tenderService => _service;

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
      // Defer the notify to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
       // if (!_disposed) safeNotify();
      });
      return;
    }
    await handleAsync(() async {
      _searchResults = await _service.search(
        TenderSearchRequest(searchTerm: _searchQuery),
      );
    });
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = null;
    notifyListeners();
    // Defer the notify to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      safeNotify();
    });
  }

  Future<bool> deleteTender(int id) async {
    final result = await handleAsync(() async {
      await _service.delete(id);
      _tenders.removeWhere((t) => t.id == id);
    });
    return result != null; // null means an error was caught
  }

  Future<bool> cancelTender(int id) async {
    final result = await handleAsync(() async {
      await _service.cancel(id);
      _tenders.removeWhere((t) => t.id == id);
      _searchResults?.removeWhere((t) => t.id == id);
    });
    return result != null;
  }

  bool _isCategoryLoading = false;
  String? _categoryLoadError;

  bool get isCategoryLoading => _isCategoryLoading;
  String? get categoryLoadError => _categoryLoadError;

  Future<void> fetchCategories() async {
    _isCategoryLoading = true;
    _categoryLoadError = null;
    // Defer the notify to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
     // if (!_disposed) safeNotify();
    });
    try {
      _categories = await _categoryService.getAll();
    } catch (e) {
      _categoryLoadError = e.toString().replaceFirst('Exception: ', '').trim();
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
      safeNotify();
    });
    }
  }

// Unutar TenderProvider-a
Future<Map<String, dynamic>?> prepareRatingArguments(BidDto bid) async {
  final bidderId = bid.submittedByUserId.trim();

 try {
    // Pošto BidDto nema informacije o kreatoru tendera, povlačimo ih direktno iz izvornog tendera
    final tender = await _service.getById(bid.tenderId);
    
    final ratedUserId = tender.createdByUserId.trim();
    final ratedUserName = tender.createdByFullname.trim();

    // Validacija: Ne možeš ocijeniti sam sebe (kreator tendera ne ocjenjuje sebe)
    if (ratedUserId.isEmpty || ratedUserId == bidderId) {
      return null; 
    }

    return {
      'tenderId': bid.tenderId.toString(),
      'ratedUserId': ratedUserId,
      'ratedUserName': ratedUserName.isEmpty ? null : ratedUserName,
    };
    
  } catch (_) {
    return null; // Bezbjedan povratak ako mrežni poziv padne
  }
}

void setSelectedCategories(Set<String> categories) {
  _selectedCategories
    ..clear()
    ..addAll(categories);
  safeNotify();
}
}