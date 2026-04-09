import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo_admin/models/dto/category_dto.dart';
import 'package:tendergo_admin/providers/tender_provider.dart';
import 'package:tendergo_admin/services/category_service.dart';
import 'package:tendergo_admin/services/dio_client.dart';
import 'package:tendergo_admin/services/tender_service.dart';
import 'package:tendergo_admin/widgets/category_chip_widget.dart';
import 'package:tendergo_admin/widgets/tender_widget.dart';
import 'package:tendergo_admin/screens/tender_post_screen.dart';
import 'package:tendergo_admin/screens/tender_details_screen.dart';

class TenderListScreen extends StatefulWidget {
  final TenderService tenderService;
  final bool embedded;
  final ValueChanged<int>? onTenderSelected;

  const TenderListScreen({
    super.key,
    required this.tenderService,
    this.embedded = false,
    this.onTenderSelected,
  });

  @override
  State<TenderListScreen> createState() => _TenderListScreenState();
}

class _TenderListScreenState extends State<TenderListScreen> {
  final Set<int> _savedIds = {};
  String _selectedCategory = 'All';
  final CategoryService _categoryService = CategoryService(DioClient.getDio());
  final List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TenderProvider>().fetchActiveTenders();
    });
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final List<CategoryDto> apiCategories = await _categoryService.getAll();
      if (!mounted) return;

      setState(() {
        _categories
          ..clear()
          ..add('All')
          ..addAll(apiCategories.map((c) => c.name));
      });
    } catch (_) {
      // Keep fallback category so the screen remains usable if fetch fails.
    }
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 300, 
          child: Column(
            children: [
              const Text(
                'Choose a location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              // Ovdje ubaci svoju formu (npr. ListView gradova ili Search)
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Container(
        color: const Color(0xFFF4F2EB),
        child: _buildBody(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EB),
      appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Row(
            children: [
              const Text(
                'TenderGo',
                style: TextStyle(
                  color: Color(0xFF185FA5),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 24),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.home_outlined,
                  size: 20,
                  color: Colors.black87,
                ),
                label: const Text(
                  'Home',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TenderPostScreen(
                            tenderService: widget.tenderService,
                          ),
                        ),
                      );
                      if (result == true && context.mounted) {
                        await context.read<TenderProvider>().fetchActiveTenders();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF185FA5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('+ Post a tender'),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5E3DC),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'JD',
                        style: TextStyle(
                          color: Color(0xFF185FA5),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: Container(height: 0.5, color: const Color(0xFFE5E3DC)),
          ),
        ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Consumer<TenderProvider>(
        builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(child: Text('Greška: ${provider.error}'));
            }

            final tenders = provider.tenders;
            final filteredTenders = _selectedCategory == 'All'
                ? tenders
                : tenders
                    .where((t) => t.categoryName == _selectedCategory)
                    .toList();

            if (filteredTenders.isEmpty) {
              return const Center(child: Text('No active tenders available.'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 4,
                      right: 4,
                      bottom: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: _categories.map((cat) {
                                    return CategoryChipWidget(
                                      label: cat,
                                      isSelected: _selectedCategory == cat,
                                      onTap: () {
                                        setState(() {
                                          _selectedCategory = cat;
                                          // Ovdje možeš pozvati provider da filtrira listu
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton.icon(
                              onPressed: () {
                                
                                _showLocationPicker(context);
                              },
                              icon: const Icon(
                                Icons.pin_drop_rounded,
                                size: 18,
                                color: Color(0xFF185FA5),
                              ),
                              label: const Text(
                                'Filter by location',
                                style: TextStyle(
                                  color: Color(0xFF185FA5),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(
                                    color: Color(0xFFE5E3DC),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${filteredTenders.length} active tenders',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5F5E5A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Izračun broja kolona
                      int crossAxisCount = 1;
                      if (constraints.maxWidth >= 900) {
                        crossAxisCount = 3;
                      } else if (constraints.maxWidth >= 600) {
                        crossAxisCount = 2;
                      }

                      final double spacing = 14.0;
                      final cardWidth =
                          (constraints.maxWidth -
                              (spacing * (crossAxisCount - 1))) /
                          crossAxisCount;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: filteredTenders.map((dto) {
                          final model = dto.toCardModel(dto);
                          return SizedBox(
                            width: cardWidth,
                            child: TenderCardWidget(
                              tender: model,
                              isSaved: _savedIds.contains(dto.id),
                              onTap: () {
                                if (widget.onTenderSelected != null) {
                                  widget.onTenderSelected!(dto.id);
                                  return;
                                }

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TenderDetailsScreen(
                                      tenderService: widget.tenderService,
                                      tenderId: dto.id,
                                    ),
                                  ),
                                );
                              },
                              onSave: () {
                                setState(() {
                                  if (_savedIds.contains(dto.id)) {
                                    _savedIds.remove(dto.id);
                                  } else {
                                    _savedIds.add(dto.id);
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
  }
}
