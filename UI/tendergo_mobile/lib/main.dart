import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:tendergo/mobile/app.dart';
// Importuj tvoj MobileApp fajl (prilagodi putanju ako je drugačija)
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/image_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/services/user_service.dart';

void main() async {
  // Osigurava da su svi Flutter binding-zi inicijalizovani prije asinhronih poziva
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicijalizacija HTTP klijenta (Dio)
  final dio = DioClient.getDio();

  // 2. Inicijalizacija svih potrebnih servisa
  final authService = AuthService(dio);
  final bidService = BidService(dio);
  final imageService = ImageService(dio);
  final tenderService = TenderService(dio,imageService);
  final userService = UserService(dio);
  final categoryService = CategoryService(dio);

  runApp(
    DevicePreview(
      enabled: true, // Postavi na false ako ne želiš Device Preview u produkciji
      builder: (context) => MobileApp(
        authService: authService,
        bidService: bidService,
        tenderService: tenderService,
        userService: userService,
        categoryService: categoryService,
      ),
    ),
  );
}