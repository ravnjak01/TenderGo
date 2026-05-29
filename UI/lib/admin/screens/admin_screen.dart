import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/core/utils/extensions/user_initials_extension.dart';
import 'package:tendergo/shared/models/dto/admin_dto.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/models/dto/location_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/models/requests/location_insert_request.dart';
import 'package:tendergo/shared/models/requests/location_update_request.dart';
import 'package:tendergo/shared/models/ui/api_response.dart';
import 'package:tendergo/shared/providers/admin_provider.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/services/pdf_service.dart';
import 'package:tendergo/shared/widgets/common/action_button.dart';
import 'package:tendergo/shared/widgets/common/app_badge.dart';
import 'package:tendergo/shared/widgets/common/app_dialogs.dart';
import 'package:tendergo/shared/widgets/common/app_icon.dart';
import 'package:tendergo/shared/widgets/common/app_text_field.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/shared/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/shared/widgets/tender/tender_meta_item.dart';

class AdminScreen extends StatefulWidget {
  final AdminProvider provider;

  const AdminScreen({super.key, required this.provider});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  UserDto? _currentUser;
  List<UserDto> _users = const [];
  List<TenderDto> _allTenders = const [];
  List<TenderDto> _activeTenders = const [];
  List<TenderDto> _closedTenders = const [];
  List<TenderDto> _cancelledTenders = const [];
  List<CategoryDto> _categories = const [];
  List<LocationDto> _locations = const [];
  _TenderBucket _selectedBucket = _TenderBucket.all;

  bool get _isAdmin {
    final roles = _currentUser?.roles ?? const <String>[];
    return roles.any((role) => role.toLowerCase() == 'admin');
  }

  List<TenderDto> get _visibleTenders {
    switch (_selectedBucket) {
      case _TenderBucket.all:
        return _allTenders;

      case _TenderBucket.active:
        return _allTenders
            .where((t) => t.status.name.toLowerCase() == 'open')
            .toList();

      case _TenderBucket.closed:
        return _allTenders
            .where((t) => t.status.name.toLowerCase() == 'closed')
            .toList();

      case _TenderBucket.cancelled:
        return _allTenders
            .where((t) => t.status.name.toLowerCase() == 'cancelled')
            .toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _handleCancelTender(TenderDto tender) async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: 'Cancel tender',
      content: 'Are you sure you want to cancel this tender?',
      cancelLabel: 'No',
      confirmLabel: 'Yes, Cancel',
      isDestructive: true,
    );

    if (!confirmed) return;

    setState(() => _isSubmitting = true);

    try {
      final cancelledTender = await widget.provider.cancelTender(tender.id);

      if (!mounted) return;

      setState(() {
        _allTenders = _allTenders
            .map((t) => t.id == tender.id ? cancelledTender : t)
            .toList();
        _activeTenders = _activeTenders
            .where((t) => t.id != tender.id)
            .toList();
        _closedTenders = _closedTenders
            .where((t) => t.id != tender.id)
            .toList();
        _cancelledTenders = [
          cancelledTender,
          ..._cancelledTenders.where((t) => t.id != tender.id),
        ];
        _isSubmitting = false;
      });

      SnackbarHelper.show(context, 'Tender canceled successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnackbarHelper.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _handleAddCategory() async {
    final name = await _showCategoryDialog();
    if (name == null || name.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final created = await widget.provider.insertCategory(name);

      if (!mounted) return;
      setState(() {
        _categories = [
          ..._categories,
          created,
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _isSubmitting = false;
      });
      SnackbarHelper.show(context, 'Category created successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnackbarHelper.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _handleEditCategory(CategoryDto category) async {
    final name = await _showCategoryDialog(initialValue: category.name);
    if (name == null || name.isEmpty || name == category.name) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.provider.updateCategory(category.id, name);

      if (!mounted) return;
      setState(() {
        _categories =
            _categories
                .map(
                  (c) => c.id == category.id
                      ? CategoryDto(id: c.id, name: name)
                      : c,
                )
                .toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
        _isSubmitting = false;
      });
      SnackbarHelper.show(context, 'Category updated successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnackbarHelper.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  // 🌟 Dodaj u _AdminScreenState klasu
  Future<void> _handleDownloadUserReport(UserDto user) async {
    setState(() => _isSubmitting = true);

    try {
      // 1. Pozivamo tvoj PdfService koji smo kreirali u prethodnom koraku
      final pdfBytes = await PdfService().fetchUserTendersReport(
        user.id.toString(),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (pdfBytes != null) {
        // 2. Ako su bajtovi uspješno stigli, navigiramo na ekran za prikaz PDF-a
        Navigator.of(context).pushNamed(
          AppRoutes
              .pdfViewer, // 🌟 Popravljeno: koristi se klasa AppRoutes direktno
          arguments: {
            'pdfBytes': pdfBytes,
            'title': 'Izvještaj: ${_userDisplayName(user)}',
          },
        );
      } else {
        SnackbarHelper.show(
          context,
          'Greška pri generisanju PDF-a.',
          isError: true,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnackbarHelper.show(context, 'Došlo je do greške: $error', isError: true);
    }
  }

  Future<void> _handleDeleteCategory(CategoryDto category) async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: 'Delete category',
      content: 'Are you sure you want to delete "${category.name}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!confirmed) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await widget.provider.deleteCategory(category.id);

      if (!mounted) return;
      setState(() {
        if (success) {
          _categories = _categories.where((c) => c.id != category.id).toList();
        }
        _isSubmitting = false;
      });

      SnackbarHelper.show(
        context,
        success
            ? 'Category deleted successfully.'
            : 'Failed to delete category.',
        isError: !success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnackbarHelper.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<String?> _showCategoryDialog({String? initialValue}) async {
    final controller = TextEditingController(text: initialValue ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(initialValue == null ? 'Add category' : 'Edit category'),
          content: AppTextField(
            controller: controller,
            label: 'Category name',
            hint: 'Enter category name',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                Navigator.of(dialogContext).pop(value);
              },
              child: Text(initialValue == null ? 'Create' : 'Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _handleAddLocation() async {
    final values = await _showLocationDialog();
    if (values == null || values.name.isEmpty || values.country.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = LocationInsertRequest(
        name: values.name,
        country: values.country,
        region: values.region,
      );

      final created = await widget.provider.insertLocation(request);

      if (!mounted) return;
      setState(() {
        _locations = [..._locations, created]..sort(_compareLocations);
        _isSubmitting = false;
      });
      SnackbarHelper.show(context, 'Location created successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnackbarHelper.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _handleEditLocation(LocationDto location) async {
    final values = await _showLocationDialog(
      initialName: location.name,
      initialCountry: location.country,
      initialRegion: location.region,
    );
    if (values == null || values.name.isEmpty || values.country.isEmpty) {
      return;
    }

    if (values.name == location.name &&
        values.country == location.country &&
        values.region == location.region) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = LocationUpdateRequest(
        name: values.name,
        country: values.country,
        region: values.region,
      );

      await widget.provider.updateLocation(location.id, request);

      if (!mounted) return;
      setState(() {
        _locations =
            _locations
                .map(
                  (l) => l.id == location.id
                      ? LocationDto(
                          id: l.id,
                          name: values.name,
                          country: values.country,
                          region: values.region,
                        )
                      : l,
                )
                .toList()
              ..sort(_compareLocations);
        _isSubmitting = false;
      });
      SnackbarHelper.show(context, 'Location updated successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnackbarHelper.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _handleDeleteLocation(LocationDto location) async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: 'Delete location',
      content:
          'Are you sure you want to delete "${location.name}, ${location.country}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!confirmed) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await widget.provider.deleteLocation(location.id);

      if (!mounted) return;
      setState(() {
        if (success) {
          _locations = _locations.where((l) => l.id != location.id).toList();
        }
        _isSubmitting = false;
      });

      SnackbarHelper.show(
        context,
        success
            ? 'Location deleted successfully.'
            : 'Failed to delete location.',
        isError: !success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnackbarHelper.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<_LocationFormValues?> _showLocationDialog({
    String? initialName,
    String? initialCountry,
    String? initialRegion,
  }) async {
    final nameController = TextEditingController(text: initialName ?? '');
    final countryController = TextEditingController(text: initialCountry ?? '');
    final regionController = TextEditingController(text: initialRegion ?? '');

    final result = await showDialog<_LocationFormValues>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(initialName == null ? 'Add location' : 'Edit location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: nameController,
                  label: 'City',
                  hint: 'Enter city name',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: countryController,
                  label: 'Country',
                  hint: 'Enter country',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: regionController,
                  label: 'Region (optional)',
                  hint: 'Enter region',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final region = regionController.text.trim();
                Navigator.of(dialogContext).pop(
                  _LocationFormValues(
                    name: nameController.text.trim(),
                    country: countryController.text.trim(),
                    region: region.isEmpty ? null : region,
                  ),
                );
              },
              child: Text(initialName == null ? 'Create' : 'Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    countryController.dispose();
    regionController.dispose();
    return result;
  }

  int _compareLocations(LocationDto a, LocationDto b) {
    final countryCompare = a.country.toLowerCase().compareTo(
      b.country.toLowerCase(),
    );
    if (countryCompare != 0) return countryCompare;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  Future<void> _loadAdminData({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final currentUserResult = await widget.provider.getCurrentUser();
      final currentUser = currentUserResult.data;

      if (!currentUserResult.success || currentUser is! UserDto) {
        throw Exception(currentUserResult.message);
      }

      _currentUser = currentUser;

      final isAdmin = currentUser.roles.any(
        (role) => role.toLowerCase() == 'admin',
      );

      if (!isAdmin) {
        if (!mounted) return;
        setState(() {
          _currentUser = currentUser;
          _users = const [];
          _allTenders = const [];
          _activeTenders = const [];
          _closedTenders = const [];
          _cancelledTenders = const [];
          _categories = const [];
          _locations = const [];
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      }

      final results = await Future.wait<dynamic>([
        widget.provider.getAllUsers(),
        widget.provider.getAllTenders(),
        widget.provider.getActiveTenders(),
        widget.provider.getClosedTenders(),
        widget.provider.getCancelledTenders(),
        widget.provider.getCategories(),
        widget.provider.getLocations(),
      ]);

      final usersResult = results[0] as ApiResponse;
      if (!usersResult.success) {
        throw Exception(usersResult.message);
      }

      if (!mounted) return;
      setState(() {
        _currentUser = currentUser;
        _users = usersResult.data is List<UserDto>
            ? usersResult.data as List<UserDto>
            : const [];
        _allTenders = results[1] as List<TenderDto>;
        _activeTenders = results[2] as List<TenderDto>;
        _closedTenders = results[3] as List<TenderDto>;
        _cancelledTenders = results[4] as List<TenderDto>;
        _categories = (results[5] as List<CategoryDto>)
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        _locations = (results[6] as List<LocationDto>)..sort(_compareLocations);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _refresh() async {
    await _loadAdminData(showLoader: false);
  }

  Future<void> _handleBanUser(UserDto user) async {
    final reason = await _showBanDialog(user);
    if (reason == null || reason.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await widget.provider.banUser(
      user.id,
      BanRequest(reason: reason),
    );
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    SnackbarHelper.show(context, result.message, isError: !result.success);
    if (result.success) {
      setState(() {
        _users = _users.map((u) {
          if (u.id == user.id) {
            return UserDto(
              id: u.id,
              email: u.email,
              username: u.username,
              firstName: u.firstName,
              lastName: u.lastName,
              address: u.address,
              profileImageUrl: u.profileImageUrl,
              roles: u.roles,
              isBanned: true,
            );
          }
          return u;
        }).toList();
      });
    }
  }

  Future<void> _handleUnbanUser(UserDto user) async {
    setState(() => _isSubmitting = true);
    final result = await widget.provider.unbanUser(user.id);
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    SnackbarHelper.show(context, result.message, isError: !result.success);
    if (result.success) {
      setState(() {
        _users = _users.map((u) {
          if (u.id == user.id) {
            return UserDto(
              id: u.id,
              email: u.email,
              username: u.username,
              firstName: u.firstName,
              lastName: u.lastName,
              address: u.address,
              profileImageUrl: u.profileImageUrl,
              roles: u.roles,
              isBanned: false,
            );
          }
          return u;
        }).toList();
      });
    }
  }

  Future<String?> _showBanDialog(UserDto user) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Ban ${_userDisplayName(user)}'),
          content: AppTextField(
            controller: controller,
            label: 'Reason',
            hint: 'Enter the reason for this ban',
            minLines: 2,
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return reason;
  }

  String _userDisplayName(UserDto user) {
    final name = '${user.firstName} ${user.lastName}'.trim();
    return name.isNotEmpty ? name : user.username;
  }

  void _goBackHome() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.tenderList, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: const Text('Admin Console'),
        actions: [
          AppIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: _isLoading || _isSubmitting ? () {} : _refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ScreenLoadingState(message: 'Loading admin data...');
    }

    if (_errorMessage != null) {
      return ScreenErrorState(message: _errorMessage!, onRetry: _loadAdminData);
    }

    if (!_isAdmin) {
      return ScreenEmptyState(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Admin access required',
        description:
            'This screen is only available to users with the Admin role.',
        actionLabel: 'Go to tenders',
        onAction: _goBackHome,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _buildSummarySection(),
          const SizedBox(height: 24),
          _buildUsersSection(),
          const SizedBox(height: 24),
          _buildCategoriesSection(),
          const SizedBox(height: 24),
          _buildLocationsSection(),
          const SizedBox(height: 24),
          _buildTenderSection(),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Category management',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _handleAddCategory,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add category'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_categories.isEmpty)
          ScreenEmptyState(
            icon: Icons.category_outlined,
            title: 'No categories found',
            description: 'Create a category to start organizing tenders.',
            actionLabel: 'Add category',
            onAction: _handleAddCategory,
          )
        else
          ..._categories.map(_buildCategoryCard),
      ],
    );
  }

  Widget _buildLocationsSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Location management',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _handleAddLocation,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add location'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_locations.isEmpty)
          ScreenEmptyState(
            icon: Icons.location_on_outlined,
            title: 'No locations found',
            description: 'Create a location for tender filtering and posting.',
            actionLabel: 'Add location',
            onAction: _handleAddLocation,
          )
        else
          ..._locations.map(_buildLocationCard),
      ],
    );
  }

  Widget _buildLocationCard(LocationDto location) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtitle = location.region != null && location.region!.isNotEmpty
        ? '${location.country} • ${location.region}'
        : location.country;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            ActionButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              isPrimary: true,
              onTap: _isSubmitting ? null : () => _handleEditLocation(location),
            ),
            const SizedBox(width: 6),
            ActionButton(
              label: 'Delete',
              icon: Icons.delete_outline_rounded,
              isPrimary: false,
              isDestructive: true,
              onTap: _isSubmitting
                  ? null
                  : () => _handleDeleteLocation(location),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryDto category) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ActionButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              isPrimary: true,
              onTap: _isSubmitting ? null : () => _handleEditCategory(category),
            ),
            const SizedBox(width: 6),
            ActionButton(
              label: 'Delete',
              icon: Icons.delete_outline_rounded,
              isPrimary: false,
              isDestructive: true,
              onTap: _isSubmitting
                  ? null
                  : () => _handleDeleteCategory(category),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              label: 'Users',
              value: _users.length.toString(),
              icon: Icons.group_rounded,
            ),
            _StatCard(
              label: 'All tenders',
              value: _allTenders.length.toString(),
              icon: Icons.inventory_2_rounded,
            ),
            _StatCard(
              label: 'Active',
              value: _activeTenders.length.toString(),
              icon: Icons.check_circle_outline_rounded,
            ),
            _StatCard(
              label: 'Closed',
              value: _closedTenders.length.toString(),
              icon: Icons.event_busy_rounded,
            ),
            _StatCard(
              label: 'Cancelled',
              value: _cancelledTenders.length.toString(),
              icon: Icons.cancel_outlined,
            ),
            _StatCard(
              label: 'Categories',
              value: _categories.length.toString(),
              icon: Icons.category_outlined,
            ),
            _StatCard(
              label: 'Locations',
              value: _locations.length.toString(),
              icon: Icons.location_on_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsersSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'User management',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text('${_users.length} users', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 12),
        if (_users.isEmpty)
          ScreenEmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No users found',
            description: 'The admin endpoint returned an empty user list.',
            onAction: _refresh,
          )
        else
          ..._users.map(_buildUserCard),
      ],
    );
  }

  Widget _buildUserCard(UserDto user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = user.isBanned ? AppColors.error : AppColors.success;
    final statusSurface = user.isBanned
        ? AppColors.errorSurface
        : AppColors.successSurface;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.infoSurface,
              foregroundColor: AppColors.primaryDark,
              child: Text(user.initials),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _userDisplayName(user),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      AppBadge(
                        label: user.isBanned ? 'Banned' : 'Active',
                        backgroundColor: statusSurface,
                        foregroundColor: statusColor,
                        borderColor: statusSurface,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(user.email, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.roles
                        .map((role) => AppBadge(label: role))
                        .toList(),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.blueAccent,
              ),
              tooltip: 'Generiši izvještaj',
              onPressed: _isSubmitting
                  ? null
                  : () => _handleDownloadUserReport(user),
            ),
            const SizedBox(width: 12),
            user.isBanned
                ? FilledButton.tonalIcon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleUnbanUser(user),
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('Unban'),
                  )
                : FilledButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleBanUser(user),
                    icon: const Icon(Icons.block_rounded),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    label: const Text('Ban'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTenderSection() {
    final theme = Theme.of(context);
    final tenders = _visibleTenders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tender inventory',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<_TenderBucket>(
            segments: const [
              ButtonSegment<_TenderBucket>(
                value: _TenderBucket.all,
                label: Text('All'),
                icon: Icon(Icons.inventory_2_outlined),
              ),
              ButtonSegment<_TenderBucket>(
                value: _TenderBucket.active,
                label: Text('Active'),
                icon: Icon(Icons.check_circle_outline_rounded),
              ),
              ButtonSegment<_TenderBucket>(
                value: _TenderBucket.closed,
                label: Text('Closed'),
                icon: Icon(Icons.event_busy_outlined),
              ),
              ButtonSegment<_TenderBucket>(
                value: _TenderBucket.cancelled,
                label: Text('Cancelled'),
                icon: Icon(Icons.cancel_outlined),
              ),
            ],
            selected: {_selectedBucket},
            onSelectionChanged: (selection) {
              setState(() {
                _selectedBucket = selection.first;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        if (tenders.isEmpty)
          ScreenEmptyState(
            icon: Icons.inventory_outlined,
            title: 'No tenders in this bucket',
            description: 'Change the selected filter or refresh to try again.',
            onAction: _refresh,
          )
        else
          ...tenders.take(12).map(_buildTenderCard),
      ],
    );
  }

  Widget _buildTenderCard(TenderDto tender) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tender.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tender.categoryName} • ${tender.location.name}, ${tender.location.country}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),

                      if (tender.status == TenderStatus.open)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () => _handleCancelTender(tender),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                AppBadge(
                  label: tender.status.label,
                  backgroundColor: tender.status.badgeBg,
                  foregroundColor: tender.status.badgeFg,
                  borderColor: tender.status.badgeBg,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                TenderMetaItem(
                  icon: Icons.account_circle_outlined,
                  label: tender.createdByFullname,
                ),
                TenderMetaItem(
                  icon: Icons.gavel_rounded,
                  label: '${tender.totalBids} bids',
                ),
                TenderMetaItem(
                  icon: Icons.payments_outlined,
                  label: '${tender.maxBudget.toStringAsFixed(0)} KM',
                ),
                TenderMetaItem(
                  icon: Icons.event_outlined,
                  label: 'Deadline ${_formatDate(tender.deadline)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }
}

class _LocationFormValues {
  final String name;
  final String country;
  final String? region;

  const _LocationFormValues({
    required this.name,
    required this.country,
    this.region,
  });
}

enum _TenderBucket { all, active, closed, cancelled }

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 172,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
