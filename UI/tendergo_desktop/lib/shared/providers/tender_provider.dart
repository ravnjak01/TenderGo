import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/requests/tender_cancel_request.dart';
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
  final Set<String> _selectedCategories = {'All'};

  String _searchQuery = '';
  LocationFilterSelection? _locationFilter;

  List<TenderDto> get tenders => _tenders;
  List<CategoryDto> get categories => _categories;
  Set<String> get selectedCategories => _selectedCategories;
  bool get isSearchActive => _searchQuery.isNotEmpty;
  LocationFilterSelection? get locationFilter => _locationFilter;

  TenderService get tenderService => _tenderService;

  void setLocationFilter(LocationFilterSelection? filter) {
    _locationFilter = filter;
    safeNotify();
  }

  void clearLocationFilter() {
    if (_locationFilter == null) return;

    _locationFilter = null;
    safeNotify();
  }

  Future<void> fetchAllTenders() async {
    await handleAsync(() async {
      _tenders = await _tenderService.getAll();
    });
  }

  Future<void> fetchCategories() async {
    await handleAsync(() async {
      _categories = await _categoryService.getAll();

      final activeCategoryNames = _categories.map((c) => c.name).toSet();

      _selectedCategories.removeWhere(
        (category) => category != 'All' && !activeCategoryNames.contains(category),
      );

      if (_selectedCategories.isEmpty) {
        _selectedCategories.add('All');
      }
    });
  }

  Future<bool> cancelTender(int id,String reason) async {
    final result = await handleAsync(() async {
      final request = TenderCancelRequest(reason: reason);
      await _tenderService.cancel(id,request);

      _tenders.removeWhere((t) => t.id == id);

      return true;
    });

    return result ?? false;
  }

  void setSelectedCategories(Set<String> categories) {
    _selectedCategories
      ..clear()
      ..addAll(categories);

    safeNotify();
  }

  void clearSearch() {
    _searchQuery = '';
    safeNotify();
  }
}