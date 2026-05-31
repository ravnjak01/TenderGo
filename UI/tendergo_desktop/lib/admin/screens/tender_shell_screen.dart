import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/admin/screens/admin_screen.dart';
import 'package:tendergo/admin/screens/mybids_screen.dart';
import 'package:tendergo/admin/screens/mytenders_screen.dart';
import 'package:tendergo/admin/screens/recommend_screen.dart';
import 'package:tendergo/admin/screens/user_profile_screen.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/providers/admin_provider.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';
import 'package:tendergo/admin/screens/tender_details_screen.dart';
import 'package:tendergo/admin/screens/tender_post_screen.dart';
import 'package:tendergo/admin/screens/tenders_list_screen.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/location_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/common/notification_bell_widget.dart';
import 'package:tendergo/shared/widgets/common/user_avatar_widget.dart';

// Definisanje tipova ekrana unutar ljuske (Shell-a)
enum ShellTab { home, myTenders, myBids, forYou, admin, tenderDetails }

class TenderShellScreen extends StatefulWidget {
  final TenderService tenderService;
  final AuthService authService;
  final LocationService locationService;
  final BidService bidService;

  const TenderShellScreen({
    super.key,
    required this.tenderService,
    required this.authService,
    required this.locationService,
    required this.bidService,
  });

  @override
  State<TenderShellScreen> createState() => _TenderShellScreenState();
}

class _TenderShellScreenState extends State<TenderShellScreen> {
  ShellTab _currentTab = ShellTab.home;
  int? _selectedTenderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUser();
    });
  }

  // ISPRAVLJENO: Navigacija sada mijenja stanje unutar istog ekrana (nema Navigator.push-a koji skriva meni)
  void _changeTab(ShellTab tab, {int? tenderId}) {
    setState(() {
      _currentTab = tab;
      _selectedTenderId = tenderId;
    });
  }

  void _goHome() {
    _changeTab(ShellTab.home);
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

  Widget _buildNavigationButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        // Vizuelni indikator aktivnog taba na desktopu
        backgroundColor: isActive
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: Icon(
        icon,
        size: 20,
        color: isActive ? theme.colorScheme.primary : Colors.black87,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isActive ? theme.colorScheme.primary : Colors.black87,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 16),
          _buildNavigationButton(
            icon: Icons.home_outlined,
            label: 'Home',
            isActive: _currentTab == ShellTab.home,
            onPressed: () => _changeTab(ShellTab.home),
          ),
          const SizedBox(width: 4),
          _buildNavigationButton(
            icon: Icons.assignment_outlined,
            label: 'My Tenders',
            isActive: _currentTab == ShellTab.myTenders,
            onPressed: () => _changeTab(ShellTab.myTenders),
          ),
          const SizedBox(width: 4),
          _buildNavigationButton(
            icon: Icons
                .gavel_outlined, // Prikladnija ikona za ponude/bids od assignment
            label: 'My Bids',
            isActive: _currentTab == ShellTab.myBids,
            onPressed: () => _changeTab(ShellTab.myBids),
          ),
          const SizedBox(width: 4),
          _buildNavigationButton(
            icon: Icons.recommend_outlined,
            label: 'For You',
            isActive: _currentTab == ShellTab.forYou,
            onPressed: () => _changeTab(ShellTab.forYou),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 4),
            _buildNavigationButton(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Admin',
              isActive: _currentTab == ShellTab.admin,
              onPressed: () => _changeTab(ShellTab.admin),
            ),
          ],
        ],
      ),
    );
  }

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
          onTap: () {
            // Profil se može otvoriti preko Navigatora jer je to izolovan podesni ekran
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    UserProfileScreen(authService: widget.authService),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return InkWell(
      onTap: () => _changeTab(ShellTab.home),
      borderRadius: BorderRadius.circular(6),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // ISPRAVLJENO: Spriječen raspad layouta. Na uskim ekranima gornji meni se pretvara u skrolujući ili se može sakriti
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final showFullMenu = constraints.maxWidth > 800;
            return Row(
              children: [
                _buildLogo(),
                if (showFullMenu)
                  Expanded(child: _buildNavigationBar())
                else
                  const Spacer(),
                _buildActionsRow(),
              ],
            );
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE5E3DC)),
        ),
      ),
      // Bočni meni (Drawer) se aktivira samo ako se ekran smanji (opcionalno, za potpunu responzivnost)
      body: _buildSelectedScreen(),
    );
  }

  // ISPRAVLJENO: Centralizovano renderovanje sadržaja na osnovu odabranog taba
  // ISPRAVLJENO: Renderovanje stvarnih ekrana sa proslijeđenim servisima i podacima
  Widget _buildSelectedScreen() {
    switch (_currentTab) {
      case ShellTab.home:
        return AdminTenderListScreen(
          tenderService: widget.tenderService,
          embedded: true,
          onTenderSelected: (id) =>
              _changeTab(ShellTab.tenderDetails, tenderId: id),
        );
      case ShellTab.tenderDetails:
        return AdminTenderDetailsScreen(
          tenderService: widget.tenderService,
          tenderId: _selectedTenderId,
          embedded: true,
          onBack: _goHome,
        );
      case ShellTab.myTenders:
        // Ovdje uvoziš tvoj stvarni ekran za korisnikove tendere
        // Ako koristiš isti spisak ali filtriran, proslijedi mu parametre kroz konstruktor
        return MyTendersScreen(
          tenderService: widget.tenderService,
          onBack: _goHome,
          // locationService: widget.locationService, // otkomentariši ako ekran ovo traži
        );
      case ShellTab.myBids:
        // Učitavanje stvarnog ekrana sa ponudama korisnika
        return MyBidsScreen(bidService: widget.bidService, onBack: _goHome);
      case ShellTab.forYou:
        // Učitavanje ekrana za preporuke (Recommendations)
        return RecommendedForYouDesktopScreen(onBack: _goHome);
      case ShellTab.admin:
        // Učitavanje administratorskog panela
        return AdminScreen(
          provider: context
              .read<
                AdminProvider
              >(), // Ili AuthProvider, zavisno šta taj ekran tačno traži
          onBack: _goHome,
        );
    }
  }
}
