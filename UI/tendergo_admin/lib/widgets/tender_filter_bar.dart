import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo_admin/providers/tender_provider.dart';
import 'package:tendergo_admin/widgets/category_chip_widget.dart';
import 'package:tendergo_admin/widgets/location_picker_sheet.dart';

class TenderFilterBar extends StatelessWidget {
  final int tenderCount;

  const TenderFilterBar({super.key, required this.tenderCount});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TenderProvider>();

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: provider.categories.map((cat) {
                      return CategoryChipWidget(
                        label: cat,
                        isSelected: provider.selectedCategories.contains(cat),
                        onTap: () => provider.toggleCategory(cat),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => LocationPickerSheet.show(context),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFE5E3DC)),
                  ),
                ),
              ),
            ],
          ),
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
}