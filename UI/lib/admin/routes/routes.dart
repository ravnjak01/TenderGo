import 'package:flutter/material.dart';
import 'package:tendergo/admin/screens/admin_screen.dart';
import 'package:tendergo/admin/screens/forgot_password_screen.dart';
import 'package:tendergo/admin/screens/home_screen.dart';
import 'package:tendergo/admin/screens/login_screen.dart';
import 'package:tendergo/admin/screens/mybids_screen.dart';
import 'package:tendergo/admin/screens/mytenders_screen.dart';
import 'package:tendergo/admin/screens/registration_screen.dart';
import 'package:tendergo/admin/screens/reset_passsword.screen.dart';
import 'package:tendergo/admin/screens/splash_screen.dart';
import 'package:tendergo/admin/screens/tender_details_screen.dart';
import 'package:tendergo/admin/screens/tender_post_screen.dart';
import 'package:tendergo/admin/screens/tender_shell_screen.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/screens/rate_user_screen.dart';
import 'package:tendergo/shared/screens/user_profile_public_screen.dart';
import 'package:tendergo/shared/screens/user_profile_screen.dart';
import 'package:tendergo/shared/services/admin_service.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/image_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/services/user_service.dart';

class AdminRoutes {
  
  static Map<String, WidgetBuilder> getRoutes({
    required AuthService authService,
    required AdminService adminService,
    required CategoryService categoryService,
    required ImageService imageService,
    required TenderService tenderService,
    required BidService bidService,
    required UserService userService,

  }) {
    return {
      AppRoutes.splash: (context) => const SplashScreen(),
      AppRoutes.login: (context) => const AdminLoginScreen(),
      AppRoutes.registration: (context) => const AdminRegistrationScreen(),
      AppRoutes.forgotPassword: (context) =>  const AdminForgotPasswordScreen(),
      AppRoutes.resetPassword: (context) => const AdminResetPasswordScreen(),
      AppRoutes.tenderList: (context) => TenderShellScreen(
        tenderService: tenderService,
        authService: authService,
      ),
      AppRoutes.tenderPost: (context) => TenderPostScreen(tenderService: tenderService),
      AppRoutes.tenderDetails: (context) =>
          AdminTenderDetailsScreen(tenderService: tenderService),
      AppRoutes.userProfile: (context) => UserProfileScreen(authService: authService),
      AppRoutes.myTenders: (context) => MyTendersScreen(tenderService: tenderService),
      AppRoutes.myBids: (context) => MyBidsScreen(
        bidService: bidService,
        tenderService: tenderService,
      ),
      AppRoutes.admin: (context) => AdminScreen(
        adminService: adminService,
        authService: authService,
        tenderService: tenderService,
        categoryService: categoryService,
      ),
       AppRoutes.userPublicProfile: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final userId = switch (args) {
          String value => value,
          Map value =>
            (value['userId'] ?? value['id'] ?? '').toString(),
          _ => '',
        };

        return UserProfilePublicScreen(userId: userId, userService: userService);
      },
      AppRoutes.rateUser: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final tenderId = args is Map ? (args['tenderId'] ?? '').toString() : '';
        final ratedUserId = args is Map
            ? (args['ratedUserId'] ?? args['userId'] ?? '').toString()
            : '';
        final ratedUserName = args is Map
            ? (args['ratedUserName'] ?? args['username'])?.toString()
            : null;

        return RateUserScreen(
          userService: userService,
          authService: authService,
          tenderId: tenderId,
          ratedUserId: ratedUserId,
          ratedUserName: ratedUserName,
        );
      },
      AppRoutes.home: (context) => const HomeScreen(),
    };
  }
}
