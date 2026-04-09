import 'package:flutter/material.dart';
import 'package:tendergo_admin/screens/forgot_password_screen.dart';
import 'package:tendergo_admin/screens/home_screen.dart';
import 'package:tendergo_admin/screens/login_screen.dart';
import 'package:tendergo_admin/screens/tender_details_screen.dart';
import 'package:tendergo_admin/screens/tender_post_screen.dart';
import 'package:tendergo_admin/screens/registration_screen.dart';
import 'package:tendergo_admin/screens/reset_passsword.screen.dart';
import 'package:tendergo_admin/screens/splash_screen.dart';
import 'package:tendergo_admin/screens/tenders_list_screen.dart';
import 'package:tendergo_admin/services/auth_service.dart';
import 'package:tendergo_admin/services/dio_client.dart';
import 'package:tendergo_admin/services/tender_service.dart';

class AppRoutes {
  // 1. MORAŠ definirati ove stringove kao konstante ili varijable
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String registration = '/registration';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String tenderList = '/tenders';
  static const String tenderPost='/tender-post';
  static const String tenderDetails='/tender-details';
  static Map<String, WidgetBuilder> getRoutes() {
    // Kreiramo Dio instancu
    final dio = DioClient.getDio(); 
    
    // Kreiramo AuthService sa tom instancom
    final authService = AuthService(dio);
    final tenderService=TenderService(  dio);

    return {
      splash: (context) => const SplashScreen(),
      login: (context) => LoginScreen(authService: authService), 
      registration: (context) => RegistrationScreen(authService: authService),
      forgotPassword: (context) => ForgotPasswordScreen(authService: authService),
      resetPassword: (context) => ResetPasswordScreen(authService: authService), 
      tenderList: (context) => TenderListScreen(tenderService: tenderService),
      tenderPost: (context) => TenderPostScreen(tenderService: tenderService),
      tenderDetails: (context) => TenderDetailsScreen(tenderService: tenderService),

      home: (context) => const HomeScreen(),
    };
  }
} 