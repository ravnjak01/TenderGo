import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/tender_post_dto.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';
import 'package:tendergo/shared/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/shared/widgets/tender/category_section_widget.dart';
import 'package:tendergo/shared/widgets/tender/datepicker_widget.dart';
import 'package:tendergo/shared/widgets/tender/image_upload_section_widget.dart';
import 'package:tendergo/shared/widgets/tender/submit_row_widget.dart';

class MobileTenderPostScreen extends StatefulWidget {
  const MobileTenderPostScreen({super.key});

  @override
  State<MobileTenderPostScreen> createState() => _MobileTenderPostScreenState();
}

class _MobileTenderPostScreenState extends State<MobileTenderPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  int? _selectedCategoryId;
  DateTime? _deadline;
  final List<PlatformFile> _imageFiles = [];

  bool _isCategoryLoading = true;
  String? _categoryLoadError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _budgetCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isCategoryLoading = true;
      _categoryLoadError = null;
    });

    try {
      await context.read<TenderProvider>().fetchCategories();
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoryLoadError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isCategoryLoading = false;
      });
    }
  }

  Future<void> _pickImagesFromDisk() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (picked == null || picked.files.isEmpty) return;

      final newFiles = <PlatformFile>[];
      for (final file in picked.files) {
        final key = '${file.path ?? file.name}:${file.size}';
        final exists = _imageFiles.any(
          (f) => '${f.path ?? f.name}:${f.size}' == key,
        );
        if (!exists) {
          newFiles.add(file);
        }
      }

      if (newFiles.isEmpty) {
        SnackbarHelper.show(
          context,
          'Selected files are already added.',
          isError: true,
        );
        return;
      }

      setState(() => _imageFiles.addAll(newFiles));
    } catch (e) {
      SnackbarHelper.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _removeImageFile(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  Future<void> _submitTender() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategoryId == null) {
      SnackbarHelper.show(context, 'Please select a category.', isError: true);
      return;
    }
    if (_deadline == null) {
      SnackbarHelper.show(context, 'Please select a deadline.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = TenderInsertRequest(
        title: _titleCtrl.text.trim(),
        maxBudget: double.parse(_budgetCtrl.text.trim()),
        locationName: _locationCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        categoryId: _selectedCategoryId!,
        deadline: _deadline!,
        imageBytes: null,
      );

      await context.read<TenderProvider>().createTender(
        request,
        imageFiles: _imageFiles,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDraft() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategoryId == null) {
      SnackbarHelper.show(context, 'Please select a category.', isError: true);
      return;
    }
    if (_deadline == null) {
      SnackbarHelper.show(context, 'Please select a deadline.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = TenderInsertRequest(
        title: _titleCtrl.text.trim(),
        maxBudget: double.parse(_budgetCtrl.text.trim()),
        locationName: _locationCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        categoryId: _selectedCategoryId!,
        deadline: _deadline!,
        imageBytes: null,
      );

      await context.read<TenderProvider>().saveDraft(
        request: request,
        imageFiles: _imageFiles,
      );
      if (!mounted) return;
      SnackbarHelper.show(context, 'Draft saved successfully!');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<TenderProvider>().categories;
    final bool isDesktopWidth = MediaQuery.sizeOf(context).width >= 900;
    final int descriptionLines = isDesktopWidth ? 5 : 4;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Post Tender'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (v) => _validateRequired(v, 'Title'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'-')),
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
                decoration: const InputDecoration(labelText: 'Max Budget *'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Budget is required';
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TenderCategorySection(
                isLoading: _isCategoryLoading,
                loadError: _categoryLoadError,
                onRetry: _loadCategories,
                categories: categories,
                selectedCategoryId: _selectedCategoryId,
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Location *'),
                validator: (v) => _validateRequired(v, 'Location'),
              ),
              const SizedBox(height: 12),
              DatepickerWidget(
                deadline: _deadline,
                onDateSelected: (newDate) {
                  setState(() {
                    _deadline = newDate;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                minLines: descriptionLines,
                maxLines: descriptionLines,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TenderImageUploadSection(
                imageFiles: _imageFiles,
                onPickFromDisk: _pickImagesFromDisk,
                onRemoveFile: _removeImageFile,
                isButtonFullWidth: false,
                buttonWidth: 190,
                buttonHeight: 42,
              ),
              const SizedBox(height: 24),
              TenderSubmitRow(
                isLoading: _isLoading,
                onSaveDraft: _saveDraft,
                onSubmitTender: _submitTender,
                useCompactStyle: true,
                fullWidthOnMobile: false,
                saveDraftLabel: 'Draft',
                publishTenderLabel: 'Publish',
              ),
            ],
          ),
        ),
      ),
    );
  }
}