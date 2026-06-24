import 'package:flutter/material.dart';
import 'package:tendergo/admin/app.dart';
import 'package:tendergo/shared/services/admin_service.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/image_service.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/location_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dio = DioClient.getDio();
  final authService = AuthService(dio);
  final adminService = AdminService(dio);
  final imageService = ImageService(dio);
  final categoryService = CategoryService(dio);
  final locationService = LocationService(dio);
  final tenderService = TenderService(dio, imageService);

  final bool isLoggedIn = await AuthService.isLoggedIn();

  runApp(
    AdminApp(
      isLoggedIn: isLoggedIn,
      authService: authService,
      adminService: adminService,
      imageService: imageService,
      categoryService: categoryService,
      locationService: locationService,
      tenderService: tenderService,
    ),
  );
}