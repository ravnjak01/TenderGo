import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/services/user_service.dart';

class UserProfilePublicScreen extends StatelessWidget {
  final String userId;
  final UserService userService;

  const UserProfilePublicScreen({
    super.key,
    required this.userId,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    if (userId.trim().isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Missing user ID.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: FutureBuilder<UserPublicDto>(
        future: userService.getUser(userId),
        builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load user profile.'));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('User not found.'));
        }

        final user = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${user.firstName} ${user.lastName}'.trim(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('@${user.username}'),
              const SizedBox(height: 4),
              Text(user.location ?? ''),
              const SizedBox(height: 12),
              Text('Rating: ${user.rating.toStringAsFixed(1)}'),
              Text('Reviews: ${user.reviewCount}'),
              Text('Tenders: ${user.tenderCount}'),
              Text('Bids: ${user.bidsCount}'),
            ],
          ),
        );
      },
      ),
    );
  }
}