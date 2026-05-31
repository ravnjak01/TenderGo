import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/mobile/routes/routes.dart';
import 'package:tendergo/mobile/widgets/common/app_action_tile.dart';
import 'package:tendergo/mobile/widgets/common/app_badge.dart';
import 'package:tendergo/mobile/widgets/common/app_dialogs.dart';
import 'package:tendergo/mobile/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/mobile/widgets/profile/user_profile_cards.dart';
import 'package:tendergo/mobile/widgets/profile/user_profile_header.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/core/utils/extensions/string_extensions.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/mobile/screens/edit_profile_screen.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/image_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/services/user_service.dart';

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
  late BidService _bidService;
  late TenderService _tenderService;
  late UserService _userService;

  UserDto? _user;
  List<BidDto> _bids = const [];
  List<TenderDto> _tenders = const [];
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
    _bidService = BidService(dio);
    _tenderService = TenderService(dio, ImageService(dio));
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
      final currentUserId = await AuthService.getCurrentUserId();

      List<BidDto> bids = const [];
      List<TenderDto> tenders = const [];

      final bidsFuture = _bidService.getMyBids(page: 1, pageSize: 100);
      final tendersFuture = (currentUserId != null && currentUserId.isNotEmpty)
          ? _tenderService.getByUser(currentUserId)
          : Future.value(const <dynamic>[]);

      final results = await Future.wait<dynamic>([
        bidsFuture,
        tendersFuture,
      ]);

      bids = results[0] as List<BidDto>;

      tenders = (results[1] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(TenderDto.fromJson)
          .toList(growable: false);

      if (!mounted) return;

      setState(() {
        _user = user;
        _bids = bids;
        _tenders = tenders;
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
            ? const ScreenLoadingState(message: 'Loading profile...')
            : _errorMessage != null
                ? ScreenErrorState(message: _errorMessage!, onRetry: _load)
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _buildMobileContent(),
                    ),
                  ),
      ),
    );
  }

  Widget _buildMobileContent() {
    final user = _user!;

    return CustomScrollView(
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
              if (user.roles.contains('Admin')) ...[
                _UserProfileRolesSection(roles: user.roles),
                const SizedBox(height: 5),
              ],
              const SizedBox(height: 16),
              UserProfileCards(user: user),
              const SizedBox(height: 16),
              _UserProfileStatsCard(
                bidsCount: _bids.length,
                tendersCount: _tenders.length,
                onBidsTap: () => Navigator.of(context).pushNamed(AppRoutes.myBids),
                onTendersTap: () => Navigator.of(context).pushNamed(AppRoutes.myTenders),
              ),
              const SizedBox(height: 32),
              ActionTile(
                icon: Icons.edit_rounded,
                label: 'Edit Profile',
                onTap: _handleEditProfile,
              ),
              const SizedBox(height: 10),
              ActionTile(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
              ),
              const SizedBox(height: 10),
              ActionTile(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                destructive: true,
                onTap: _handleLogout,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _handleEditProfile() async {
    if (_user == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          user: _user!,
          userService: _userService,
          onSave: () async => await _load(),
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

      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }
}

// ── Privatni pomoćni widgeti koji pripadaju mobilnom prikazu ─────────────────

class _UserProfileRolesSection extends StatelessWidget {
  const _UserProfileRolesSection({required this.roles});

  final List<String> roles;

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: roles.map((r) => AppBadge(label: r.toRoleLabel())).toList(),
      ),
    );
  }
}

class _UserProfileStatsCard extends StatelessWidget {
  const _UserProfileStatsCard({
    required this.bidsCount,
    required this.tendersCount,
    this.onBidsTap,
    this.onTendersTap,
  });

  final int bidsCount;
  final int tendersCount;
  final VoidCallback? onBidsTap;
  final VoidCallback? onTendersTap;

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
        child: Row(
          children: [
            Expanded(
              child: _UserProfileStatTile(
                icon: Icons.gavel_rounded,
                label: 'My Bids',
                value: bidsCount.toString(),
                onTap: onBidsTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UserProfileStatTile(
                icon: Icons.assignment_outlined,
                label: 'My Tenders',
                value: tendersCount.toString(),
                onTap: onTendersTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserProfileStatTile extends StatelessWidget {
  const _UserProfileStatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: onTap != null ? AppColors.primary : AppColors.outline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const Spacer(),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (onTap != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Click for more',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}