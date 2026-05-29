import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/mobile/screens/tender_post_screen.dart';
import 'package:tendergo/mobile/screens/tender_details_screen.dart';
import 'package:tendergo/shared/screens/user_profile_screen.dart';
import 'package:tendergo/mobile/screens/tenders_list_screen.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/feedback/snackbar_helper.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().loadUser();
    });
  }

  Future<void> _openPostTender() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const MobileTenderPostScreen(),
      ),
    );

    if (result == true && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final provider = context.read<TenderProvider>();
        await provider.fetchActiveTenders(silent: true);
        if (!mounted) return;
        if (provider.error != null) {
          SnackbarHelper.show(
            context,
            'Tender posted, but list refresh failed.',
            isError: true,
          );
        }
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

 void _openBookmarkedTenders() {
  Navigator.of(context).pushNamed(AppRoutes.bookmarkedTenders).then((_) {
    if (mounted) {
      context.read<TenderProvider>().fetchActiveTenders(silent: true);
    }
  });
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
          IconButton(
            onPressed: _openBookmarkedTenders,
            icon: const Icon(Icons.favorite_outline_rounded),
            color: AppColors.textPrimary,
            tooltip: 'Sačuvani tenderi',
          ),

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



