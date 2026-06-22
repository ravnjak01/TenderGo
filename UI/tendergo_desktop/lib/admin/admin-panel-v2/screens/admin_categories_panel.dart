import 'package:flutter/material.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/widgets/common/app_dialogs.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/models/requests/category_search_request.dart';

class AdminCategoriesPanel extends StatefulWidget {
  const AdminCategoriesPanel({super.key});

  @override
  State<AdminCategoriesPanel> createState() => _AdminCategoriesPanelState();
}

class _AdminCategoriesPanelState extends State<AdminCategoriesPanel> {
  final TextEditingController _searchController = TextEditingController();
  late CategoryService _categoryService;

  List<CategoryDto> _categories = [];
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
      final request = CategorySearchRequest(
        searchTerm: searchTerm,
        page: 1,
        pageSize: 10,
      );

      final result = await _categoryService.search(request);

      setState(() {
        _categories = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
        CategoryDto(id: category.id, name: newName),
      );

      if (!success) {
        throw Exception('Nije moguće ažurirati kategoriju.');
      }

      await _fetchCategories(searchTerm: _searchController.text);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dodaj novu kategoriju'),
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

    final name = controller.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _categoryService.insert(CategoryDto(id: 0, name: name));
      await _fetchCategories(searchTerm: _searchController.text);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCategory(CategoryDto category) async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: 'Potvrdi brisanje',
      content:
          'Da li ste sigurni da želite obrisati kategoriju "${category.name}"?',
      cancelLabel: 'Otkaži',
      confirmLabel: 'Obriši',
      isDestructive: true,
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _categoryService.delete(category.id);
      await _fetchCategories(searchTerm: _searchController.text);
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



  int _getTenderCount(int index) {
    final counts = [18, 14, 6, 9, 4];
    return index < counts.length ? counts[index] : 0;
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
                                    //  category.description ??
                                    'Nema opisa',
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                              // Broj potkategorija (Badge)

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
                                    '${_getTenderCount(index)} aktivnih',
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
                                        onPressed: () =>
                                            _deleteCategory(category),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(65, 26),
                                          padding: EdgeInsets.zero,
                                          side: const BorderSide(
                                            color: Color(0xFFFECACA),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Obriši',
                                          style: TextStyle(
                                            color: Color(0xFFEF4444),
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
