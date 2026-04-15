import 'package:flutter/material.dart';
import 'package:tendergo_admin/core/theme/app_theme.dart';
import 'package:tendergo_admin/providers/tender_provider.dart';
import 'package:tendergo_admin/routes/routes.dart';
import 'package:tendergo_admin/services/auth_service.dart';
import 'package:tendergo_admin/services/admin_service.dart';
import 'package:tendergo_admin/services/bid_service.dart';
import 'package:tendergo_admin/services/category_service.dart';
import 'package:tendergo_admin/services/dio_client.dart';
import 'package:tendergo_admin/services/image_service.dart';
import 'package:tendergo_admin/services/tender_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dio = DioClient.getDio();
  final authService = AuthService(dio);
  final adminService = AdminService(dio);
  final bidService = BidService(dio);
  final imageService = ImageService(dio);
  final tenderService = TenderService(dio, imageService);
  final categoryService = CategoryService(dio);

  final bool isLoggedIn = await AuthService.isLoggedIn();

  runApp(
    MyApp(
      isLoggedIn: isLoggedIn,
      authService: authService,
      adminService: adminService,
      bidService: bidService,
      imageService: imageService,
      tenderService: tenderService,
      categoryService: categoryService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final AdminService adminService;
  final BidService bidService;
  final ImageService imageService;
  final TenderService tenderService;
  final bool isLoggedIn;
  final CategoryService categoryService;

  const MyApp({
    super.key,
    required this.authService,
    required this.adminService,
    required this.bidService,
    required this.imageService,
    required this.tenderService,
    required this.isLoggedIn,
    required this.categoryService,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TenderProvider(tenderService, categoryService),
      child: MaterialApp(
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.getRoutes(
          authService: authService,
          adminService: adminService,
          categoryService: categoryService,
          imageService: imageService,
          tenderService: tenderService,
          bidService: bidService,
        ),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
      ),
    );
  }
}
