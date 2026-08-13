import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tendergo/mobile/widgets/common/user_avatar_widget.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';

void main() {
  testWidgets('falls back to initials when the profile image URL is invalid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserAvatarWidget(
            user: UserDto(
              id: '1',
              email: '',
              username: '',
              firstName: 'John',
              lastName: 'Doe',
              profileImageUrl: 'http://127.0.0.1:1/no-image.png',
              roles: const [],
              isBanned: false,
            ),
            onTap: () {},
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 2));

    expect(find.text('JD'), findsOneWidget);
  });
}
