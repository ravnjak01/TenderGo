import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/paged_result.dart';
import 'package:tendergo/shared/models/requests/category_search_request.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/widgets/common/app_dialogs.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/models/requests/category_insert_request.dart';
import 'package:tendergo/shared/models/requests/category_update_request.dart';
import 'package:tendergo/shared/core/utils/error_extension.dart';

class AdminCategoriesPanel extends StatefulWidget {
  const AdminCategoriesPanel({super.key});

  @override
  State<AdminCategoriesPanel> createState() => _AdminCategoriesPanelState();
}

class _AdminCategoriesPanelState extends State<AdminCategoriesPanel> {
  final TextEditingController _searchController = TextEditingController();
  late CategoryService _categoryService;

  List<CategoryDto> _categories = [];
  Map<int, CategoryStatisticsDto> _statsByCategory = {};
  bool _isLoading = true;
  String? _error;
int _currentPage = 1;
  int _pageSize = 5; 
  int _totalCount = 0;
  @override
  void initState() {
    super.initState();
    _categoryService = CategoryService(DioClient.getDio());
    _loadData();
  }

  Future<void> _loadData({String searchTerm = '', bool refreshAll = false, bool isNewSearch = false}) async {
    if (isNewSearch) {
      _currentPage = 1;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (refreshAll || _categories.isEmpty) {
        final results = await Future.wait([
          _categoryService.getCategoryStatistics(),
          _categoryService.getCategories(CategorySearchRequest(
            searchTerm: searchTerm.isEmpty ? null : searchTerm,
            page: _currentPage,
            pageSize: _pageSize,
          )),
        ]);

        final statistics = results[0] as List<CategoryStatisticsDto>;
        final pagedResult = results[1] as PagedResult<CategoryDto>;

        if (!mounted) return;

        setState(() {
          _statsByCategory = {
            for (final stat in statistics) stat.categoryId: stat,
          };
          _categories = pagedResult.result;
          _totalCount = pagedResult.totalCount;
          _currentPage = pagedResult.page;
          _pageSize = pagedResult.pageSize;
          _isLoading = false;
        });
      } else {
        await _fetchCategoriesOnly(searchTerm: searchTerm);
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toUserMessage();
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage), 
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _fetchCategoriesOnly({String searchTerm = ''}) async {
    final request = CategorySearchRequest(
      searchTerm: searchTerm.isEmpty ? null : searchTerm,
      page: _currentPage,
      pageSize: _pageSize,
    );

    final pagedResult = await _categoryService.getCategories(request);

    if (!mounted) return;

    setState(() {
      _categories = pagedResult.result;
      _totalCount = pagedResult.totalCount;
      _currentPage = pagedResult.page;
      _pageSize = pagedResult.pageSize;
      _isLoading = false;
    });
  }


Future<void> _refreshCategories() {
  return _loadData(searchTerm: _searchController.text, refreshAll: true);
}

  Future<void> _showEditCategoryDialog(CategoryDto category) async {
    final currentDescription =
        _statsByCategory[category.id]?.description ??
        category.description ??
        '';
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(
      text: currentDescription,
    );
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uredi kategoriju'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Naziv kategorije',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Naziv kategorije je obavezan.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Opis kategorije',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Opis kategorije je obavezan.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Sačuvaj'),
          ),
        ],
      ),
    );

    final newName = nameController.text.trim();
    final newDescription = descriptionController.text.trim();

    if (shouldSave != true) {
      return;
    }

    final request = CategoryUpdateRequest.fromChangedFields(
      originalName: category.name,
      originalDescription: currentDescription,
      newName: newName,
      newDescription: newDescription,
    );

    if (request.toJson().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _categoryService.update(category.id, request);

      await _refreshCategories();
    } catch (e) {
      setState(() {
        _error = e.toUserMessage();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dodaj novu kategoriju'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Naziv kategorije',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Naziv kategorije je obavezan.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Opis kategorije',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Opis kategorije je obavezan.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Sačuvaj'),
          ),
        ],
      ),
    );

    final name = nameController.text.trim();
    final description = descriptionController.text.trim();

    if (shouldSave != true) {
      nameController.dispose();
      descriptionController.dispose();
      return;
    }

    final request = CategoryInsertRequest(
      name: name,
      description: description,
    );
    final validationError = request.validate();

    if (validationError != null) {
      nameController.dispose();
      descriptionController.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _categoryService.insert(request);
      await _refreshCategories();
    } catch (e) {
      setState(() {
        _error = e.toUserMessage();
        _isLoading = false;
      });
    } finally {
      nameController.dispose();
      descriptionController.dispose();
    }
  }

  Future<void> _activateCategory(CategoryDto category) async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: 'Aktiviraj kategoriju',
      content:
          'Da li ste sigurni da \u017eelite aktivirati kategoriju "${category.name}"?',
      cancelLabel: 'Otka\u017ei',
      confirmLabel: 'Aktiviraj',
      isDestructive: false,
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _categoryService.activateCategory(category.id);
      await _refreshCategories();
    } catch (e) {
      setState(() {
        _error = e.toUserMessage();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCategory(CategoryDto category) async {
    if (_hasConnectedTenders(category)) {
      final shouldDeactivate = await AppDialogs.showConfirm(
        context: context,
        title: 'Kategorija ima povezane tendere',
        content:
            'Ova kategorija se ne mo\u017ee obrisati jer je povezana sa tenderima. '
            'Da li \u017eelite da je deaktivirate umjesto brisanja?',
        cancelLabel: 'Otka\u017ei',
        confirmLabel: 'Deaktiviraj',
        isDestructive: false,
      );

      if (!shouldDeactivate) return;

      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        await _categoryService.deactivateCategory(category.id);
        await _refreshCategories();
      } catch (e) {
        setState(() {
          _error = e.toUserMessage();
          _isLoading = false;
        });
      }
      return;
    }

    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: 'Potvrdi brisanje',
      content:
          'Da li ste sigurni da želite obrisati kategoriju "${category.name}"?',
      cancelLabel: 'Otkaži',
      confirmLabel: 'Obri\u0161i',
      isDestructive: true,
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _categoryService.delete(category.id);
      await _refreshCategories();
    } catch (e) {
      setState(() {
        _error = e.toUserMessage();
        _isLoading = false;
      });
    }
  }

  String _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('građevinarstvo') || lower.contains('gradevinarstvo'))
      return '🏗️';
    if (lower.contains('informacione') || lower.contains('it')) return '💻';
    if (lower.contains('transport') || lower.contains('logistika')) return '🚚';
    if (lower.contains('energetika')) return '⚡';
    if (lower.contains('medicinska') || lower.contains('zdravstvo'))
      return '🏥';
    return '📁';
  }

  CategoryStatisticsDto? _categoryStats(CategoryDto category) {
    return _statsByCategory[category.id];
  }

  String _categoryDescription(CategoryDto category) {
    final description =
        _categoryStats(category)?.description ?? category.description;

    if (description == null || description.trim().isEmpty) {
      return 'Nema opisa';
    }

    return description.trim();
  }

  int _categoryTenderCount(CategoryDto category) {
    return _categoryStats(category)?.tenderCount ?? 0;
  }

  bool _hasConnectedTenders(CategoryDto category) {
    return _categoryTenderCount(category) > 0;
  }

  @override
Widget build(BuildContext context) {
final effectivePageSize = _pageSize <= 0 ? 10 : _pageSize;
final int totalPages = _totalCount <= 0 
      ? 1 
      : (_totalCount / effectivePageSize).ceil();

  return Container(
    color: const Color(0xFFF8FAFC), 
    width: double.infinity,
    padding: const EdgeInsets.all(32.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upravljanje kategorijama',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            RichText(
              text: const TextSpan(
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                children: [
                  TextSpan(text: 'Prijavljen: '),
                  TextSpan(
                    text: 'Admin Korisnik',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Search bar i Akciono dugme
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 300,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Pretraži kategorije...',
                  hintStyle: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  _loadData(searchTerm: value, isNewSearch: true);
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddCategoryDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB), // Plava boja
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Dodaj novu kategoriju',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text('Greška pri učitavanju: $_error'))
              : Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: _categories.isEmpty
                      ? const Center(
                          child: Text(
                            'Nema pronađenih lokacija.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 15,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: DataTable(
                            horizontalMargin: 24,
                            headingRowHeight: 55,
                            dataRowMaxHeight: 75,
                            dataRowMinHeight: 65,
                            headingRowColor: MaterialStateProperty.all(
                              const Color(0xFFF8FAFC),
                            ),
                            columns: const [
                        DataColumn(
                          label: Text(
                            'Naziv kategorije',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Opis',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Status',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Ukupno\ntendera',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Akcije',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                            rows: List.generate(_categories.length, (index) {
                              final category = _categories[index];
                              final tenderCount = _categoryTenderCount(category);

                              return DataRow(
                                cells: [
                            DataCell(
                              Row(
                                children: [
                                  Text(
                                    _getCategoryIcon(category.name),
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      category.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 300,
                                child: Text(
                                  _categoryDescription(category),
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: category.isActive
                                      ? const Color(0xFFE6FFFA)
                                      : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  category.isActive ? 'Aktivna' : 'Neaktivna',
                                  style: TextStyle(
                                    color: category.isActive
                                        ? const Color(0xFF047857)
                                        : const Color(0xFFB91C1C),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$tenderCount aktivnih',
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () =>
                                          _showEditCategoryDialog(category),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(65, 26),
                                        padding: EdgeInsets.zero,
                                        side: const BorderSide(
                                          color: Color(0xFFCBD5E1),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      child: const Text(
                                        'Uredi',
                                        style: TextStyle(
                                          color: Color(0xFF475569),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    OutlinedButton(
                                      onPressed: () => category.isActive
                                          ? _deleteCategory(category)
                                          : _activateCategory(category),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(65, 26),
                                        padding: EdgeInsets.zero,
                                        side: BorderSide(
                                          color: category.isActive
                                              ? const Color(0xFFFECACA)
                                              : const Color(0xFFBBF7D0),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      child: Text(
                                        category.isActive
                                            ? 'Obriši'
                                            : 'Aktiviraj',
                                        style: TextStyle(
                                          color: category.isActive
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF16A34A),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
        ),
        
        if (!_isLoading && _error == null && _totalCount > 0) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prikazano ${((_currentPage - 1) * _pageSize) + 1} - ${(_currentPage * _pageSize) > _totalCount ? _totalCount : (_currentPage * _pageSize)} od $_totalCount stavki',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _fetchCategoriesOnly(searchTerm: _searchController.text);
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF475569)),
                  ),
                  const SizedBox(width: 8),
                  
                  Text(
                    'Stranica $_currentPage od $totalPages',
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  OutlinedButton(
                    onPressed: _currentPage < totalPages
                        ? () {
                            setState(() => _currentPage++);
                            _fetchCategoriesOnly(searchTerm: _searchController.text);
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF475569)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
}
