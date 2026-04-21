// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tendergo_admin/main.dart';
import 'package:tendergo_admin/services/admin_service.dart';
import 'package:tendergo_admin/services/auth_service.dart';
import 'package:tendergo_admin/services/bid_service.dart';
import 'package:tendergo_admin/services/category_service.dart';
import 'package:tendergo_admin/services/dio_client.dart';
import 'package:tendergo_admin/services/image_service.dart';
import 'package:tendergo_admin/services/tender_service.dart';

void main() {
  testWidgets('Provjera da li se aplikacija učitava', (WidgetTester tester) async {

    final dio = DioClient.getDio();
    final authService = AuthService(dio);
    final adminService = AdminService(dio);
    final bidService = BidService(dio);
    final imageService = ImageService(dio);
    final TenderService tenderService = TenderService(dio, imageService);
    final CategoryService categoryService = CategoryService(dio);
   await tester.pumpWidget(MyApp(
      authService: authService,
      adminService: adminService,
      bidService: bidService,
      imageService: imageService,
      tenderService: tenderService,
      categoryService: categoryService,
      isLoggedIn: false, 
    ));

    expect(find.byType(MaterialApp), findsOneWidget);

  });
}
