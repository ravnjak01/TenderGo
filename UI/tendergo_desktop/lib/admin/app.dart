import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/admin/routes/nav_observer.dart';
import 'package:tendergo/admin/routes/routes.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';

// Services uvozi
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/location_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/admin_service.dart';

class AdminApp extends StatelessWidget {
  final AuthService authService;
  final AdminService adminService;
  final TenderService tenderService;
  final bool isLoggedIn;
  final CategoryService categoryService;
  final LocationService locationService;

  const AdminApp({
    super.key,
    required this.authService,
    required this.adminService,
    required this.tenderService,
    required this.isLoggedIn,
    required this.categoryService,
    required this.locationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TenderService>.value(value: tenderService),
        ChangeNotifierProvider(
          create: (_) => TenderProvider(tenderService, categoryService),
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
       
        
      ],
      child: MaterialApp(
        initialRoute: AppRoutes.login,
        navigatorKey: AppRoutes.navigatorKey,
        navigatorObservers: [routeObserver],

        routes: AppRoutes.getRoutes(
          authService: authService,
          adminService: adminService,
          categoryService: categoryService,
          locationService: locationService,
        ),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
      ),
    );
  }
}
