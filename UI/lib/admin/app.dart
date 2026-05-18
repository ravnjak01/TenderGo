import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/admin/routes/routes.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/providers/notification_provider.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/location_service.dart';
import 'package:tendergo/shared/services/image_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';  
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/admin_service.dart';import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/notification_service.dart';import 'package:tendergo/shared/services/user_service.dart';
class AdminApp extends StatelessWidget {
  final AuthService authService;
  final AdminService adminService;
  final BidService bidService;
  final ImageService imageService;
  final TenderService tenderService;
  final UserService userService;
  final bool isLoggedIn;
  final CategoryService categoryService;
  final LocationService locationService;

  const AdminApp({
    super.key,
    required this.authService,
    required this.adminService,
    required this.bidService,
    required this.imageService,
    required this.tenderService,
    required this.userService,
    required this.isLoggedIn,
    required this.categoryService,
    required this.locationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TenderProvider(tenderService, categoryService),
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
       // ChangeNotifierProvider(
          //create: (_) =>
            //    NotificationProvider(NotificationService(DioClient.getDio())),
      //  ),
      ],
      child: MaterialApp(
        initialRoute: AppRoutes.splash,
        routes: AdminRoutes.getRoutes(
          authService: authService,
          adminService: adminService,
          categoryService: categoryService,
          locationService: locationService,
          imageService: imageService,
          tenderService: tenderService,
          bidService: bidService,
          userService: userService,
        ),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
      ),
    );
  }
}
