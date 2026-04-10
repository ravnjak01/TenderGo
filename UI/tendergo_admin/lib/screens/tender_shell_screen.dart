import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo_admin/core/theme/app_theme.dart';
import 'package:tendergo_admin/models/dto/auth_dto.dart';
import 'package:tendergo_admin/providers/tender_provider.dart';
import 'package:tendergo_admin/routes/routes.dart';
import 'package:tendergo_admin/screens/tender_details_screen.dart';
import 'package:tendergo_admin/screens/tender_post_screen.dart';
import 'package:tendergo_admin/screens/tenders_list_screen.dart';
import 'package:tendergo_admin/screens/user_profile_screen.dart';
import 'package:tendergo_admin/services/auth_service.dart';
import 'package:tendergo_admin/services/tender_service.dart';

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

@override
  void initState() {
    super.initState();
    _loadUser(); // Učitaj korisnika pri pokretanju
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
              icon: const Icon(
                Icons.home_outlined,
                size: 20,
                color: Colors.black87,
              ),
              label: const Text(
                'Home',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('+ Post a tender'),
                ),
                const SizedBox(width: 16),
                InkWell(
                 onTap: _openUserProfile,
                  mouseCursor: SystemMouseCursors.click,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.infoSurface, // Tvoja svijetlo plava iz teme
                      shape: BoxShape.circle,
                  ),
                  child:  Center(
                    child: Text(
                      _currentUser != null 
                        ? UserDto.getInitials(_currentUser!) 
                      : '',
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
      ),
      body: _selectedTenderId == null
          ? TenderListScreen(
              tenderService: widget.tenderService,
              embedded: true,
              onTenderSelected: (id) {
                setState(() {
                  _selectedTenderId = id;
                });
              },
            )
          : TenderDetailsScreen(
              tenderService: widget.tenderService,
              tenderId: _selectedTenderId,
              embedded: true,
            ),
    );
  }
}
