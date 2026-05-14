import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/mobile/screens/tender_post_screen.dart';
import 'package:tendergo/mobile/screens/tender_details_screen.dart';
import 'package:tendergo/shared/screens/user_profile_screen.dart';
import 'package:tendergo/mobile/screens/tenders_list_screen.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/providers/notification_provider.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/common/notification_bell_widget.dart';

class MobileTenderShellScreen extends StatefulWidget {
  const MobileTenderShellScreen({
    super.key,
    required this.tenderService,
    required this.authService,
  });

  final TenderService tenderService;
  final AuthService authService;

  @override
  State<MobileTenderShellScreen> createState() => _MobileTenderShellScreenState();
}

class _MobileTenderShellScreenState extends State<MobileTenderShellScreen> {
  int _listVersion = 0;
  NotificationProvider? _notificationProvider;

  @override
  void initState() {
    super.initState();
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

  Future<void> _openPostTender() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const MobileTenderPostScreen(),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _listVersion++;
      });
    }
  }

  void _openTenderDetails(int tenderId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileTenderDetailsScreen(
          tenderService: widget.tenderService,
          tenderId: tenderId,
        ),
      ),
    );
  }

  void _openUserProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(authService: widget.authService),
      ),
    );
  }

  void _openRecommendations() {
    Navigator.of(context).pushNamed(AppRoutes.recommendations);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'TenderGo',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          const NotificationBell(iconColor: AppColors.textPrimary),
          IconButton(
            onPressed: _openRecommendations,
            icon: const Icon(Icons.recommend_outlined),
            color: AppColors.textPrimary,
            tooltip: 'For You',
          ),
          IconButton(
            onPressed: _openUserProfile,
            icon: const Icon(Icons.person_outline_rounded),
            color: AppColors.textPrimary,
            tooltip: 'Profile',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE5E3DC)),
        ),
      ),
      body: MobileTenderListScreen(
        key: ValueKey(_listVersion),
        tenderService: widget.tenderService,
        embedded: true,
        onTenderSelected: _openTenderDetails,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPostTender,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post'),
      ),
    );
  }
}



