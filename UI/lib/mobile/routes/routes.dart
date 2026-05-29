import 'package:flutter/material.dart';
import 'package:tendergo/admin/screens/mybids_screen.dart';
import 'package:tendergo/admin/screens/splash_screen.dart';
import 'package:tendergo/mobile/screens/forgot_password_screen.dart';
import 'package:tendergo/mobile/screens/login_screen.dart';
import 'package:tendergo/mobile/screens/mobile_bookmarked_screen.dart';
import 'package:tendergo/mobile/screens/my_tenders_screen.dart';
import 'package:tendergo/mobile/screens/registration_screen.dart';
import 'package:tendergo/mobile/screens/reset_password_screen.dart';
import 'package:tendergo/mobile/screens/tender_details_screen.dart';
import 'package:tendergo/mobile/screens/tender_post_screen.dart';
import 'package:tendergo/mobile/screens/tender_shell_screen.dart';
import 'package:tendergo/shared/screens/user_profile_screen.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/screens/notification_screen.dart';
import 'package:tendergo/shared/screens/recommendation_screen.dart';
import 'package:tendergo/shared/screens/rate_user_screen.dart';
import 'package:tendergo/shared/screens/user_profile_public_screen.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/services/user_service.dart';

class MobileRoutes {
  static Map<String, WidgetBuilder> getRoutes({
    required AuthService authService,
    required BidService bidService,
    required TenderService tenderService,
    required UserService userService,
    required CategoryService categoryService,
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
          MobileMyTendersScreen(tenderService: tenderService),
      AppRoutes.myBids: (context) => MyBidsScreen(
        bidService: bidService,
      ),
      AppRoutes.userPublicProfile: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final userId = switch (args) {
          String value => value,
          Map value =>
            (value['userId'] ?? value['id'] ?? '').toString(),
          _ => '',
        };

        return UserProfilePublicScreen(userId: userId, userService: userService,tenderService: tenderService,);
      },
      AppRoutes.rateUser: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final rawTenderId = args is Map ? args['tenderId'] : null;
        final int tenderId = rawTenderId is int 
        ? rawTenderId 
        : int.tryParse(rawTenderId?.toString() ?? '') ?? 0;
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
      AppRoutes.recommendations: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final onTap = args is Map
            ? args['onTenderTapped'] as void Function(int)?
            : null;
        return RecommendedForYouScreen(onTenderTapped: onTap);
      },
      AppRoutes.notifications: (context) => const NotificationScreen(),
      AppRoutes.bookmarkedTenders: (context) {
  return MobileBookmarkedTendersScreen(
    tenderService: tenderService,
    onTenderSelected: (tenderId) {
      // Otvaranje detalja tendera kada se klikne unutar sačuvanih
      Navigator.of(context).pushNamed(
        AppRoutes.tenderDetails,
        arguments: tenderId, // Ako tvoj detalji screen prima argumente ovako
      );
    },
  );
},

    };
  }
}