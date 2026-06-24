import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/admin/admin-panel-v2/screens/admin_categories_panel.dart';
import 'package:tendergo/admin/admin-panel-v2/screens/admin_layout.dart';
import 'package:tendergo/admin/admin-panel-v2/screens/login_screen.dart';

// Screens / Ekran uvozi
import 'package:tendergo/admin/screens/admin_report_preview_screen.dart';
import 'package:tendergo/admin/screens/forgot_password_screen.dart';
import 'package:tendergo/admin/screens/reset_passsword.screen.dart';

// Providers uvozi
import 'package:tendergo/shared/providers/admin_provider.dart';

// Services uvozi
import 'package:tendergo/shared/services/admin_service.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/location_service.dart';

import '../admin-panel-v2/screens/admin_layout.dart';

class AppRoutes {
  // Navigator Key za globalni pristup bez konteksta
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Nazivi ruta (Konstante)
  static const String splash = '/splash';
  static const String login = '/login';
  static const String loginV2 = '/login-v2';
  static const String registration = '/registration';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String tenderList = '/tenders';
  static const String tenderPost = '/tender-post';
  static const String tenderDetails = '/tender-details';
  static const String userProfile = '/user-profile';
  static const String editProfile = '/edit-profile';
  static const String myTenders = '/my-tenders';
  static const String myBids = '/my-bids';
  static const String admin = '/admin';
  static const String userPublicProfile = '/user-public-profile';
  static const String rateUser = '/rate-user';
  static const String recommendations = '/recommendations';
  static const String notifications = '/notifications';
  static const String pdfViewer = '/pdf-viewer';
  static const String bookmarkedTenders = '/bookmarked-tenders';
  static const String mainAdminLayout = '/main-admin';
  static const String adminCategories = '/admin-categories';
  static const String adminLocations = '/admin-locations';
  static const String adminUsers = '/admin-users';
  static const String adminTenders = '/admin-tenders';
  static const String adminReports = '/admin-reports';
  static const String adminDashboard = '/admin-dashboard';

  // Metoda koja generiše mapu ruta sa proslijeđenim servisima
  static Map<String, WidgetBuilder> getRoutes({
    required AuthService authService,
    required AdminService adminService,
    required CategoryService categoryService,
    required LocationService locationService,

  }) {
    return {
      AppRoutes.forgotPassword: (context) => const AdminForgotPasswordScreen(),
      AppRoutes.resetPassword: (context) => const AdminResetPasswordScreen(),

  


      AppRoutes.pdfViewer: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final Uint8List pdfBytes = args?['pdfBytes'] ?? Uint8List(0);
        final String title = args?['title'] ?? 'Pregled izvještaja';

        return AdminReportPreviewScreen(pdfBytes: pdfBytes, title: title);
      },

      AppRoutes.loginV2: (context) => const AdminLoginScreenV2(),
      AppRoutes.mainAdminLayout: (context) =>
    const MainAdminLayout(),
    AppRoutes.adminCategories: (context) =>const AdminCategoriesPanel(),
    };
  }
}
