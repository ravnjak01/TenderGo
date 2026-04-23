import 'package:flutter/material.dart';
import 'package:tendergo/mobile/widgets/tender_widget.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';


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

  bool _isLoading = false;
  String? _error;
  List<TenderDto> _tenders = const [];
  String _selectedCategory = 'All';

  List<String> get _categories {
    final unique = _tenders.map((t) => t.categoryName).toSet().toList()..sort();
    return ['All', ...unique];
  }

  List<TenderDto> get _filteredTenders {
    if (_selectedCategory == 'All') {
      return _tenders;
    }
    return _tenders.where((t) => t.categoryName == _selectedCategory).toList();
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
                      '${filtered.length} active tenders',
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
                child: ScreenEmptyState(
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

