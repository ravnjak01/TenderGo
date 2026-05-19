import 'package:tendergo/shared/models/dto/admin_dto.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/models/dto/location_dto.dart';
import 'package:tendergo/shared/models/requests/location_filter_request.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/requests/location_insert_request.dart';
import 'package:tendergo/shared/models/requests/location_update_request.dart';
import 'package:tendergo/shared/models/ui/auth_result.dart';
import 'package:tendergo/shared/services/admin_service.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/location_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';

class AdminProvider {
  final AdminService adminService;
  final TenderService tenderService;
  final AuthService authService;
  final CategoryService categoryService;
  final LocationService locationService;

  AdminProvider({
    required this.adminService,
    required this.tenderService,
    required this.authService,
    required this.categoryService,
    required this.locationService,
  });

  Future<AuthResult> getCurrentUser() => authService.getCurrentUser();

  Future<AuthResult> getAllUsers() => adminService.getAllUsers();

  Future<List<TenderDto>> getAllTenders() =>
      tenderService.getAll(page: 1, pageSize: 100);

  Future<List<TenderDto>> getActiveTenders() => tenderService.getActive();

  Future<List<TenderDto>> getClosedTenders() => tenderService.getClosed();

  Future<List<CategoryDto>> getCategories() => categoryService.getAll();

  Future<AuthResult> deleteTender(int id) => adminService.deleteTender(id);

  Future<AuthResult> banUser(String id, BanRequest request) =>
      adminService.banUser(id, request);

  Future<AuthResult> unbanUser(String id) => adminService.unbanUser(id);

  Future<CategoryDto> insertCategory(String name) =>
      categoryService.insert(CategoryDto(id: 0, name: name));

  Future<void> updateCategory(int id, String name) =>
      categoryService.update(id, CategoryDto(id: id, name: name));

  Future<bool> deleteCategory(int id) => categoryService.delete(id);

  Future<List<LocationDto>> getLocations() =>
      locationService.getLocations(const LocationFilterRequest());

  Future<LocationDto> insertLocation(LocationInsertRequest request) =>
      locationService.insertLocation(
        request,
      );

  Future<bool> updateLocation(
    int id, LocationUpdateRequest request) =>
      locationService.updateLocation(id, request);

  Future<bool> deleteLocation(int id) => locationService.deleteLocation(id);
}