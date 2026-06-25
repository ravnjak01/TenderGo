import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/location_service.dart';
import 'package:tendergo/mobile/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/mobile/widgets/tender/category_chip_widget.dart';
import 'package:tendergo/mobile/widgets/tender/location_picker_sheet.dart';

class TenderFilterBar extends StatelessWidget {
  final int tenderCount;

  /// When true, renders a dropdown instead of a horizontal chip row.
  /// Pass true from mobile screens; leave false (default) for desktop/tablet.
  final bool useDropdown;

  const TenderFilterBar({
    super.key,
    required this.tenderCount,
    this.useDropdown = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TenderProvider>();
    final locationFilter = provider.locationFilter;

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: useDropdown
                    ? _CategoryDropdown(provider: provider)
                    : _CategoryChips(provider: provider),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => _openLocationPicker(context, provider),
                icon: const Icon(
                  Icons.pin_drop_rounded,
                  size: 18,
                  color: Color(0xFF185FA5),
                ),
                label: Text(
                  locationFilter != null
                      ? 'Change location'
                      : 'Filter by location',
                  style: const TextStyle(
                    color: Color(0xFF185FA5),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFE5E3DC)),
                  ),
                ),
              ),
            ],
          ),
          if (locationFilter != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InputChip(
                  label: Text(locationFilter.displayLabel),
                  deleteIcon: const Icon(Icons.close_rounded, size: 18),
                  onDeleted: provider.clearLocationFilter,
                  backgroundColor: const Color(0xFFE6F1FB),
                  labelStyle: const TextStyle(
                    color: Color(0xFF185FA5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            '$tenderCount active tenders',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5F5E5A),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLocationPicker(
    BuildContext context,
    TenderProvider provider,
  ) async {
    try {
      final service = LocationService(DioClient.getDio());
      final selection = await LocationPickerSheet.show(
        context,
        locationService: service,
      );

      if (!context.mounted || selection == null) return;
      provider.setLocationFilter(selection);
    } catch (e) {
      if (!context.mounted) return;
      SnackbarHelper.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Chip row — unchanged, used on desktop/tablet
// ---------------------------------------------------------------------------

class _CategoryChips extends StatelessWidget {
  final TenderProvider provider;

  const _CategoryChips({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CategoryChipWidget(
            label: 'All',
            isSelected: provider.selectedCategories.contains('All'),
            onTap: () => provider.toggleCategory('All'),
          ),
          ...provider.categories
              .where((catDto) => catDto.name.toLowerCase() != 'all')
              .map((catDto) {
            final String categoryName = catDto.name;
            return CategoryChipWidget(
              label: categoryName,
              isSelected: provider.selectedCategories.contains(categoryName),
              onTap: () => provider.toggleCategory(categoryName),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Multi-select dropdown button — used on mobile only.
// Tapping opens a bottom sheet with checkboxes; selections apply immediately.
// ---------------------------------------------------------------------------

class _CategoryDropdown extends StatelessWidget {
  final TenderProvider provider;

  const _CategoryDropdown({required this.provider});

  // Returns a short label for the pill button.
  String _buttonLabel() {
    final selected = provider.selectedCategories;
    if (selected.isEmpty || selected.contains('All')) return 'All categories ';
    if (selected.length == 1) return selected.first;
    return '${selected.length} categories';
  }

  // Whether any specific (non-All) filter is active.
  bool get _isFiltered =>
      provider.selectedCategories.isNotEmpty &&
      !provider.selectedCategories.contains('All');

  void _openSheet(BuildContext context) {
    final List<String> items = [
      'All',
      ...provider.categories
          .where((c) => c.name.toLowerCase() != 'all')
          .map((c) => c.name),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryPickerSheet(
        items: items,
        provider: provider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isFiltered ? const Color(0xFFE6F1FB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isFiltered
                ? const Color(0xFF185FA5)
                : const Color(0xFFE5E3DC),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _buttonLabel(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF185FA5),
                  fontWeight:
                      _isFiltered ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF185FA5),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet content — stateful so checkbox state updates instantly.
// ---------------------------------------------------------------------------

class _CategoryPickerSheet extends StatefulWidget {
  final List<String> items;
  final TenderProvider provider;

  const _CategoryPickerSheet({
    required this.items,
    required this.provider,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  // Local copy so the sheet re-renders on each tap without rebuilding the tree.
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.of(widget.provider.selectedCategories);
  }

  void _toggle(String category) {
    setState(() {
      if (category == 'All') {
        _selected = {'All'};
      } else {
        _selected.remove('All');
        if (_selected.contains(category)) {
          _selected.remove(category);
          if (_selected.isEmpty) _selected = {'All'};
        } else {
          _selected.add(category);
        }
      }
    });
    // Apply to provider immediately so the list updates in the background.
    widget.provider.setSelectedCategories(Set.of(_selected));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E3DC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Text(
                      'Filter by category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const Spacer(),
                    if (!_selected.contains('All'))
                      TextButton(
                        onPressed: () {
                          setState(() => _selected = {'All'});
                          widget.provider.setSelectedCategories({'All'});
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Color(0xFF185FA5)),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Category list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final category = widget.items[index];
                    final isSelected = category == 'All'
                        ? _selected.contains('All')
                        : _selected.contains(category);

                    return InkWell(
                      onTap: () => _toggle(category),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggle(category),
                              activeColor: const Color(0xFF185FA5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? const Color(0xFF185FA5)
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Done button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF185FA5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}