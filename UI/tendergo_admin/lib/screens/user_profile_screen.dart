import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tendergo_admin/core/theme/app_theme.dart';
import 'package:tendergo_admin/models/dto/auth_dto.dart';
import 'package:tendergo_admin/routes/routes.dart';
import 'package:tendergo_admin/services/auth_service.dart';
import 'package:tendergo_admin/widgets/error_banner.widget.dart';




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

  // ── helpers ────────────────────────────────────────────────────────────────

  String _roleLabel(String role) =>
      role[0].toUpperCase() + role.substring(1).toLowerCase();

  // ── build ──────────────────────────────────────────────────────────────────

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
            SliverToBoxAdapter(child: _buildHeader(user)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildRolesSection(user.roles),
                  const SizedBox(height: 16),
                  _buildInfoCard(user),
                  if (user.address != null) ...[
                    const SizedBox(height: 16),
                    _buildAddressCard(user.address!),
                  ],
                
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

  // ── header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(UserDto user) {
  return Container(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(
        bottom: BorderSide(color: AppColors.outline, width: 1),
      ),
    ),
    child: Column(
      children: [
        // Top bar (Back button, Title, Edit)
        Row(
          children: [
            _IconBtn(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.maybePop(context),
            ),
            const Spacer(),
            Text(
              'Profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            _IconBtn(
              icon: Icons.edit_outlined,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 28),
        
        // Avatar section
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.infoSurface, 
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                UserDto.getInitials(user),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            // Online status indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surface,
                  width: 3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Name and Email
        Text(
          user.username,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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
                child: _RoleBadge(label: _roleLabel(r)),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── info card ──────────────────────────────────────────────────────────────

  Widget _buildInfoCard(UserDto user) {
    final firstName = user.firstName.trim();
    final lastName = user.lastName.trim();

    return _Card(
      title: 'Account Information',
      icon: Icons.person_outline_rounded,
      children: [
        _InfoRow(
        label: 'First Name',
        value: firstName.isEmpty ? '-' : firstName,
      ),
      _InfoRow(
        label: 'Last Name',
        value: lastName.isEmpty ? '-' : lastName,
      ),
        _InfoRow(label: 'Username', value: user.username),
        _InfoRow(label: 'Email', value: user.email),
      ],
    );
  }

  // ── address card ───────────────────────────────────────────────────────────

  Widget _buildAddressCard(AddressDto address) {
    return _Card(
      title: 'Address',
      icon: Icons.location_on_outlined,
      children: [
        if (address.street != null)
          _InfoRow(label: 'Street', value: address.street!),
        if (address.city != null)
          _InfoRow(label: 'City', value: address.city!),
        if (address.postalCode != null)
          _InfoRow(label: 'Postal Code', value: address.postalCode!),
        if (address.country != null)
          _InfoRow(label: 'Country', value: address.country!),
      ],
    );
  }

  // ── id card ────────────────────────────────────────────────────────────────

  Widget _buildIdCard(String id) {
    return _Card(
      title: 'System',
      icon: Icons.fingerprint_rounded,
      children: [
        _InfoRow(
          label: 'User ID',
          value: id,
          monospace: true,
          copyable: true,
        ),
      ],
    );
  }

  // ── actions ────────────────────────────────────────────────────────────────

  Widget _buildActions() {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.lock_outline_rounded,
          label: 'Change Password',
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
          },
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.logout_rounded,
          label: 'Sign Out',
          destructive: true,
          onTap: () => _handleLogout(),
        ),
      ],
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.authService.logout();
      if (!mounted) return;

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout failed. Please try again.'),
        ),
      );
    }
  }
}

// ─── Reusable components ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Card({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 15, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(
              height: 1, thickness: 1, color: AppColors.outline),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;
  final bool copyable;

  const _InfoRow({
    required this.label,
    required this.value,
    this.monospace = false,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(letterSpacing: 0.2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontFamily: monospace ? 'monospace' : null,
                letterSpacing: monospace ? 0.4 : 0,
              ),
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final isAdmin = label.toLowerCase() == 'admin';
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? AppColors.infoSurface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAdmin
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.outline,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: isAdmin ? AppColors.primary : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.textPrimary;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        splashColor: (destructive ? AppColors.error : AppColors.primary)
            .withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outline, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: AppColors.textSecondary),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.outline, width: 1),
        ),
        minimumSize: const Size(36, 36),
      ),
    );
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

