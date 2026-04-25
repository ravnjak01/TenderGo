import 'package:flutter/material.dart';
import 'package:tendergo/admin/screens/mybids_screen.dart';
import 'package:tendergo/admin/screens/mytenders_screen.dart';
import 'package:tendergo/admin/screens/splash_screen.dart';
import 'package:tendergo/mobile/screens/forgot_password_screen.dart';
import 'package:tendergo/mobile/screens/login_screen.dart';
import 'package:tendergo/mobile/screens/registration_screen.dart';
import 'package:tendergo/mobile/screens/reset_password_screen.dart';
import 'package:tendergo/mobile/screens/tender_details_screen.dart';
import 'package:tendergo/mobile/screens/tender_post_screen.dart';
import 'package:tendergo/mobile/screens/tender_shell_screen.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/screens/user_profile_public_screen.dart';
import 'package:tendergo/shared/screens/user_profile_screen.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/services/user_service.dart';

class MobileRoutes {
  static Map<String, WidgetBuilder> getRoutes({
    required AuthService authService,
    required BidService bidService,
    required TenderService tenderService,
    required UserService userService,
  }) {
    return {
      AppRoutes.splash: (context) => const SplashScreen(),
      AppRoutes.login: (context) => const MobileLoginScreen(),
      AppRoutes.registration: (context) => const MobileRegistrationScreen(),
      AppRoutes.forgotPassword: (context) => const MobileForgotPasswordScreen(),
      AppRoutes.resetPassword: (context) => const MobileResetPasswordScreen(),
      AppRoutes.tenderList: (context) => MobileTenderShellScreen(
        tenderService: tenderService,
        authService: authService,
      ),
      AppRoutes.tenderPost: (context) => const MobileTenderPostScreen(),
      AppRoutes.tenderDetails: (context) =>
          MobileTenderDetailsScreen(tenderService: tenderService),
      AppRoutes.userProfile: (context) =>
          UserProfileScreen(authService: authService),
      AppRoutes.myTenders: (context) =>
          MyTendersScreen(tenderService: tenderService),
      AppRoutes.myBids: (context) => MyBidsScreen(bidService: bidService),
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
    };
  }
}