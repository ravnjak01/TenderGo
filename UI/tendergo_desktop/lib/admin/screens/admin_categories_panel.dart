import 'package:flutter/material.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/widgets/common/app_dialogs.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/models/requests/category_insert_request.dart';

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

  @override
  void initState() {
    super.initState();
    _categoryService = CategoryService(DioClient.getDio());
    _fetchCategories();
  }

  Future<void> _fetchCategories({String searchTerm = ''}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final normalizedSearch = searchTerm.trim().toLowerCase();
      final statistics = await _categoryService.getCategoryStatistics();
      final filteredStatistics = statistics.where((stat) {
        if (normalizedSearch.isEmpty) return true;

        return stat.categoryName.toLowerCase().contains(normalizedSearch) ||
            stat.description.toLowerCase().contains(normalizedSearch);
      }).toList();
      final categories = filteredStatistics
          .map(
            (stat) => CategoryDto(
              id: stat.categoryId,
              name: stat.categoryName,
              description: stat.description,
              isActive: stat.isActive,
            ),
          )
          .toList();

      setState(() {
        _categories = categories;
        _statsByCategory = {
          for (final stat in statistics) stat.categoryId: stat,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshCategories() {
    return _fetchCategories(searchTerm: _searchController.text);
  }

  Future<void> _showEditCategoryDialog(CategoryDto category) async {
    final controller = TextEditingController(text: category.name);
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uredi kategoriju'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Naziv kategorije',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sačuvaj'),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;

    final newName = controller.text.trim();
    if (newName.isEmpty || newName == category.name) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _categoryService.update(
        category.id,
        CategoryDto(
          id: category.id,
          name: newName,
          description:
              _statsByCategory[category.id]?.description ?? category.description,
          isActive: category.isActive,
        ),
      );

      if (!success) {
        throw Exception('Nije moguće ažurirati kategoriju.');
      }

      await _refreshCategories();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dodaj novu kategoriju'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Naziv kategorije',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Opis kategorije',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sačuvaj'),
          ),
        ],
      ),
    );

    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    nameController.dispose();
    descriptionController.dispose();

    if (shouldSave != true) return;
    if (name.isEmpty || description.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _categoryService.insertCategory(
        CategoryInsertRequest(
          name: name,
          description: description,
        ),
      );
      await _refreshCategories();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
        _error = e.toString();
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
          _error = e.toString();
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
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Pomoćna metoda za dobijanje odgovarajuće ikone (ili emotikona) na osnovu naziva kategorije sa slike
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
    return Container(
      color: const Color(0xFFF8FAFC), // Svijetlo siva pozadina panela
      width: double.infinity,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Naslov i informacije o prijavljenom korisniku
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
                    _fetchCategories(searchTerm: value);
                  },
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddCategoryDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF2563EB,
                  ), // Plava boja sa slike
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

          // Glavna tabela sa podacima
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
                    child: SingleChildScrollView(
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
                              // Naziv kategorije sa ikonom
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
                              // Opis kategorije
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
                              // Broj potkategorija (Badge)

                              // Status kategorije
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

                              // Ukupno tendera (Plavi tekst/Badge)
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
                              // Akcije (Uredi / Obriši dugmad)
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
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          category.isActive
                                              ? 'Obri\u0161i'
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
        ],
      ),
    );
  }
}
