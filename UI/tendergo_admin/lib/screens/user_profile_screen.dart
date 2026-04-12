import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tendergo_admin/core/theme/app_theme.dart';
import 'package:tendergo_admin/core/utils/string_extensions.dart';
import 'package:tendergo_admin/models/dto/auth_dto.dart';
import 'package:tendergo_admin/routes/routes.dart';
import 'package:tendergo_admin/services/auth_service.dart';
import 'package:tendergo_admin/widgets/common/app_action_tile.dart';
import 'package:tendergo_admin/widgets/common/app_badge.dart';
import 'package:tendergo_admin/widgets/common/app_dialogs.dart';
import 'package:tendergo_admin/widgets/error_banner.widget.dart';
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.infoSurface,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading profile…',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ── error ──────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorBannerWidget(
              message: _errorMessage!,
              onClose: () {
                if (!mounted) return;
                setState(() {
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 28),
            _OutlinedButton(label: 'Retry', onTap: _load),
          ],
        ),
      ),
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
            SliverToBoxAdapter(child: UserProfileHeader(user: user,
            onBack: () => Navigator.pop(context),

            )),
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
      child: Row(
        children: roles
            .map(
              (r) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child:  AppBadge(label: r.toRoleLabel()),
              ),
            )
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
  // 1. Pozivamo helper klasu
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

  



class _OutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlinedButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text(label),
    );
  }
}

