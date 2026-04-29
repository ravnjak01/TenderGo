import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tendergo/mobile/widgets/tender_widget.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/shared/widgets/tender/search_bar_widget.dart';


class MobileTenderListScreen extends StatefulWidget {
  final TenderService tenderService;
  final bool embedded;
  final ValueChanged<int>? onTenderSelected;

  const MobileTenderListScreen({
    super.key,
    required this.tenderService,
    this.embedded = false,
    this.onTenderSelected,
  });

  @override
  State<MobileTenderListScreen> createState() => _MobileTenderListScreenState();
}

class _MobileTenderListScreenState extends State<MobileTenderListScreen> {
  final Set<int> _savedIds = <int>{};
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  List<TenderDto> _tenders = const [];
  List<TenderDto>? _searchResults;
  String _selectedCategory = 'All';

  List<TenderDto> get _base => _searchResults ?? _tenders;

  List<String> get _categories {
    final unique = _base.map((t) => t.categoryName).toSet().toList()..sort();
    return ['All', ...unique];
  }

  List<TenderDto> get _filteredTenders {
    if (_selectedCategory == 'All') return _base;
    return _base.where((t) => t.categoryName == _selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadTenders();
  }

  Future<void> _loadTenders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tenders = await widget.tenderService.getActive();
      if (!mounted) return;
      setState(() {
        _tenders = tenders;
        _searchResults = null;
        _searchController.clear();
        _selectedCategory = 'All';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      if (query.trim().isEmpty) {
        setState(() {
          _searchResults = null;
          _selectedCategory = 'All';
        });
        return;
      }
      setState(() => _isSearching = true);
      try {
        final results = await widget.tenderService.search(
          TenderSearchRequest(searchTerm: query.trim()),
        );
        if (!mounted) return;
        setState(() {
          _searchResults = results;
          _selectedCategory = 'All';
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _searchResults = []);
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSaved(int id) {
    setState(() {
      if (_savedIds.contains(id)) {
        _savedIds.remove(id);
      } else {
        _savedIds.add(id);
      }
    });
  }

  void _openTender(TenderDto tender) {
    if (widget.onTenderSelected != null) {
      widget.onTenderSelected!(tender.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ScreenLoadingState(message: 'Loading tenders...');
    }

    if (_error != null) {
      return ScreenErrorState(message: _error!, onRetry: _loadTenders);
    }

    if (_tenders.isEmpty) {
      return ScreenEmptyState(
        icon: Icons.inbox_rounded,
        title: 'No active tenders',
        description: 'There are no tenders available right now.',
        onAction: _loadTenders,
      );
    }

    final filtered = _filteredTenders;

    return Container(
      color: const Color(0xFFF4F2EB),
      child: RefreshIndicator(
        onRefresh: _loadTenders,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TenderSearchBar(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onClear: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      isLoading: _isSearching,
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
                          final isSelected = category == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${filtered.length} ${_searchController.text.isNotEmpty ? 'results' : 'active tenders'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5F5E5A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _searchController.text.isNotEmpty
                    ? ScreenEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No results found',
                        description: 'Try different keywords.',
                        actionLabel: 'Clear search',
                        onAction: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : ScreenEmptyState(
                        icon: Icons.filter_alt_off_rounded,
                        title: 'No matches found',
                        description: 'Try a different category filter.',
                        actionLabel: 'Clear filter',
                        onAction: () {
                          setState(() {
                            _selectedCategory = 'All';
                          });
                        },
                      ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                sliver: SliverList.separated(
                  itemBuilder: (context, index) {
                    final dto = filtered[index];
                    final model = dto.toCardModel(dto);

                    return MobileTenderCardWidget(
                      tender: model,
                      isSaved: _savedIds.contains(dto.id),
                      onTap: () => _openTender(dto),
                      onSave: () => _toggleSaved(dto.id),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: filtered.length,
                ),
              ),
          ],
        ),
      ),
    );
  }

}

