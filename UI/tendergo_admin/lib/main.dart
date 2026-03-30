import 'package:flutter/material.dart';
import 'package:tendergo_admin/core/theme/app_theme.dart';
import 'package:tendergo_admin/routes/routes.dart';
import 'package:tendergo_admin/services/auth_service.dart';
import 'package:tendergo_admin/services/dio_client.dart';
void main() async{
WidgetsFlutterBinding.ensureInitialized();

final dio = DioClient.getDio();
final authService=AuthService(dio);


final bool isLoggedIn = await AuthService.isLoggedIn();


  runApp(MyApp(isLoggedIn: isLoggedIn,authService: authService,));
}

class MyApp extends StatelessWidget {
    final AuthService authService;
  final bool isLoggedIn;

  const MyApp({
    super.key, 
    required this.authService, 
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: AppRoutes.splash,

      routes: AppRoutes.getRoutes(),

        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
      );

  }
}

  
  