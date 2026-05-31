import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';

class TenderImageUploadSection extends StatelessWidget {
  final List<PlatformFile> imageFiles;
  final VoidCallback onPickFromDisk;
  final ValueChanged<int> onRemoveFile;
  final bool isButtonFullWidth;
  final double buttonHeight;
  final double buttonWidth;

  const TenderImageUploadSection({
    super.key,
    required this.imageFiles,
    required this.onPickFromDisk,
    required this.onRemoveFile,
    this.isButtonFullWidth = true,
    this.buttonHeight = 48,
    this.buttonWidth = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: isButtonFullWidth ? double.infinity : buttonWidth,
            child: FilledButton.icon(
              onPressed: onPickFromDisk,
              icon: const Icon(Icons.upload_file_rounded, size: 16),
              label: const Text('Upload image'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: Size.fromHeight(buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        if (imageFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ImageFileChips(imageFiles: imageFiles, onRemoveFile: onRemoveFile),
        ],
      ],
    );
  }
}

class _ImageFileChips extends StatelessWidget {
  final List<PlatformFile> imageFiles;
  final ValueChanged<int> onRemoveFile;

  const _ImageFileChips({required this.imageFiles, required this.onRemoveFile});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        imageFiles.length,
        (i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.upload_file_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  imageFiles[i].name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => onRemoveFile(i),
                child: const Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}