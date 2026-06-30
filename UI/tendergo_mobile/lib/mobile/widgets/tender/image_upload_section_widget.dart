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
  final bool isEnabled;

  const TenderImageUploadSection({
    super.key,
    required this.imageFiles,
    required this.onPickFromDisk,
    required this.onRemoveFile,
    this.isButtonFullWidth = true,
    this.buttonHeight = 48,
    this.buttonWidth = 220,
    this.isEnabled = true,
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
              onPressed: isEnabled ? onPickFromDisk : null,
              icon: const Icon(Icons.upload_file_rounded, size: 16),
              label: const Text('Upload images'),
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
          _ImagePreviewList(
            imageFiles: imageFiles,
            onRemoveFile: onRemoveFile,
            isEnabled: isEnabled,
          ),
        ],
      ],
    );
  }
}

class _ImagePreviewList extends StatelessWidget {
  final List<PlatformFile> imageFiles;
  final ValueChanged<int> onRemoveFile;
  final bool isEnabled;

  const _ImagePreviewList({
    required this.imageFiles,
    required this.onRemoveFile,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageFiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final file = imageFiles[index];

          return SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        border: Border.all(color: AppColors.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _ImagePreview(file: file),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: isEnabled ? () => onRemoveFile(index) : null,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final PlatformFile file;

  const _ImagePreview({required this.file});

  @override
  Widget build(BuildContext context) {
    final bytes = file.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.image_rounded,
          color: AppColors.textSecondary,
          size: 24,
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            file.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
