import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';

class TenderCategorySection extends StatelessWidget {
  final bool isLoading;
  final String? loadError;
  final VoidCallback onRetry;
  final List<CategoryDto> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onChanged;
  final String? Function(int?)? validator;

  const TenderCategorySection({
    super.key,
    required this.isLoading,
    required this.loadError,
    required this.onRetry,
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category *',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          )
        else if (loadError != null)
          _buildErrorState()
        else
          DropdownButtonFormField<int>(
            value: selectedCategoryId,
            isExpanded: true,
            menuMaxHeight: 280,
            decoration: InputDecoration(
              hintText: 'Select a category',
              hintStyle: const TextStyle(
                fontWeight: FontWeight.normal, 
                color: AppColors.textSecondary, 
              ),
              
              filled: true,
              fillColor: AppColors.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
            ),
            items: categories
                .map(
                  (category) => DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(category.name),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            validator: validator,
            selectedItemBuilder: (context) {
              return categories
                  .map(
                    (category) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        category.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList();
            },
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.error_outline,
                      size: 14,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      loadError!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(64, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontSize: 12, color: AppColors.primary),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            const Icon(Icons.error_outline, size: 14, color: AppColors.error),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                loadError!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(64, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}
