import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tendergo_admin/core/utils/string_extensions.dart';
import 'package:tendergo_admin/core/theme/app_theme.dart';
import 'package:tendergo_admin/models/dto/auth_dto.dart';
import 'package:tendergo_admin/routes/routes.dart';
import 'package:tendergo_admin/services/auth_service.dart';
import 'package:tendergo_admin/widgets/common/app_action_tile.dart';
import 'package:tendergo_admin/widgets/common/app_badge.dart';
import 'package:tendergo_admin/widgets/common/app_dialogs.dart';
import 'package:tendergo_admin/widgets/common/screen_state_widgets.dart';
import 'package:tendergo_admin/widgets/user_profile_cards.dart';
import 'package:tendergo_admin/widgets/user_profile_header.dart';




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

    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final result = await widget.authService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _user = result.data;
        _animCtrl.forward(from: 0);
      } else {
        _errorMessage = result.message;
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
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
    return ScreenErrorState(
      message: _errorMessage!,
      onRetry: _load,
    );
  }

  // ── profile ────────────────────────────────────────────────────────────────

  Widget _buildProfile() {
    final user = _user!;
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: UserProfileHeader(
                user: user,
                onBack: () => Navigator.pop(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildRolesSection(user.roles),
                  const SizedBox(height: 16),
                  UserProfileCards(user: user),
                  const SizedBox(height: 32),
                  _buildActions(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── roles ──────────────────────────────────────────────────────────────────
  Widget _buildRolesSection(List<String> roles) {
    if (roles.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: roles
            .map((r) => AppBadge(label: r.toRoleLabel()))
            .toList(),
      ),
    );
  }

  // ── actions ────────────────────────────────────────────────────────────────

  Widget _buildActions() {
    return Column(
      children: [
        ActionTile(
          icon: Icons.lock_outline_rounded,
          label: 'Change Password',
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
          },
        ),
        const SizedBox(height: 10),
        ActionTile(
          icon: Icons.logout_rounded,
          label: 'Sign Out',
          destructive: true,
          onTap: () => _handleLogout(),
        ),
      ],
    );
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

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }
}

