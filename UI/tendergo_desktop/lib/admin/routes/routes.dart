import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:tendergo/admin/screens/admin_categories_panel.dart';
import 'package:tendergo/admin/screens/admin_layout.dart';
import 'package:tendergo/admin/screens/login_screen.dart';

import 'package:tendergo/admin/screens/admin_report_preview_screen.dart';



import 'package:tendergo/shared/services/admin_service.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/location_service.dart';


class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Nazivi ruta (Konstante)
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String myTenders = '/my-tenders';
  static const String myBids = '/my-bids';
  static const String pdfViewer = '/pdf-viewer';
  static const String mainAdminLayout = '/main-admin';
  static const String adminCategories = '/admin-categories';
  static const String adminLocations = '/admin-locations';
  static const String adminUsers = '/admin-users';
  static const String adminTenders = '/admin-tenders';
  static const String adminReports = '/admin-reports';
  static const String adminDashboard = '/admin-dashboard';

  static Map<String, WidgetBuilder> getRoutes({
    required AuthService authService,
    required AdminService adminService,
    required CategoryService categoryService,
    required LocationService locationService,

  }) {
    return {
   
      AppRoutes.pdfViewer: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final Uint8List pdfBytes = args?['pdfBytes'] ?? Uint8List(0);
        final String title = args?['title'] ?? 'Pregled izvještaja';

        return AdminReportPreviewScreen(pdfBytes: pdfBytes, title: title);
      },

      AppRoutes.login: (context) => const AdminLoginScreen(),
      AppRoutes.mainAdminLayout: (context) =>
    const MainAdminLayout(),
    AppRoutes.adminCategories: (context) =>const AdminCategoriesPanel(),
    };
  }
}
