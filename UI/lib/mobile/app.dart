import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/mobile/routes/routes.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';

class MobileApp extends StatelessWidget {
  final AuthService authService;
  final TenderService tenderService;

  const MobileApp({
    super.key,
    required this.authService,
    required this.tenderService,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(authService),
      child: MaterialApp(
        title: 'TenderGo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Device Preview hooks
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        initialRoute: AppRoutes.login,
        routes: MobileRoutes.getRoutes(
          authService: authService,
          tenderService: tenderService,
        ),
      ),
    );
  }
}