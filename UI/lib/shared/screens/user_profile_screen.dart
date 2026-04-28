import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/screens/edit_profile_screen.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/image_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/services/user_service.dart';
import 'package:tendergo/shared/models/dto/update_profile_request.dart';
import 'package:tendergo/admin/widgets/common/app_dialogs.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/shared/widgets/profile/user_profile_layouts.dart';
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
  static const double _desktopBreakpoint = 768;

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
      final tendersFuture =
          (currentUserId != null && currentUserId.isNotEmpty)
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
    final isDesktop = MediaQuery.of(context).size.width >= _desktopBreakpoint;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _errorMessage != null
            ? _buildError()
            : _buildProfile(isDesktop),
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

  Widget _buildProfile(bool isDesktop) {
    final user = _user!;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: isDesktop
            ? UserProfileDesktop(user: user)
            : UserProfileMobile(
                user: user,
                bids: _bids,
                tenders: _tenders,
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
            // Reload user data after edit
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
