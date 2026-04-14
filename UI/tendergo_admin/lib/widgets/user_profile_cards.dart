import 'package:flutter/material.dart';
import 'package:tendergo_admin/models/dto/auth_dto.dart';
import 'package:tendergo_admin/widgets/common/app_card.dart';

class UserProfileCards extends StatelessWidget {
  final UserDto user;
  final String? userId;

  const UserProfileCards({
    super.key,
    required this.user,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UserProfileInfoCard(user: user),
        if (user.address != null) ...[
          const SizedBox(height: 16),
          UserProfileAddressCard(address: user.address!),
        ],
        if (userId != null && userId!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          UserProfileIdCard(id: userId!),
        ],
      ],
    );
  }
}

class UserProfileInfoCard extends StatelessWidget {
  final UserDto user;

  const UserProfileInfoCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = user.firstName.trim();
    final lastName = user.lastName.trim();

    return AppCard(
      title: 'Account Information',
      icon: Icons.person_outline_rounded,
      children: [
        InfoRow(
          label: 'First Name',
          value: firstName.isEmpty ? '-' : firstName,
        ),
        InfoRow(
          label: 'Last Name',
          value: lastName.isEmpty ? '-' : lastName,
        ),
        InfoRow(label: 'Username', value: user.username),
        InfoRow(label: 'Email', value: user.email),
      ],
    );
  }
}

class UserProfileAddressCard extends StatelessWidget {
  final AddressDto address;

  const UserProfileAddressCard({
    super.key,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Address',
      icon: Icons.location_on_outlined,
      children: [
        InfoRow(label: 'Street', value: address.street),
        InfoRow(label: 'City', value: address.city),
        InfoRow(label: 'Postal Code', value: address.postalCode),
        InfoRow(label: 'Country', value: address.country),
      ],
    );
  }
}

class UserProfileIdCard extends StatelessWidget {
  final String id;

  const UserProfileIdCard({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'System',
      icon: Icons.fingerprint_rounded,
      children: [
        InfoRow(
          label: 'User ID',
          value: id,
          monospace: true,
          copyable: true,
        ),
      ],
    );
  }
}