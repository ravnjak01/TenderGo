import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/requests/tender_insert_request.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';
import 'package:tendergo/shared/services/location_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/common/app_card.dart';
import 'package:tendergo/shared/widgets/common/app_text_field.dart';
import 'package:tendergo/shared/widgets/common/error_banner_widget.dart';
import 'package:tendergo/shared/widgets/tender/category_section_widget.dart';
import 'package:tendergo/shared/widgets/tender/location_section_widget.dart';
import 'package:tendergo/shared/widgets/tender/image_upload_section_widget.dart';
import 'package:tendergo/shared/widgets/tender/datepicker_widget.dart';
import 'package:tendergo/shared/widgets/feedback/fade_in_widget.dart';
import 'package:tendergo/shared/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/shared/widgets/tender/submit_row_widget.dart';

class TenderPostScreen extends StatefulWidget {
  final TenderService tenderService;
  final LocationService locationService;

  const TenderPostScreen({
    super.key,
    required this.tenderService,
    required this.locationService,
  });

  @override
  State<TenderPostScreen> createState() => _TenderPostScreenState();
}

class _TenderPostScreenState extends State<TenderPostScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  int? _selectedCategoryId;
  int? _selectedLocationId;
  DateTime? _deadline;
  final List<PlatformFile> _imageFiles = [];
  bool _isCategoryLoading = true;
  String? _categoryLoadError;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isCategoryLoading = true;
      _categoryLoadError = null;
    });

    try {
      await context.read<TenderProvider>().fetchCategories();

      if (!mounted) return;

      setState(() {
        _isCategoryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCategoryLoading = false;
        _categoryLoadError = e
            .toString()
            .replaceFirst('Exception: ', '')
            .trim();
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _budgetCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  } 

  Future<void> _pickImagesFromDisk() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      // 🌟 Rješenje 1: Provjera odmah nakon završetka asinhronog FilePicker-a
      if (!mounted) return;

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
      // 🌟 Rješenje 2: Provjera unutar catch bloka u slučaju greške
      if (!mounted) return;

      SnackbarHelper.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _removeImageFile(int index) =>
      setState(() => _imageFiles.removeAt(index));

  Future<void> _submitTender() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      SnackbarHelper.show(context, 'Please select a deadline', isError: true);
      return;
    }
    if (_selectedCategoryId == null) {
      SnackbarHelper.show(context, 'Please select a category', isError: true);
      return;
    }
    if (_selectedLocationId == null) {
      SnackbarHelper.show(context, 'Please select a location', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = TenderInsertRequest(
        title: _titleCtrl.text.trim(),
        maxBudget: double.parse(_budgetCtrl.text.trim()),
        locationId: _selectedLocationId!,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        categoryId: _selectedCategoryId!,
        deadline: _deadline!,
        imageBytes: null,
      );

      await widget.tenderService.create(request, imageFiles: _imageFiles);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      SnackbarHelper.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _cardField(Widget child) =>
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: child);

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<TenderProvider>().categories;
    final bool isDesktopWidth = MediaQuery.sizeOf(context).width >= 900;
    final int descriptionLines = isDesktopWidth ? 5 : 4;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: FadeInWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBanner(),
                const SizedBox(height: 20),

                // ── Tender Details ────────────────────────────────
                AppCard(
                  title: 'TENDER DETAILS',
                  icon: Icons.edit_outlined,
                  children: [
                    _cardField(
                      AppTextField(
                        controller: _titleCtrl,
                        label: 'Title *',
                        hint: 'e.g. Road Construction — Phase 2',
                        prefixIcon: Icons.edit_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Title is required'
                            : null,
                      ),
                    ),
                    _cardField(_buildBudgetField()),
                    _cardField(
                      TenderCategorySection(
                        isLoading: _isCategoryLoading,
                        loadError: _categoryLoadError,
                        onRetry: _loadCategories,
                        categories: categories,
                        selectedCategoryId: _selectedCategoryId,
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                            _errorMessage = null;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                    ),
                    _cardField(
                      TenderLocationSection(
                        locationService: widget.locationService,
                        selectedLocationId: _selectedLocationId,
                        onChanged: (value) {
                          setState(() {
                            _selectedLocationId = value;
                            _errorMessage = null;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a city';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Deadline & Description ────────────────────────
                AppCard(
                  title: 'DEADLINE & DESCRIPTION',
                  icon: Icons.event_outlined,
                  children: [
                    _cardField(
                      DatepickerWidget(
                        deadline: _deadline,
                       onDateSelected: (newDate) {
                          setState(() => _deadline = newDate);
                        },
                      ),
                    ),
                    _cardField(
                      AppTextField(
                        controller: _descCtrl,
                        label: 'Description (optional)',
                        hint:
                            'Describe scope, requirements, evaluation criteria…',
                        minLines: descriptionLines,
                        maxLines: descriptionLines,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Media ─────────────────────────────────────────
                AppCard(
                  title: 'IMAGES (OPTIONAL)',
                  icon: Icons.image_outlined,
                  children: [
                    _cardField(
                      TenderImageUploadSection(
                        imageFiles: _imageFiles,
                        onPickFromDisk: _pickImagesFromDisk,
                        onRemoveFile: _removeImageFile,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  ErrorBannerWidget(
                    message: _errorMessage!,
                    onClose: () => setState(() => _errorMessage = null),
                  ),
                ],

                const SizedBox(height: 32),
                TenderSubmitRow(
                  isLoading: _isLoading,
                  onSubmitTender: _submitTender,
                ),

                const SizedBox(height: 20),

              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: AppColors.surface,
    elevation: 0,
    centerTitle: false,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    leading: const CustomBackButton(),
    title: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(
            Icons.post_add_rounded,
            color: AppColors.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Post Tender',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: AppColors.outline),
    ),
  );

  Widget _buildBanner() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.08),
          AppColors.primary.withValues(alpha: 0.03),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.description_outlined,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a New Tender',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Fill in the details below. Fields marked * are required.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // Budget stays as raw TextFormField — needs inputFormatters which AppTextField doesn't support
  Widget _buildBudgetField() => TextFormField(
    controller: _budgetCtrl,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      FilteringTextInputFormatter.deny(RegExp(r'-')),
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
    ],
    decoration: InputDecoration(
      labelText: 'Max Budget *',
      hintText: '0.00',
      prefixIcon: const Padding(
        padding: EdgeInsets.only(left: 12, right: 4),
        child: Text(
          '\$',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),
    validator: (v) {
      if (v == null || v.trim().isEmpty) return 'Required';
      final d = double.tryParse(v.trim());
      if (d == null || d <= 0) return 'Invalid amount';
      return null;
    },
  );

}
