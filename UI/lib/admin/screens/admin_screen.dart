import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/admin_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/models/ui/auth_result.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/services/admin_service.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';

class AdminScreen extends StatefulWidget {
  final AdminService adminService;
  final AuthService authService;
  final TenderService tenderService;
  final CategoryService categoryService;

  const AdminScreen({
    super.key,
    required this.adminService,
    required this.authService,
    required this.tenderService,
    required this.categoryService,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  UserDto? _currentUser;
  List<_AdminUserRecord> _users = const [];
  List<TenderDto> _allTenders = const [];
  List<TenderDto> _activeTenders = const [];
  List<TenderDto> _closedTenders = const [];
  List<TenderDto> _cancelledTenders = const [];
  List<CategoryDto> _categories = const [];
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

  Future<void> _handleDeleteTender(TenderDto tender) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete tender'),
          content: Text('Are you sure you want to delete "${tender.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    final result = await widget.adminService.deleteTender(tender.id);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    _showSnackBar(result.message);

    if (result.success) {
      setState(() {
        _allTenders.removeWhere((t) => t.id == tender.id);
        _activeTenders.removeWhere((t) => t.id == tender.id);
      });
    }
  }

  Future<void> _handleAddCategory() async {
    final name = await _showCategoryDialog();
    if (name == null || name.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final created = await widget.categoryService.insert(
        CategoryDto(id: 0, name: name),
      );

      if (!mounted) return;
      setState(() {
        _categories = [
          ..._categories,
          created,
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _isSubmitting = false;
      });
      _showSnackBar('Category created successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackBar(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handleEditCategory(CategoryDto category) async {
    final name = await _showCategoryDialog(initialValue: category.name);
    if (name == null || name.isEmpty || name == category.name) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.categoryService.update(
        category.id,
        CategoryDto(id: category.id, name: name),
      );

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
      _showSnackBar('Category updated successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackBar(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handleDeleteCategory(CategoryDto category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete category'),
          content: Text('Are you sure you want to delete "${category.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await widget.categoryService.delete(category.id);

      if (!mounted) return;
      setState(() {
        if (success) {
          _categories = _categories.where((c) => c.id != category.id).toList();
        }
        _isSubmitting = false;
      });

      _showSnackBar(
        success
            ? 'Category deleted successfully.'
            : 'Failed to delete category.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackBar(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<String?> _showCategoryDialog({String? initialValue}) async {
    final controller = TextEditingController(text: initialValue ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(initialValue == null ? 'Add category' : 'Edit category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Category name',
              hintText: 'Enter category name',
            ),
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

  Future<void> _loadAdminData({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final currentUserResult = await widget.authService.getCurrentUser();
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
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      }

      final results = await Future.wait<dynamic>([
        widget.adminService.getAllUsers(),
        widget.tenderService.getAll(page: 1, pageSize: 100),
        widget.tenderService.getActive(),
        widget.tenderService.getClosed(),
        //widget.tenderService.getCancelled(),
        widget.categoryService.getAll(),
      ]);

      final usersResult = results[0] as AuthResult;
      if (!usersResult.success) {
        throw Exception(usersResult.message);
      }

      if (!mounted) return;
      setState(() {
        _currentUser = currentUser;
        _users = _parseUsers(usersResult.data);
        _allTenders = results[1] as List<TenderDto>;
        _activeTenders = results[2] as List<TenderDto>;
        _closedTenders = results[3] as List<TenderDto>;
        _categories = (results[4] as List<CategoryDto>)
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        // _cancelledTenders = results[4] as List<TenderDto>;
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

  Future<void> _handleBanUser(_AdminUserRecord user) async {
    final reason = await _showBanDialog(user);
    if (reason == null || reason.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await widget.adminService.banUser(
      user.id,
      BanRequest(reason: reason),
    );
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    _showSnackBar(result.message);
    if (result.success) {
      setState(() {
        _users = _users.map((u) {
          if (u.id == user.id) {
            return _AdminUserRecord(
              id: u.id,
              username: u.username,
              email: u.email,
              roles: u.roles,
              isBanned: true,
            );
          }
          return u;
        }).toList();
      });
    }
  }

  Future<void> _handleUnbanUser(_AdminUserRecord user) async {
    setState(() => _isSubmitting = true);
    final result = await widget.adminService.unbanUser(user.id);
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    _showSnackBar(result.message);
    if (result.success) {
      setState(() {
        _users = _users.map((u) {
          if (u.id == user.id) {
            return _AdminUserRecord(
              id: u.id,
              username: u.username,
              email: u.email,
              roles: u.roles,
              isBanned: false,
            );
          }
          return u;
        }).toList();
      });
    }
  }

  Future<String?> _showBanDialog(_AdminUserRecord user) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Ban ${user.displayName}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Enter the reason for this ban',
            ),
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

  List<_AdminUserRecord> _parseUsers(dynamic payload) {
    final rawList = switch (payload) {
      final List<dynamic> items => items,
      final Map<String, dynamic> map =>
        (map['result'] ?? map['items'] ?? map['data']) as List<dynamic>? ??
            const <dynamic>[],
      _ => const <dynamic>[],
    };

    return rawList
        .map(_coerceMap)
        .where((item) => item.isNotEmpty)
        .map(_AdminUserRecord.fromJson)
        .toList();
  }

  Map<String, dynamic> _coerceMap(dynamic item) {
    if (item is Map<String, dynamic>) {
      return item;
    }

    if (item is Map) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }

    return const <String, dynamic>{};
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading || _isSubmitting ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
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
            TextButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => _handleEditCategory(category),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => _handleDeleteCategory(category),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
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

  Widget _buildUserCard(_AdminUserRecord user) {
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
                          user.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusSurface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          user.isBanned ? 'Banned' : 'Active',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                        .map(
                          (role) => Chip(
                            label: Text(role),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
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
                        '${tender.categoryName} • ${tender.locationName}, ${tender.country}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => _handleDeleteTender(tender),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoSurface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tender.status.name.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                _MetaPill(
                  icon: Icons.account_circle_outlined,
                  label: tender.createdByFullname,
                ),
                _MetaPill(
                  icon: Icons.gavel_rounded,
                  label: '${tender.totalBids} bids',
                ),
                _MetaPill(
                  icon: Icons.payments_outlined,
                  label: '${tender.maxBudget.toStringAsFixed(0)} KM',
                ),
                _MetaPill(
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

enum _TenderBucket { all, active, closed, cancelled }

class _AdminUserRecord {
  final String id;
  final String username;
  final String email;
  final List<String> roles;
  final bool isBanned;

  const _AdminUserRecord({
    required this.id,
    required this.username,
    required this.email,
    required this.roles,
    required this.isBanned,
  });

  factory _AdminUserRecord.fromJson(Map<String, dynamic> json) {
    final roles = json['roles'] is List
        ? List<String>.from(
            (json['roles'] as List).map((role) => role.toString()),
          )
        : const <String>[];

    final username = (json['username'] ?? json['userName'] ?? json['fullName'])
        ?.toString()
        .trim();

    final email = json['email']?.toString().trim();
    final id = json['id']?.toString().trim();

    return _AdminUserRecord(
      id: id == null || id.isEmpty ? '' : id,
      username: username == null || username.isEmpty
          ? 'Unknown user'
          : username,
      email: email == null || email.isEmpty ? 'No email' : email,
      roles: roles,
      isBanned:
          json['isBanned'] == true ||
          json['banned'] == true ||
          json['isBlocked'] == true,
    );
  }

  String get displayName => username;

  String get initials {
    if (displayName.isEmpty) {
      return 'U';
    }

    final parts = displayName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return displayName[0].toUpperCase();
  }
}

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

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
