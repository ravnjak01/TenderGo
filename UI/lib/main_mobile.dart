import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:tendergo/mobile/app.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/category_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/image_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dio = DioClient.getDio();
  final authService = AuthService(dio);
  final bidService = BidService(dio);
  final imageService = ImageService(dio);
  final tenderService = TenderService(dio, imageService);
  final userService = UserService(dio);
  final categoryService = CategoryService(dio);
  runApp(
    DevicePreview(
      enabled: true,
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
