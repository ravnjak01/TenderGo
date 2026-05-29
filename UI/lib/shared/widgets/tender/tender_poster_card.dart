import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/address_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart'; // Ako zatreba za avatar
import 'package:tendergo/shared/models/dto/user_public_dto.dart'; // Tvoj javni DTO
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/services/user_service.dart'; // Tvoj servis
import 'package:tendergo/shared/widgets/common/user_avatar_widget.dart';
import 'package:tendergo/shared/widgets/tender/tender_section_label.dart';

class TenderPosterCard extends StatefulWidget {
  const TenderPosterCard({
    super.key,
    required this.tender,
  });

  final TenderDto tender;

  @override
  State<TenderPosterCard> createState() => _TenderPosterCardState();
}

class _TenderPosterCardState extends State<TenderPosterCard> {
  late final UserService _userService;
  Future<UserPublicDto>? _userFuture;

  @override
  void initState() {
    super.initState();
    // Inicijalizacija servisa (proslijedi Dio instancu koju koristiš u aplikaciji)
    // Ako koristiš GetIt / locator, zamijeni sa: locator<Dio>() ili locator<UserService>()
    _userService = UserService(Dio()); 

    final userId = widget.tender.createdByUserId.trim();
    if (userId.isNotEmpty) {
      // Pozivamo tvoju metodu sa servisa
      _userFuture = _userService.getUser(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.tender.createdByUserId.trim();

    // Priprema inicijala iz imena za prvu ruku dok se slika učitava
    final nameParts = widget.tender.createdByFullname.trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Dummy korisnik kojeg prikazujemo dok API ne vrati pravi odgovor
    final fallbackUser = UserDto(
      id: widget.tender.createdByUserId,
      firstName: firstName,
      lastName: lastName,
      email: '',
      username: '',
      profileImageUrl: null, 
      roles: const [],
      isBanned: false,
      address:  AddressDto(id: 0, city: '', country: '', street: '', postalCode: ''),
    );


//nije popravljeno 
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TenderSectionLabel(
            icon: Icons.person_outline,
            label: 'Posted By',
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _navigateToProfile(context, userId),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    // FutureBuilder koji sada sluša UserPublicDto
                    FutureBuilder<UserPublicDto>(
                      future: _userFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final publicUser = snapshot.data!;
                          
                          final userForAvatar = UserDto(
                            id: userId,
                            firstName: publicUser.firstName ,
                            lastName: publicUser.lastName ,
                            email: '',
                            username: '',
                            profileImageUrl: publicUser.profileImageUrl, // Ovdje je tvoja slika sa backenda!
                            roles: const [],
                            isBanned: false,
                            address:  AddressDto(id: 0, city: '', country: '', street: '', postalCode: ''),
                          );

                          return UserAvatarWidget(
                            user: userForAvatar,
                            size: 40,
                            onTap: () => _navigateToProfile(context, userId),
                          );
                        }

                        // Ako je loading ili greška, prikaži fallback sa inicijalima
                        return UserAvatarWidget(
                          user: fallbackUser,
                          size: 40,
                          onTap: () => _navigateToProfile(context, userId),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tender.createdByFullname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'View Profile',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile(BuildContext context, String userId) {
    if (userId.isEmpty) return;
    Navigator.of(context).pushNamed(
      AppRoutes.userPublicProfile,
      arguments: userId,
    );
  }
}