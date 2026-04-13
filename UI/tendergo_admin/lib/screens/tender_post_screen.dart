import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tendergo_admin/core/theme/app_theme.dart';
import 'package:tendergo_admin/models/dto/category_dto.dart';
import 'package:tendergo_admin/models/dto/tender_post_dto.dart';
import 'package:tendergo_admin/providers/tender_provider.dart';
import 'package:tendergo_admin/services/category_service.dart';
import 'package:tendergo_admin/services/dio_client.dart';
import 'package:tendergo_admin/services/tender_service.dart';
import 'package:tendergo_admin/widgets/category_chip_widget.dart';
import 'package:tendergo_admin/widgets/datepicker_widget.dart';
import 'package:tendergo_admin/widgets/error_banner.widget.dart';
import 'package:tendergo_admin/widgets/common/app_card.dart';
import 'package:tendergo_admin/widgets/common/app_icon.dart';
import 'package:tendergo_admin/widgets/common/app_text_field.dart';

class TenderPostScreen extends StatefulWidget {
  final TenderService tenderService;

  const TenderPostScreen({super.key, required this.tenderService});

  @override
  State<TenderPostScreen> createState() => _TenderPostScreenState();
}

class _TenderPostScreenState extends State<TenderPostScreen>
    with SingleTickerProviderStateMixin {
  late final TenderService _tenderService = widget.tenderService;
  late final CategoryService _categoryService =
      CategoryService(DioClient.getDio());

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  int? _selectedCategoryId;
  DateTime? _deadline;
  final List<String> _imageUrls = [];
  List<CategoryDto> _categories = [];
  bool _isCategoryLoading = true;
  String? _categoryLoadError;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _aniCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 540),
  )..forward();
  late final Animation<double> _fadeAni =
      CurvedAnimation(parent: _aniCtrl, curve: Curves.easeOut);

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
      final categories = await _categoryService.getAll();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isCategoryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCategoryLoading = false;
        _categoryLoadError = e.toString().replaceFirst('Exception: ', '').trim();
      });
    }
  }

  @override
  void dispose() {
    _aniCtrl.dispose();
    _titleCtrl.dispose();
    _budgetCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _deadline = DateTime(
            picked.year, picked.month, picked.day, 23, 59, 59,
          ));
    }
  }

  void _addImageUrl() {
    final url = _imageUrlCtrl.text.trim();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isAbsolute) {
      _showSnack('Enter a valid URL', isError: true);
      return;
    }
    setState(() => _imageUrls.add(url));
    _imageUrlCtrl.clear();
  }

  void _removeImageUrl(int index) => setState(() => _imageUrls.removeAt(index));

  TenderInsertRequest _buildRequest() => TenderInsertRequest(
        title: _titleCtrl.text.trim(),
        maxBudget: double.parse(_budgetCtrl.text.trim()),
        locationName: _locationCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        categoryId: _selectedCategoryId!,
        deadline: _deadline!,
        imageUrls: _imageUrls.isEmpty ? null : List.from(_imageUrls),
      );

  bool _validateExtra() {
    if (_deadline == null) {
      setState(() => _errorMessage = 'Please select a deadline date.');
      return false;
    }
    if (_selectedCategoryId == null) {
      setState(() => _errorMessage = 'Please select a category.');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_validateExtra()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await context.read<TenderProvider>().createTender(_buildRequest());
      if (!mounted) return;
      _showSnack('Tender published successfully!');
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDraft() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_validateExtra()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await _tenderService.createDraft(_buildRequest());
      if (!mounted) return;
      _showSnack('Draft saved successfully!');
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? AppColors.error : AppColors.success,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isError
                ? AppColors.error.withValues(alpha: 0.4)
                : AppColors.success.withValues(alpha: 0.4),
          ),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _cardField(Widget child) =>
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: child);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAni,
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
                    _cardField(AppTextField(
                      controller: _titleCtrl,
                      label: 'Title *',
                      hint: 'e.g. Road Construction — Phase 2',
                      prefixIcon: Icons.edit_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Title is required'
                          : null,
                    )),
                    _cardField(_buildBudgetField()),
                    _cardField(_buildCategorySection()),
                    _cardField(AppTextField(
                      controller: _locationCtrl,
                      label: 'Location *',
                      hint: 'e.g. Sarajevo, Bosnia',
                      prefixIcon: Icons.place_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Location is required'
                          : null,
                    )),
                    const SizedBox(height: 4),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Deadline & Description ────────────────────────
                AppCard(
                  title: 'DEADLINE & DESCRIPTION',
                  icon: Icons.event_outlined,
                  children: [
                    _cardField(DatepickerWidget(
                      deadline: _deadline,
                      onTap: _pickDeadline,
                    )),
                    _cardField(AppTextField(
                      controller: _descCtrl,
                      label: 'Description (optional)',
                      hint: 'Describe scope, requirements, evaluation criteria…',
                      minLines: 5,
                      maxLines: 5,
                    )),
                    const SizedBox(height: 4),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Media ─────────────────────────────────────────
                AppCard(
                  title: 'IMAGE URLS (OPTIONAL)',
                  icon: Icons.image_outlined,
                  children: [
                    _cardField(_buildImageUrlRow()),
                    if (_imageUrls.isNotEmpty) _cardField(_buildImageChips()),
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

                const SizedBox(height: 28),
                _buildSubmitRow(),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 17, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.post_add_rounded,
                  color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 10),
            const Text(
              'Post Tender',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
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
          gradient: LinearGradient(colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.03),
          ]),
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
              child: const Icon(Icons.description_outlined,
                  color: AppColors.primary, size: 22),
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
                        fontSize: 14),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Fill in the details below. Fields marked * are required.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
            child: Text('\$',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.error, width: 1.5),
          ),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          final d = double.tryParse(v.trim());
          if (d == null || d <= 0) return 'Invalid amount';
          return null;
        },
      );

  Widget _buildCategorySection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CATEGORY *',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 8),
          if (_isCategoryLoading)
            // Small inline spinner — ScreenLoadingState is a full-screen widget
            const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            )
          else if (_categoryLoadError != null)
            // ScreenErrorState is full-screen too, so use a compact inline version
            Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 14, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _categoryLoadError!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: _loadCategories,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Retry',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.primary)),
                ),
              ],
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories
                    .map((c) => CategoryChipWidget(
                          label: c.name,
                          isSelected: _selectedCategoryId == c.id,
                          onTap: () =>
                              setState(() => _selectedCategoryId = c.id),
                        ))
                    .toList(),
              ),
            ),
        ],
      );

  Widget _buildImageUrlRow() => Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _imageUrlCtrl,
              label: 'Paste image URL…',
              prefixIcon: Icons.link_rounded,
            ),
          ),
          const SizedBox(width: 10),
          AppIconButton(icon: Icons.add_rounded, onTap: _addImageUrl),
        ],
      );

  Widget _buildImageChips() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(
          _imageUrls.length,
          (i) => Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    _imageUrls[i],
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _removeImageUrl(i),
                  child: const Icon(Icons.close_rounded,
                      size: 13, color: AppColors.error),
                ),
              ],
            ),
          ),
        ),
      );

  // ActionButton doesn't support icons or loading state, so the submit
  // row keeps full ElevatedButton/OutlinedButton implementations
  Widget _buildSubmitRow() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 146,
            height: 52,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _saveDraft,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isLoading
                    ? const SizedBox(
                        key: ValueKey('loader_draft'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: AppColors.primary),
                      )
                    : const Row(
                        key: ValueKey('label_draft'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.drafts,
                              color: AppColors.primary, size: 19),
                          SizedBox(width: 8),
                          Text(
                            'Save Draft',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 180,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.textDisabled,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isLoading
                    ? const SizedBox(
                        key: ValueKey('loader'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Row(
                        key: ValueKey('label'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.publish_rounded,
                              color: Colors.white, size: 19),
                          SizedBox(width: 8),
                          Text(
                            'Publish Tender',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      );
}