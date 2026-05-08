import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/auth_dto.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/providers/notification_provider.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';
import 'package:tendergo/admin/screens/tender_details_screen.dart';
import 'package:tendergo/admin/screens/tender_post_screen.dart';
import 'package:tendergo/admin/screens/tenders_list_screen.dart';
import 'package:tendergo/admin/screens/user_profile_screen.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/screens/user_profile_screen.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/common/notification_bell_widget.dart';

class TenderShellScreen extends StatefulWidget {
  final TenderService tenderService;
  final AuthService authService;
  const TenderShellScreen({
    super.key,
    required this.tenderService,
    required this.authService,
  });

  @override
  State<TenderShellScreen> createState() => _TenderShellScreenState();
}

class _TenderShellScreenState extends State<TenderShellScreen> {
  int? _selectedTenderId;
  UserDto? _currentUser;
  NotificationProvider? _notificationProvider;

  bool get _isAdmin {
    final roles = _currentUser?.roles ?? const <String>[];
    return roles.any((role) => role.toLowerCase() == 'admin');
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notificationProvider = context.read<NotificationProvider>();
      _notificationProvider!.startPolling();
    });
  }

  @override
  void dispose() {
    _notificationProvider?.stopPolling();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final result = await widget.authService.getCurrentUser();
    if (result.success && mounted) {
      setState(() {
        _currentUser = result.data;
      });
    }
  }

  void _openTenderListFromTopBar() {
    setState(() {
      _selectedTenderId = null;
    });
  }

  void _openUserProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(authService: widget.authService),
      ),
    );
  }

  void _openMyTenders() {
    Navigator.of(context).pushNamed(AppRoutes.myTenders);
  }

  void _openMyBids() {
    Navigator.of(context).pushNamed(AppRoutes.myBids);
  }

  void _openAdmin() {
    Navigator.of(context).pushNamed(AppRoutes.admin);
  }

  void _openRecommendations() {
    Navigator.of(context).pushNamed(AppRoutes.recommendations);
  }

  Future<void> _openPostTender() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TenderPostScreen(tenderService: widget.tenderService),
      ),
    );

    if (result == true && mounted) {
      await context.read<TenderProvider>().fetchActiveTenders();
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          InkWell(
            onTap: _openTenderListFromTopBar,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'TenderGo',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          TextButton.icon(
            onPressed: _openTenderListFromTopBar,
            icon: const Icon(Icons.home_outlined, size: 20, color: Colors.black87),
            label: const Text(
              'Home',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w400),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _openMyTenders,
            icon: const Icon(
              Icons.assignment_outlined,
              size: 20,
              color: Colors.black87,
            ),
            label: const Text(
              'My Tenders',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w400),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _openMyBids,
            icon: const Icon(
              Icons.assignment_outlined,
              size: 20,
              color: Colors.black87,
            ),
            label: const Text(
              'My Bids',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w400),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _openRecommendations,
            icon: const Icon(
              Icons.recommend_outlined,
              size: 20,
              color: Colors.black87,
            ),
            label: const Text(
              'For You',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w400),
            ),
          ),
          if (_isAdmin) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _openAdmin,
              icon: const Icon(
                Icons.admin_panel_settings_outlined,
                size: 20,
                color: Colors.black87,
              ),
              label: const Text(
                'Admin',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w400),
              ),
            ),
          ],
          if (_selectedTenderId != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedTenderId = null;
                });
              },
              child: const Text('Tenders'),
            ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: _openPostTender,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF185FA5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text('+ Post a tender'),
              ),
              const SizedBox(width: 16),
              NotificationBell(iconColor: Colors.black87),
              InkWell(
                onTap: _openUserProfile,
                mouseCursor: SystemMouseCursors.click,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.infoSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _currentUser != null ? UserDto.getInitials(_currentUser!) : '',
                      style: TextStyle(
                        color: Color(0xFF185FA5),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: const Color(0xFFE5E3DC)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _selectedTenderId == null
          ? AdminTenderListScreen(
              tenderService: widget.tenderService,
              embedded: true,
              onTenderSelected: (id) {
                setState(() {
                  _selectedTenderId = id;
                });
              },
            )
          : AdminTenderDetailsScreen(
              tenderService: widget.tenderService,
              tenderId: _selectedTenderId,
              embedded: true,
            ),
    );
  }
}
