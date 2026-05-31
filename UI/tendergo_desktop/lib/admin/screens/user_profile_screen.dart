import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tendergo/admin/routes/routes.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/core/utils/extensions/string_extensions.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/admin/screens/edit_profile_screen.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/user_service.dart';
import 'package:tendergo/shared/widgets/common/app_action_tile.dart';
import 'package:tendergo/shared/widgets/common/app_badge.dart';
import 'package:tendergo/shared/widgets/common/app_dialogs.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/shared/widgets/profile/user_profile_cards.dart';
import 'package:tendergo/shared/widgets/profile/user_profile_header.dart';
import 'package:provider/provider.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class UserProfileScreen extends StatefulWidget {
  final AuthService authService;

  const UserProfileScreen({super.key, required this.authService});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late UserService _userService;

  UserDto? _user;
  String? _errorMessage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    final dio = DioClient.getDio();
    _userService = UserService(dio);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final userResult = await context.read<AuthProvider>().loadUser();
      if (!mounted) return;

      if (!userResult.success || userResult.data == null) {
        setState(() {
          _loading = false;
          _errorMessage = userResult.message;
        });
        return;
      }

      final user = userResult.data!;

      if (!mounted) return;

      setState(() {
        _user = user;
        _loading = false;
        _errorMessage = null;
      });
      _animCtrl.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Failed to load profile data.';
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const CustomBackButton(),
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _errorMessage != null
            ? _buildError()
            : _buildProfile(),
      ),
    );
  }

  // ── loading ────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const ScreenLoadingState(message: 'Loading profile...');
  }

  // ── error ──────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return ScreenErrorState(message: _errorMessage!, onRetry: _load);
  }

  // ── profile ────────────────────────────────────────────────────────────────

  Widget _buildProfile() {
    final user = _user!;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: _UserProfileDesktopLayout(
          user: user,
          onEdit: () {
            _handleEditProfile();
          },
          onChangePassword: () {
            Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
          },
          onLogout: () {
            _handleLogout();
          },
        ),
      ),
    );
  }

  Future<void> _handleEditProfile() async {
    if (_user == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          user: _user!,
          userService: _userService,
          onSave: () async {
            await _load();
          },
        ),
      ),
    );

    if (result ?? false) {
      await _load();
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await AppDialogs.showConfirm(
      context: context,
      title: 'Sign Out',
      content: 'Are you sure you want to log out?',
      confirmLabel: 'Logout',
      isDestructive: true,
    );

    if (!confirm) return;

    try {
      await widget.authService.logout();
      if (!mounted) return;

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }
}

class _UserProfileDesktopLayout extends StatelessWidget {
  const _UserProfileDesktopLayout({
    required this.user,
    required this.onEdit,
    required this.onChangePassword,
    required this.onLogout,
  });

  final UserDto user;
  final VoidCallback onEdit;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: UserProfileHeader(user: user)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: UserProfileCards(user: user)),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          if (user.roles.contains('Admin')) ...[
                            _ProfileSideCard(
                              title: 'Roles',
                              child: _UserProfileRolesSection(
                                roles: user.roles,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          _ProfileSideCard(
                            title: 'Account',
                            child: Column(
                              children: [
                                ActionTile(
                                  icon: Icons.edit_rounded,
                                  label: 'Edit Profile',
                                  onTap: onEdit,
                                ),
                                const SizedBox(height: 10),
                                ActionTile(
                                  icon: Icons.lock_outline_rounded,
                                  label: 'Change Password',
                                  onTap: onChangePassword,
                                ),
                                const SizedBox(height: 10),
                                ActionTile(
                                  icon: Icons.logout_rounded,
                                  label: 'Sign Out',
                                  destructive: true,
                                  onTap: onLogout,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSideCard extends StatelessWidget {
  const _ProfileSideCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _UserProfileRolesSection extends StatelessWidget {
  const _UserProfileRolesSection({required this.roles});

  final List<String> roles;

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: roles
          .map((role) => AppBadge(label: role.toRoleLabel()))
          .toList(),
    );
  }
}
