import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/requests/tender_search_request.dart';
import 'package:tendergo/shared/models/ui/location_filter_selection.dart';
import 'package:tendergo/shared/providers/base_provider.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/tender_service.dart';

class TenderProvider extends BaseProvider {
  final TenderService _service;
  final CategoryService _categoryService;
  static const _storage = FlutterSecureStorage();

  TenderProvider(
    this._service,
    this._categoryService);

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


 

  void setLocationFilter(LocationFilterSelection? filter) {
    _locationFilter = filter;
    safeNotify();
  }

  void clearLocationFilter() {
    if (_locationFilter == null) return;
    _locationFilter = null;
    safeNotify();
  }


  Future<void> fetchAllTenders() => handleAsync(() async {
    _tenders = await _service.getAll();
  });

  



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

  

  void setSelectedCategories(Set<String> categories) {
    _selectedCategories
      ..clear()
      ..addAll(categories);
    safeNotify();
  }
}
