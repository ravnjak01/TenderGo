// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tendergo_admin/main.dart';
import 'package:tendergo_admin/services/auth_service.dart';
import 'package:tendergo_admin/services/dio_client.dart';

void main() {
  testWidgets('Provjera da li se aplikacija učitava', (WidgetTester tester) async {

    final dio = DioClient.getDio();
    final authService = AuthService(dio);

    // Ovo "bilježi" tvoju aplikaciju u testnom okruženju
   await tester.pumpWidget(MyApp(
      authService: authService,
      isLoggedIn: false, // Možeš staviti true ili false, zavisi šta testiraš
    ));

    expect(find.byType(MaterialApp), findsOneWidget);

    // Test će proći jer nismo postavili nikakve stroge uslove (expect)
    print("Test uspješno izvršen!");
  });
}
