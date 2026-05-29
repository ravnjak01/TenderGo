import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';
import 'package:tendergo/admin/screens/tender_details_screen.dart';
import 'package:tendergo/admin/screens/tender_post_screen.dart';
import 'package:tendergo/admin/screens/tenders_list_screen.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/screens/user_profile_screen.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/location_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/common/notification_bell_widget.dart';
import 'package:tendergo/shared/widgets/common/user_avatar_widget.dart';

class TenderShellScreen extends StatefulWidget {
  final TenderService tenderService;
  final AuthService authService;
  final LocationService locationService;

  const TenderShellScreen({
    super.key,
    required this.tenderService,
    required this.authService,
    required this.locationService,
  });

  @override
  State<TenderShellScreen> createState() => _TenderShellScreenState();
}

class _TenderShellScreenState extends State<TenderShellScreen> {
  int? _selectedTenderId;

  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUser();
    });
  }

  @override
  void dispose() {
    super.dispose();
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
        builder: (_) => TenderPostScreen(
          tenderService: widget.tenderService,
          locationService: widget.locationService,
        ),
      ),
    );

    if (result == true && mounted) {
      await context.read<TenderProvider>().fetchActiveTenders();
    }
  }

  /// Build a navigation button for the top bar.
  Widget _buildNavigationButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: Colors.black87),
      label: Text(
        label,
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w400),
      ),
    );
  }



  /// Build the main navigation bar with all menu items.
  Widget _buildNavigationBar() {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return Row(
      children: [
        const SizedBox(width: 24),
        _buildNavigationButton(
          icon: Icons.home_outlined,
          label: 'Home',
          onPressed: _openTenderListFromTopBar,
        ),
        const SizedBox(width: 8),
        _buildNavigationButton(
          icon: Icons.assignment_outlined,
          label: 'My Tenders',
          onPressed: _openMyTenders,
        ),
        const SizedBox(width: 8),
        _buildNavigationButton(
          icon: Icons.assignment_outlined,
          label: 'My Bids',
          onPressed: _openMyBids,
        ),
        const SizedBox(width: 8),
        _buildNavigationButton(
          icon: Icons.recommend_outlined,
          label: 'For You',
          onPressed: _openRecommendations,
        ),
        if (isAdmin) ...[
          const SizedBox(width: 8),
          _buildNavigationButton(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Admin',
            onPressed: _openAdmin,
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
      ],
    );
  }

  /// Build the action buttons row (post tender, notifications, profile).
  Widget _buildActionsRow() {
    final userFromProvider = context.watch<AuthProvider>().currentUser;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: _openPostTender,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
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
        const SizedBox(width: 12),
        UserAvatarWidget(
          user: userFromProvider,
          onTap: _openUserProfile,
        ),
      ],
    );
  }

  /// Build the logo area.
  Widget _buildLogo() {
    return InkWell(
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
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          _buildLogo(),
          _buildNavigationBar(),
          const Spacer(),
          _buildActionsRow(),
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
