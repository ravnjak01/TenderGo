import 'package:tendergo/shared/models/dto/auth_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/services/admin_service.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';

class AdminProvider {
   final AdminService adminService;
  final TenderService tenderService;
  final AuthService authService;

  AdminProvider({
    required this.adminService,
    required this.tenderService,
    required this.authService,
  });


   List<TenderDto> allTenders = [];
  List<UserDto> users = [];

//admin provider jos nije implementiran, ali ce se koristiti za dohvatanje svih tendera i korisnika, te za banovanje korisnika i brisanje tendera
  Future<void> loadAdminData() async {
    try {
      final usersResult = await adminService.getAllUsers();
      if (usersResult.success) {
        users = (usersResult.data as List)
            .map((u) => UserDto.fromJson(u as Map<String, dynamic>))
            .toList();
      }

      allTenders = await tenderService.getAll(page: 1, pageSize: 100);
    } catch (e) {
      // Handle errors if needed
    }
  }
}