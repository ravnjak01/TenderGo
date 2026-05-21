import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/mobile/routes/routes.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/providers/notification_provider.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/notification_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/services/user_service.dart';

class MobileApp extends StatelessWidget {
  final AuthService authService;
  final BidService bidService;
  final TenderService tenderService;
  final UserService userService;
  final CategoryService categoryService;

  const MobileApp({
    super.key,
    required this.authService,
    required this.bidService,
    required this.tenderService,
    required this.userService,
    required this.categoryService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(
          create: (_) => TenderProvider(
            tenderService,
            categoryService,
          ),
        ),
        //ChangeNotifierProvider(
          //create: (_) =>
           //   NotificationProvider(NotificationService(DioClient.getDio())),
       // ),
      ],
      child: MaterialApp(
        title: 'TenderGo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Device Preview hooks
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        initialRoute: AppRoutes.login,
        navigatorKey: AppRoutes.navigatorKey,
        routes: MobileRoutes.getRoutes(
          authService: authService,
          bidService: bidService,
          tenderService: tenderService,
          userService: userService,
          categoryService: categoryService,
        ),
      ),
    );
  }
}