import 'package:flutter/material.dart';
import 'package:tendergo_admin/core/theme/app_theme.dart';
import 'package:tendergo_admin/providers/tender_provider.dart';
import 'package:tendergo_admin/routes/routes.dart';
import 'package:tendergo_admin/services/auth_service.dart';
import 'package:tendergo_admin/services/category_service.dart';
import 'package:tendergo_admin/services/dio_client.dart';
import 'package:tendergo_admin/services/image_service.dart';
import 'package:tendergo_admin/services/tender_service.dart';
import 'package:provider/provider.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dio = DioClient.getDio();
  final authService = AuthService(dio);
  final imageService = ImageService(dio);
  final tenderService = TenderService(dio, imageService);
  final categoryService = CategoryService(dio);

  final bool isLoggedIn = await AuthService.isLoggedIn();

  runApp(MyApp(
    isLoggedIn: isLoggedIn,
    authService: authService,
    tenderService: tenderService,
    categoryService: categoryService,
  ));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final TenderService tenderService;
  final bool isLoggedIn;
  final CategoryService categoryService;

  const MyApp({
    super.key,
    required this.authService,
    required this.tenderService,
    required this.isLoggedIn,
    required this.categoryService
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TenderProvider(tenderService, categoryService), 
      child: MaterialApp(
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.getRoutes(),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
      ),
    );
  }
}