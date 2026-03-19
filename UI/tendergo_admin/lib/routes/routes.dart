import 'package:flutter/material.dart';
import 'package:tendergo_admin/screens/home_screen.dart';
import 'package:tendergo_admin/screens/login_screen.dart';
import 'package:tendergo_admin/screens/splash_screen.dart';
import 'package:tendergo_admin/services/auth_service.dart';
import 'package:tendergo_admin/services/dio_client.dart';

class AppRoutes {
  // 1. MORAŠ definirati ove stringove kao konstante ili varijable
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';

  static Map<String, WidgetBuilder> getRoutes() {
    // Kreiramo Dio instancu
    final dio = DioClient.getDio(); 
    
    // Kreiramo AuthService sa tom instancom
    final authService = AuthService(dio);

    return {
      splash: (context) => const SplashScreen(),
      // 2. Makni 'const' ispred LoginScreen u pozivu ako on prima authService
      login: (context) => LoginScreen(authService: authService), 
      home: (context) => const HomeScreen(),
    };
  }
} // <-- Ova zagrada je nedostajala